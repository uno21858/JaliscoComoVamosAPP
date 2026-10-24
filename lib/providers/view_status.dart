enum ViewStatus {
  loading,
  ready,

  /// El servidor no mostró datos porque la muestra no llega al umbral.
  tooFew,
  error,
}
