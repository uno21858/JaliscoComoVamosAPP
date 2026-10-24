import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/core.dart';
import '../../core/router/app_routes.dart';
import '../../models/models.dart';
import '../../repositories/repositories.dart';
import '../../widgets/widgets.dart';
import 'widgets/topic_icon.dart';

/// 2.1 Temáticas: rejilla con las 8 temáticas.
class TopicsScreen extends StatefulWidget {
  const TopicsScreen({super.key});

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  late Future<(Result<List<Topic>>, Result<SampleInfo>)> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(Result<List<Topic>>, Result<SampleInfo>)> _load() {
    final repo = context.read<DataRepository>();
    return (repo.getTopics(), repo.getSampleInfo()).wait;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const RootHeader(
            title: 'Datos',
            subtitle: 'Encuesta de Bienestar de Jóvenes AMG 2026',
          ),
          Expanded(
            child: FutureBuilder<(Result<List<Topic>>, Result<SampleInfo>)>(
              future: _future,
              builder: (context, snapshot) {
                final data = snapshot.data;
                if (data == null) return const LoadingStateView();
                final (topicsResult, sampleResult) = data;
                final topics = topicsResult.valueOrNull;
                if (topics == null) {
                  return ConnectionErrorView(
                    onRetry: () => setState(() {
                      _future = _load();
                    }),
                  );
                }
                final sample = sampleResult.valueOrNull;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  children: [
                    Semantics(
                      header: true,
                      child: const Text(
                        'Elige una temática',
                        style: TextStyle(
                          fontSize: 16,
                          height: 22 / 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    if (sample != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${Formatters.thousands(sample.total)} jóvenes de '
                        '${sample.minAge} a ${sample.maxAge} años · ${sample.edition}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                    const SizedBox(height: 16),
                    EvenGrid(
                      columns: 2,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final topic in topics) _TopicTile(topic: topic),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const MockDataBanner(padding: EdgeInsets.zero),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({required this.topic});

  final Topic topic;

  @override
  Widget build(BuildContext context) {
    return JcvCard(
      padding: const EdgeInsets.all(14),
      onTap: () => context.push(AppRoutes.topic(topic.id)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 88),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconCircle(
              icon: topicIcon(topic.id),
              size: 46,
              iconSize: 24,
              background: AppColors.lime,
            ),
            const SizedBox(height: 12),
            Text(
              topic.name,
              style: const TextStyle(
                fontSize: 14,
                height: 18 / 14,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
