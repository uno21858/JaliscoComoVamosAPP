import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;

import '../../core/app_error.dart';
import '../../core/error_sanitizer.dart';
import '../../core/result.dart';

/// Tokens de Cognito en Keychain/Keystore, como _CognitoSecureStorage de CCL.
class _SecureCognitoStorage extends CognitoStorage {
  _SecureCognitoStorage(this._storage);

  final FlutterSecureStorage _storage;
  static const _prefix = 'cog.';

  @override
  Future<dynamic> getItem(String key) => _storage.read(key: '$_prefix$key');

  @override
  Future<dynamic> setItem(String key, value) async {
    await _storage.write(key: '$_prefix$key', value: value.toString());
    return value;
  }

  @override
  Future<dynamic> removeItem(String key) => _storage.delete(key: '$_prefix$key');

  @override
  Future<void> clear() async {
    final keys = (await _storage.readAll()).keys.where((k) => k.startsWith(_prefix));
    for (final key in keys.toList()) {
      await _storage.delete(key: key);
    }
  }
}

enum SignInOutcome { signedIn, needsConfirmation }

/// 3.2 Registro bloqueado. El pre-signup de Cognito es el que de verdad lo impide.
const tecOnlyMessage = 'Las encuestas son solo para estudiantes del Tec. Usa tu correo @tec.mx.';

bool isTecEmail(String email) => RegExp(r'^[^@\s]+@tec\.mx$', caseSensitive: false).hasMatch(email.trim());

/// Login con correo y contraseña contra el pool de JCV (SRP, como CCL).
///
/// Supabase recibe el access token por [accessToken]; con sesión, las RPC
/// sacan al usuario del JWT (jcv.usuario_actual), nunca de un parámetro.
class AuthService extends ChangeNotifier {
  AuthService({
    required String userPoolId,
    required String clientId,
    String hostedUiDomain = '',
    FlutterSecureStorage? storage,
  })  : _clientId = clientId,
        _domain = hostedUiDomain,
        _pool = CognitoUserPool(
          userPoolId,
          clientId,
          storage: _SecureCognitoStorage(storage ?? const FlutterSecureStorage()),
        );

  final CognitoUserPool _pool;
  final String _clientId;
  final String _domain;
  CognitoUser? _user;
  CognitoUserSession? _session;
  Future<void>? _refreshing;

  /// Se llama al cerrar sesión o borrar la cuenta (borra datos locales de la persona).
  Future<void> Function()? onSignedOut;

  bool get isSignedIn => _session != null;

  /// Del ID token: con Google el username de Cognito no es el correo.
  String? get email => _session?.getIdToken().payload['email'] as String?;

  /// Sin Hosted UI configurado no se muestra el botón.
  bool get hasGoogle => _domain.isNotEmpty;

  static const _callbackScheme = 'jcvapp';
  static const _callbackUrl = '$_callbackScheme://callback';

  CognitoUser _userFor(String email) =>
      CognitoUser(email, _pool, storage: _pool.storage);

  static String _normalize(String email) => email.trim().toLowerCase();

  /// Al abrir la app: recupera la sesión guardada (y la refresca si venció).
  Future<void> restore() async {
    try {
      final user = await _pool.getCurrentUser();
      final session = await user?.getSession();
      if (user != null && session != null && session.isValid()) {
        _user = user;
        _session = session;
      }
    } on Object catch (e) {
      debugPrint('AuthService.restore: $e');
    }
    notifyListeners();
  }

  /// Access token vigente o null (sin sesión: Supabase usa la anon key).
  /// Refresca si le queda menos de un minuto; si el refresh falla, cierra sesión.
  Future<String?> accessToken() async {
    final session = _session;
    if (session == null) return null;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (session.getAccessToken().getExpiration() - now > 60) {
      return session.getAccessToken().getJwtToken();
    }
    await (_refreshing ??= _refresh().whenComplete(() => _refreshing = null));
    return _session?.getAccessToken().getJwtToken();
  }

  Future<void> _refresh() async {
    final user = _user;
    final refreshToken = _session?.getRefreshToken();
    if (user == null || refreshToken == null) return;
    try {
      _session = await user.refreshSession(refreshToken);
    } on CognitoClientException catch (e) {
      // Refresh vencido o revocado: hay que volver a entrar.
      if (e.code == 'NotAuthorizedException') {
        await _clearLocal();
        return;
      }
      rethrow;
    }
  }

  Future<Result<SignInOutcome>> signIn(String email, String password) => _guard(() async {
        final user = _userFor(_normalize(email));
        try {
          final session = await user.authenticateUser(
            AuthenticationDetails(username: _normalize(email), password: password),
          );
          _user = user;
          _session = session;
          notifyListeners();
          return SignInOutcome.signedIn;
        } on CognitoUserConfirmationNecessaryException {
          return SignInOutcome.needsConfirmation;
        }
      });

  /// Google por el Hosted UI de Cognito (code + PKCE). El pre-signup rechaza
  /// lo que no sea @tec.mx y liga la cuenta si ya existía con correo.
  /// Ok(false): la persona cerró la ventana.
  Future<Result<bool>> signInWithGoogle() => _guard(() async {
        final rnd = Random.secure();
        String random() => base64Url.encode(List.generate(32, (_) => rnd.nextInt(256))).replaceAll('=', '');
        final verifier = random();
        final state = random();
        final challenge = base64Url.encode(sha256.convert(ascii.encode(verifier)).bytes).replaceAll('=', '');

        final String result;
        try {
          result = await FlutterWebAuth2.authenticate(
            url: Uri.parse('$_domain/oauth2/authorize').replace(queryParameters: {
              'response_type': 'code',
              'client_id': _clientId,
              'redirect_uri': _callbackUrl,
              'identity_provider': 'Google',
              'scope': 'openid email profile',
              'state': state,
              'code_challenge': challenge,
              'code_challenge_method': 'S256',
            }).toString(),
            callbackUrlScheme: _callbackScheme,
            // Sin cookies: al cerrar sesión se puede elegir otra cuenta de Google.
            options: const FlutterWebAuth2Options(preferEphemeral: true),
          );
        } on PlatformException catch (e) {
          if (e.code == 'CANCELED') return false;
          rethrow;
        }

        final params = Uri.parse(result).queryParameters;
        final error = params['error_description'] ?? params['error'];
        if (error != null) {
          throw error.contains('TEC_ONLY') ? const ValidationError(tecOnlyMessage) : ServerError('google $error');
        }
        final code = params['code'];
        if (params['state'] != state || code == null) throw const ServerError('google: state o code inválido');

        final response = await http.post(
          Uri.parse('$_domain/oauth2/token'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'grant_type': 'authorization_code',
            'client_id': _clientId,
            'code': code,
            'redirect_uri': _callbackUrl,
            'code_verifier': verifier,
          },
        ).timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) throw ServerError('google token ${response.statusCode}');
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        final session = CognitoUserSession(
          CognitoIdToken(data['id_token'] as String),
          CognitoAccessToken(data['access_token'] as String),
          refreshToken: CognitoRefreshToken(data['refresh_token'] as String),
        );
        // Mismo storage que SRP: restore() y refreshSession funcionan igual.
        final user = CognitoUser(session.getAccessToken().payload['username'] as String, _pool,
            storage: _pool.storage, signInUserSession: session);
        await user.cacheTokens();
        _user = user;
        _session = session;
        notifyListeners();
        return true;
      });

  Future<Result<void>> signUp(String email, String password) => _guard(() async {
        await _pool.signUp(_normalize(email), password,
            userAttributes: [AttributeArg(name: 'email', value: _normalize(email))]);
      });

  Future<Result<void>> confirm(String email, String code) =>
      _guard(() async {
        await _userFor(_normalize(email)).confirmRegistration(code.trim());
      });

  Future<Result<void>> resendCode(String email) =>
      _guard(() async {
        await _userFor(_normalize(email)).resendConfirmationCode();
      });

  Future<Result<void>> forgotPassword(String email) =>
      _guard(() async {
        await _userFor(_normalize(email)).forgotPassword();
      });

  Future<Result<void>> resetPassword(String email, String code, String newPassword) =>
      _guard(() async {
        await _userFor(_normalize(email)).confirmPassword(code.trim(), newPassword);
      });

  Future<void> signOut() async {
    try {
      await _user?.signOut(revokeRefreshToken: true);
    } on Object catch (e) {
      debugPrint('AuthService.signOut: $e'); // sin red: igual se borra local
    }
    await _clearLocal();
  }

  /// Apple 5.1.1(v): borrar la cuenta desde la app. [deleteServerData] corre
  /// primero, con el token todavía vigente.
  Future<Result<void>> deleteAccount(Future<void> Function() deleteServerData) => _guard(() async {
        final user = _user;
        if (user == null) throw const ValidationError('Tu sesión terminó. Vuelve a entrar.');
        await deleteServerData();
        await user.deleteUser();
        await _clearLocal();
      });

  Future<void> _clearLocal() async {
    try {
      await _user?.clearCachedTokens();
    } on Object catch (e) {
      debugPrint('AuthService.clearCachedTokens: $e');
    }
    _user = null;
    _session = null;
    await onSignedOut?.call();
    notifyListeners();
  }

  /// Errores de Cognito -> mensajes para personas (nunca el texto crudo).
  static Future<Result<T>> _guard<T>(Future<T> Function() body) => guardResult(() async {
        try {
          return await body();
        } on CognitoClientException catch (e) {
          throw _toAppError(e);
        } on TimeoutException {
          throw const NetworkError();
        }
      });

  static AppError _toAppError(CognitoClientException e) => switch (e.code) {
        'NotAuthorizedException' || 'UserNotFoundException' =>
          const ValidationError('Correo o contraseña incorrectos.'),
        'UsernameExistsException' => const ValidationError('Ya hay una cuenta con ese correo. Inicia sesión.'),
        'InvalidPasswordException' => const ValidationError(
            'La contraseña necesita al menos 8 caracteres, una mayúscula, una minúscula y un número.'),
        'CodeMismatchException' => const ValidationError('El código no es correcto.'),
        'ExpiredCodeException' => const ValidationError('El código venció. Pide uno nuevo.'),
        'LimitExceededException' || 'TooManyRequestsException' || 'TooManyFailedAttemptsException' =>
          const ValidationError('Demasiados intentos. Espera unos minutos.'),
        'InvalidParameterException' => const ValidationError('Revisa el correo.'),
        'UserLambdaValidationException' when (e.message ?? '').contains('TEC_ONLY') =>
          const ValidationError(tecOnlyMessage),
        'UserLambdaValidationException' when (e.message ?? '').contains('SOCIAL_ACCOUNT_EXISTS') =>
          const ValidationError('Ese correo ya entra con Google o Apple. Usa ese botón.'),
        'NetworkError' || null => NetworkError('cognito ${e.code}'),
        _ => ServerError('cognito ${e.code}'),
      };
}
