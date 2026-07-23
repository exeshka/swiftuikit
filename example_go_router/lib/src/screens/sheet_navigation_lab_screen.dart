import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SheetNavigationLabScreen extends StatefulWidget {
  const SheetNavigationLabScreen({super.key});

  @override
  State<SheetNavigationLabScreen> createState() =>
      _SheetNavigationLabScreenState();
}

class _SheetNavigationLabScreenState extends State<SheetNavigationLabScreen> {
  String _lastEvent = 'Готов к проверке';

  String _target({
    required String path,
    required String operation,
    required String back,
    bool result = false,
  }) {
    return Uri(
      path: path,
      queryParameters: {
        'operation': operation,
        'back': back,
        if (result) 'result': 'true',
      },
    ).toString();
  }

  Future<void> _pushSheet() async {
    setState(() => _lastEvent = 'Sheet → Sheet: ожидаю результат...');
    final result = await context.push<String>(
      _target(
        path: '/sheet-navigation-result',
        operation: 'Sheet → Sheet · push',
        back: 'SwiftSheet Lab',
        result: true,
      ),
    );
    if (!mounted) return;
    setState(() => _lastEvent = 'Sheet → Sheet вернул: ${result ?? 'null'}');
  }

  Future<void> _pushPage() async {
    setState(() => _lastEvent = 'Sheet → Page: ожидаю результат...');
    final result = await context.push<String>(
      _target(
        path: '/navigation-result',
        operation: 'Sheet → Page · push',
        back: 'SwiftSheet Lab',
        result: true,
      ),
    );
    if (!mounted) return;
    setState(() => _lastEvent = 'Sheet → Page вернул: ${result ?? 'null'}');
  }

  void _pushReplacementSheet() {
    context.pushReplacement(
      _target(
        path: '/sheet-navigation-result',
        operation: 'Sheet → Sheet · pushReplacement',
        back: 'Home',
      ),
    );
  }

  void _pushReplacementPage() {
    context.pushReplacement(
      _target(
        path: '/navigation-result',
        operation: 'Sheet → Page · pushReplacement',
        back: 'Home',
      ),
    );
  }

  void _replaceSheet() {
    context.replace(
      _target(
        path: '/sheet-navigation-result',
        operation: 'Sheet → Sheet · replace',
        back: 'Home',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const _DragHandle(),
          Text(
            'SwiftSheet Navigation Lab',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text('go_router · потяните лист вниз для проверки dismiss'),
          const SizedBox(height: 16),
          _EventCard(message: _lastEvent),
          const SizedBox(height: 20),
          _ScenarioTile(
            number: 1,
            title: 'Sheet → Sheet · push',
            expectation:
                '«Вернуть OK» закрывает верхний sheet, показывает этот sheet '
                'и записывает результат.',
            onTap: _pushSheet,
          ),
          _ScenarioTile(
            number: 2,
            title: 'Sheet → Page · push',
            expectation:
                'Page покрывает sheet. Back возвращает к этому sheet, не на Home.',
            color: Colors.indigo,
            onTap: _pushPage,
          ),
          _ScenarioTile(
            number: 3,
            title: 'Sheet → Sheet · pushReplacement',
            expectation:
                'Этот sheet удаляется. Back на новом sheet ведёт сразу на Home.',
            color: Colors.deepOrange,
            onTap: _pushReplacementSheet,
          ),
          _ScenarioTile(
            number: 4,
            title: 'Sheet → Page · pushReplacement',
            expectation:
                'Sheet заменяется страницей. Back на странице ведёт на Home.',
            color: Colors.purple,
            onTap: _pushReplacementPage,
          ),
          _ScenarioTile(
            number: 5,
            title: 'Sheet → Sheet · replace',
            expectation:
                'Проверяет go_router replace с сохранением page key. Back ведёт '
                'на Home.',
            color: Colors.blueGrey,
            onTap: _replaceSheet,
          ),
          const SizedBox(height: 8),
          const _Checklist(),
        ],
      ),
    );
  }
}

class SheetNavigationResultScreen extends StatelessWidget {
  const SheetNavigationResultScreen({
    required this.operation,
    required this.expectedBackDestination,
    required this.canReturnResult,
    super.key,
  });

  final String operation;
  final String expectedBackDestination;
  final bool canReturnResult;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: [
          const _DragHandle(),
          const Icon(Icons.layers_rounded, size: 64, color: Colors.teal),
          const SizedBox(height: 16),
          Text(
            operation,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            'После Back ожидается: $expectedBackDestination',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          if (canReturnResult)
            FilledButton.icon(
              onPressed: () => context.pop('OK'),
              icon: const Icon(Icons.check),
              label: const Text('Вернуть OK'),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back),
            label: Text('Back → $expectedBackDestination'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Также проверьте drag-to-dismiss: результат должен совпасть '
            'с обычным Back.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 38,
        height: 5,
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
      ),
    );
  }
}

class _ScenarioTile extends StatelessWidget {
  const _ScenarioTile({
    required this.number,
    required this.title,
    required this.expectation,
    required this.onTap,
    this.color = Colors.teal,
  });

  final int number;
  final String title;
  final String expectation;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$number. $title',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(expectation),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: color),
              onPressed: onTap,
              child: const Text('Запустить'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Checklist extends StatelessWidget {
  const _Checklist();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Чек-лист SwiftSheet',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8),
            Text('✓ предыдущий route корректно масштабируется'),
            Text('✓ Sheet → Sheet образует правильный стек'),
            Text('✓ Sheet → Page возвращает к sheet'),
            Text('✓ replacement удаляет исходный sheet'),
            Text('✓ drag закрывает sheet примерно после 32% высоты'),
            Text('✓ Back и drag-to-dismiss дают одинаковый результат'),
          ],
        ),
      ),
    );
  }
}
