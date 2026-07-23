import 'package:auto_route/auto_route.dart';
import 'package:example/src/core/router/router.gr.dart';
import 'package:flutter/material.dart';

@RoutePage()
class SheetNavigationLabScreen extends StatefulWidget {
  const SheetNavigationLabScreen({super.key});

  @override
  State<SheetNavigationLabScreen> createState() =>
      _SheetNavigationLabScreenState();
}

class _SheetNavigationLabScreenState extends State<SheetNavigationLabScreen> {
  String _lastEvent = 'Готов к проверке';

  Future<void> _pushSheet() async {
    setState(() => _lastEvent = 'Sheet → Sheet: ожидаю результат...');
    final result = await context.router.push<String>(
      SheetNavigationResultRoute(
        operation: 'Sheet → Sheet · push',
        expectedBackDestination: 'SwiftSheet Lab',
        canReturnResult: true,
      ),
    );
    if (!mounted) return;
    setState(() => _lastEvent = 'Sheet → Sheet вернул: ${result ?? 'null'}');
  }

  Future<void> _pushPage() async {
    setState(() => _lastEvent = 'Sheet → Page: ожидаю результат...');
    final result = await context.router.push<String>(
      NavigationResultRoute(
        operation: 'Sheet → Page · push',
        expectedBackDestination: 'SwiftSheet Lab',
        canReturnResult: true,
      ),
    );
    if (!mounted) return;
    setState(() => _lastEvent = 'Sheet → Page вернул: ${result ?? 'null'}');
  }

  void _replaceWithSheet() {
    context.router.replace(
      SheetNavigationResultRoute(
        operation: 'Sheet → Sheet · replace',
        expectedBackDestination: 'Home',
      ),
    );
  }

  void _replaceWithPage() {
    context.router.replace(
      NavigationResultRoute(
        operation: 'Sheet → Page · replace',
        expectedBackDestination: 'Home',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Material(
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
            const Text('auto_route · потяните лист вниз для проверки dismiss'),
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
              title: 'Sheet → Sheet · replace',
              expectation:
                  'Этот sheet удаляется. Back на новом sheet ведёт сразу на Home.',
              color: Colors.deepOrange,
              onTap: _replaceWithSheet,
            ),
            _ScenarioTile(
              number: 4,
              title: 'Sheet → Page · replace',
              expectation:
                  'Sheet заменяется страницей. Back на странице ведёт на Home.',
              color: Colors.purple,
              onTap: _replaceWithPage,
            ),
            const SizedBox(height: 8),
            const _Checklist(),
          ],
        ),
      ),
    );
  }
}

@RoutePage()
class SheetNavigationResultScreen extends StatelessWidget {
  const SheetNavigationResultScreen({
    required this.operation,
    required this.expectedBackDestination,
    this.canReturnResult = false,
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
              onPressed: () => context.router.pop('OK'),
              icon: const Icon(Icons.check),
              label: const Text('Вернуть OK'),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.router.maybePop(),
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
            Text('✓ replace удаляет исходный sheet'),
            Text('✓ drag закрывает sheet примерно после 32% высоты'),
            Text('✓ Back и drag-to-dismiss дают одинаковый результат'),
          ],
        ),
      ),
    );
  }
}
