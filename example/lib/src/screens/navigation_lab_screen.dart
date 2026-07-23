import 'package:auto_route/auto_route.dart';
import 'package:example/src/core/router/router.gr.dart';
import 'package:flutter/material.dart';

@RoutePage()
class NavigationLabScreen extends StatefulWidget {
  const NavigationLabScreen({super.key});

  @override
  State<NavigationLabScreen> createState() => _NavigationLabScreenState();
}

class _NavigationLabScreenState extends State<NavigationLabScreen> {
  String _lastEvent = 'Сценарий ещё не запускался';

  Future<void> _testPush() async {
    setState(() => _lastEvent = 'Открыт push, ожидаю результат...');
    final result = await context.router.push<String>(
      NavigationResultRoute(
        operation: 'push',
        expectedBackDestination: 'Navigation Lab',
        canReturnResult: true,
      ),
    );
    if (!mounted) return;
    setState(() => _lastEvent = 'push вернул результат: ${result ?? 'null'}');
  }

  void _testReplace() {
    context.router.replace(
      NavigationResultRoute(
        operation: 'replace',
        expectedBackDestination: 'Home',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Navigation Lab · auto_route')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _StatusCard(
            router: 'auto_route',
            currentRoute: 'NavigationLabRoute',
            replacementApi: 'context.router.replace(...)',
          ),
          const SizedBox(height: 16),
          _EventCard(message: _lastEvent),
          const SizedBox(height: 24),
          const Text(
            'Проверка стека',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            number: '1',
            title: 'push',
            code: 'context.router.push(...)',
            expectation:
                'На целевой странице нажмите «Вернуть OK». Вы должны попасть '
                'сюда и увидеть результат OK.',
            onPressed: _testPush,
          ),
          const SizedBox(height: 12),
          _ActionCard(
            number: '2',
            title: 'replace',
            code: 'context.router.replace(...)',
            expectation:
                'Navigation Lab будет заменён. Back на целевой странице должен '
                'вернуть на Home, минуя этот экран.',
            color: Colors.deepOrange,
            onPressed: _testReplace,
          ),
          const SizedBox(height: 24),
          const _Checklist(),
        ],
      ),
    );
  }
}

@RoutePage()
class NavigationResultScreen extends StatelessWidget {
  const NavigationResultScreen({
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
    return Scaffold(
      appBar: AppBar(title: Text('Результат: $operation')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.route_rounded, size: 72, color: Colors.indigo),
              const SizedBox(height: 24),
              Text(
                operation,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ожидаемая страница после Back: $expectedBackDestination',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.router,
    required this.currentRoute,
    required this.replacementApi,
  });

  final String router;
  final String currentRoute;
  final String replacementApi;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.indigo.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              router,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text('Текущий route: $currentRoute'),
            Text('Replacement API: $replacementApi'),
          ],
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
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'monospace',
          fontSize: 13,
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.number,
    required this.title,
    required this.code,
    required this.expectation,
    required this.onPressed,
    this.color = Colors.indigo,
  });

  final String number;
  final String title;
  final String code;
  final String expectation;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  child: Text(number),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SelectableText(
              code,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 8),
            Text(expectation),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: color),
              onPressed: onPressed,
              child: Text('Запустить $title'),
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
              'Что считать успешной проверкой',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text('✓ push возвращается в Lab и передаёт результат'),
            Text('✓ replace удаляет Lab из стека'),
            Text('✓ системный Back и кнопка Back ведут одинаково'),
            Text('✓ интерактивный swipe-back не ломает стек'),
          ],
        ),
      ),
    );
  }
}
