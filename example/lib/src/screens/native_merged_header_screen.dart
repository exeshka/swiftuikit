import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:example/src/core/router/router.gr.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/services.dart';

@RoutePage()
class NativeMergedHeaderScreen extends StatefulWidget {
  const NativeMergedHeaderScreen({super.key});

  @override
  State<NativeMergedHeaderScreen> createState() =>
      _NativeMergedHeaderScreenState();
}

class _NativeMergedHeaderScreenState extends State<NativeMergedHeaderScreen> {
  static const _toolbarExtent = 52.0;
  static const _sectionHeaderExtent = 44.0;

  late final ScrollController _scrollController;
  late final _MergedHeaderController _headerController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _headerController = _MergedHeaderController(_scrollController);
  }

  @override
  void dispose() {
    _headerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final baseChromeExtent = topInset + _toolbarExtent;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        body: Stack(
          children: [
            const Positioned.fill(child: _PageBackground()),
            CustomScrollView(
              controller: _scrollController,
              scrollCacheExtent: const ScrollCacheExtent.pixels(700),
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(child: SizedBox(height: baseChromeExtent)),
                const SliverToBoxAdapter(child: _DemoIntro()),
                _DemoSectionSliver(
                  id: 'today',
                  title: 'Сегодня',
                  controller: _headerController,
                  headerExtent: _sectionHeaderExtent,
                  rows: const [
                    _DemoRow(
                      icon: Icons.motion_photos_on_rounded,
                      color: Color(0xFF0A84FF),
                      title: 'Проверить motion',
                      subtitle: 'Интерактивная анимация',
                    ),
                    _DemoRow(
                      icon: Icons.water_drop_rounded,
                      color: Color(0xFF64D2FF),
                      title: 'Liquid Glass',
                      subtitle: 'Один общий backdrop blur',
                    ),
                    _DemoRow(
                      icon: Icons.layers_rounded,
                      color: Color(0xFFBF5AF2),
                      title: 'Слои',
                      subtitle: 'Контент движется под шапкой',
                    ),
                  ],
                ),
                _DemoSectionSliver(
                  id: 'tomorrow',
                  title: 'Завтра',
                  controller: _headerController,
                  headerExtent: _sectionHeaderExtent,
                  rows: const [
                    _DemoRow(
                      icon: Icons.route_rounded,
                      color: Color(0xFFFF9F0A),
                      title: 'Переходы',
                      subtitle: 'Интерактивный swipe back',
                    ),
                    _DemoRow(
                      icon: Icons.call_to_action_rounded,
                      color: Color(0xFFFF375F),
                      title: 'Модальные окна',
                      subtitle: 'Динамическая высота',
                    ),
                    _DemoRow(
                      icon: Icons.vertical_align_top_rounded,
                      color: Color(0xFF30D158),
                      title: 'Scroll sheets',
                      subtitle: 'Snap detents и overlap',
                    ),
                  ],
                ),
                _DemoSectionSliver(
                  id: 'later',
                  title: 'Позже',
                  controller: _headerController,
                  headerExtent: _sectionHeaderExtent,
                  rows: const [
                    _DemoRow(
                      icon: Icons.blur_on_rounded,
                      color: Color(0xFF5E5CE6),
                      title: 'Unified blur',
                      subtitle: 'Без шва между заголовками',
                    ),
                    _DemoRow(
                      icon: Icons.animation_rounded,
                      color: Color(0xFFFF453A),
                      title: 'Push transition',
                      subtitle: 'Следующая секция вытесняет предыдущую',
                    ),
                    _DemoRow(
                      icon: Icons.speed_rounded,
                      color: Color(0xFF00C7BE),
                      title: 'Render geometry',
                      subtitle: 'Без GlobalKey и задержки',
                    ),
                  ],
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 280)),
              ],
            ),
            _UnifiedNavigationChrome(
              controller: _headerController,
              baseExtent: baseChromeExtent,
              topInset: topInset,
              toolbarExtent: _toolbarExtent,
              sectionHeaderExtent: _sectionHeaderExtent,
              onOpenShowcase: () {
                context.router.push(const ProductListRoute());
              },
            ),
            _SectionTitlesOverlay(
              controller: _headerController,
              baseExtent: baseChromeExtent,
              headerExtent: _sectionHeaderExtent,
            ),
          ],
        ),
      ),
    );
  }
}

class _PageBackground extends StatelessWidget {
  const _PageBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFD6D9), Color(0xFFF2F2F7), Color(0xFFE8E8ED)],
          stops: [0, 0.38, 1],
        ),
      ),
    );
  }
}

class _DemoIntro extends StatelessWidget {
  const _DemoIntro();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 4),
      child: Container(
        height: 174,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF646B), Color(0xFFFF2D55)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF2D55).withValues(alpha: 0.22),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              CupertinoIcons.rectangle_stack_fill,
              color: Colors.white,
              size: 30,
            ),
            Spacer(),
            Text(
              'Потяни список вверх',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Заголовок отделится от карточки и станет частью единого blur.',
              style: TextStyle(
                color: Color(0xE6FFFFFF),
                fontSize: 15,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoSectionSliver extends StatefulWidget {
  const _DemoSectionSliver({
    required this.id,
    required this.title,
    required this.controller,
    required this.headerExtent,
    required this.rows,
  });

  final Object id;
  final String title;
  final _MergedHeaderController controller;
  final double headerExtent;
  final List<_DemoRow> rows;

  @override
  State<_DemoSectionSliver> createState() => _DemoSectionSliverState();
}

class _DemoSectionSliverState extends State<_DemoSectionSliver> {
  static const _topSpacing = 14.0;

  @override
  void didUpdateWidget(_DemoSectionSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.id != widget.id) {
      oldWidget.controller.unregister(oldWidget.id);
    }
  }

  @override
  void dispose() {
    widget.controller.unregister(widget.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        widget.controller.register(
          id: widget.id,
          title: widget.title,
          scrollOffset: constraints.precedingScrollExtent + _topSpacing,
        );

        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, _topSpacing, 12, 0),
            child: _SectionCard(
              id: widget.id,
              title: widget.title,
              controller: widget.controller,
              headerExtent: widget.headerExtent,
              rows: widget.rows,
            ),
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.id,
    required this.title,
    required this.controller,
    required this.headerExtent,
    required this.rows,
  });

  final Object id;
  final String title;
  final _MergedHeaderController controller;
  final double headerExtent;
  final List<_DemoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: headerExtent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    if (controller.hasGeometry(id)) {
                      return const SizedBox.shrink();
                    }
                    return _SectionTitle(title);
                  },
                ),
              ),
            ),
          ),
          Divider(
            height: 0.5,
            thickness: 0.5,
            indent: 18,
            color: Colors.black.withValues(alpha: 0.1),
          ),
          for (var index = 0; index < rows.length; index++) ...[
            _DemoRowTile(row: rows[index]),
            if (index != rows.length - 1)
              Divider(
                height: 0.5,
                thickness: 0.5,
                indent: 66,
                color: Colors.black.withValues(alpha: 0.1),
              ),
          ],
        ],
      ),
    );
  }
}

class _DemoRow {
  const _DemoRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
}

class _DemoRowTile extends StatelessWidget {
  const _DemoRowTile({required this.row});

  final _DemoRow row;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 68,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: row.color,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(row.icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.title,
                    style: const TextStyle(
                      color: Color(0xFF1C1C1E),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    row.subtitle,
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_forward,
              color: Color(0xFFC7C7CC),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _UnifiedNavigationChrome extends StatelessWidget {
  const _UnifiedNavigationChrome({
    required this.controller,
    required this.baseExtent,
    required this.topInset,
    required this.toolbarExtent,
    required this.sectionHeaderExtent,
    required this.onOpenShowcase,
  });

  final _MergedHeaderController controller;
  final double baseExtent;
  final double topInset;
  final double toolbarExtent;
  final double sectionHeaderExtent;
  final VoidCallback onOpenShowcase;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final sections = controller.sections;
        final attachment = sections.isEmpty
            ? 0.0
            : controller.progressFor(
                sections.first,
                baseExtent: baseExtent,
                headerExtent: sectionHeaderExtent,
              );
        final chromeExtent = baseExtent + sectionHeaderExtent * attachment;

        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: chromeExtent,
          child: RepaintBoundary(
            child: ClipRect(
              child: BackdropFilter(
                filterConfig: const ImageFilterConfig.blur(
                  sigmaX: 22,
                  sigmaY: 22,
                  bounded: true,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF555C).withValues(alpha: 0.68),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.22),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: topInset,
                        left: 0,
                        right: 0,
                        height: toolbarExtent,
                        child: const Center(
                          child: Text(
                            'Шапки',
                            style: TextStyle(
                              color: Color(0xFF1C1C1E),
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: topInset,
                        right: 8,
                        height: toolbarExtent,
                        child: Center(
                          child: CupertinoButton(
                            padding: const EdgeInsets.all(10),
                            minimumSize: const Size(40, 40),
                            onPressed: onOpenShowcase,
                            child: const Icon(
                              CupertinoIcons.square_grid_2x2,
                              color: Color(0xFF1C1C1E),
                              size: 21,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitlesOverlay extends StatelessWidget {
  const _SectionTitlesOverlay({
    required this.controller,
    required this.baseExtent,
    required this.headerExtent,
  });

  final _MergedHeaderController controller;
  final double baseExtent;
  final double headerExtent;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final sections = controller.sections;

        return Positioned(
          top: baseExtent,
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: ClipRect(
              child: Stack(
                children: [
                  for (var index = 0; index < sections.length; index++)
                    _buildTitle(sections, index),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle(List<_SectionGeometry> sections, int index) {
    final section = sections[index];
    final normalTop = section.scrollOffset - controller.pixels;
    final progress = controller.progressFor(
      section,
      baseExtent: baseExtent,
      headerExtent: headerExtent,
    );
    final nextProgress = index + 1 >= sections.length
        ? 0.0
        : controller.progressFor(
            sections[index + 1],
            baseExtent: baseExtent,
            headerExtent: headerExtent,
          );
    final viewportTop =
        math.max(normalTop, baseExtent) - headerExtent * nextProgress;
    final localTop = viewportTop - baseExtent;
    final horizontalInset = 30.0 - 10.0 * progress;

    return Positioned(
      key: ValueKey(section.id),
      top: localTop,
      left: horizontalInset,
      right: 20,
      height: headerExtent,
      child: Align(
        alignment: Alignment.centerLeft,
        child: _SectionTitle(section.title),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFF9D343A),
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _MergedHeaderController extends ChangeNotifier {
  _MergedHeaderController(this.scrollController) {
    scrollController.addListener(_handleScroll);
  }

  final ScrollController scrollController;
  final Map<Object, _SectionGeometry> _sections = {};

  bool _notificationScheduled = false;
  bool _disposed = false;

  double get pixels {
    if (!scrollController.hasClients) {
      return 0;
    }
    return scrollController.position.pixels;
  }

  List<_SectionGeometry> get sections {
    return _sections.values.toList()
      ..sort((a, b) => a.scrollOffset.compareTo(b.scrollOffset));
  }

  bool hasGeometry(Object id) => _sections.containsKey(id);

  void register({
    required Object id,
    required String title,
    required double scrollOffset,
  }) {
    final previous = _sections[id];
    if (previous != null &&
        previous.title == title &&
        (previous.scrollOffset - scrollOffset).abs() < 0.01) {
      return;
    }

    _sections[id] = _SectionGeometry(
      id: id,
      title: title,
      scrollOffset: scrollOffset,
    );
    _scheduleNotification();
  }

  void unregister(Object id) {
    if (_sections.remove(id) != null) {
      _scheduleNotification();
    }
  }

  double progressFor(
    _SectionGeometry section, {
    required double baseExtent,
    required double headerExtent,
  }) {
    final top = section.scrollOffset - pixels;
    return ((baseExtent + headerExtent - top) / headerExtent)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  void _handleScroll() {
    notifyListeners();
  }

  void _scheduleNotification() {
    if (_notificationScheduled || _disposed) {
      return;
    }
    _notificationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationScheduled = false;
      if (!_disposed) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    scrollController.removeListener(_handleScroll);
    super.dispose();
  }
}

class _SectionGeometry {
  const _SectionGeometry({
    required this.id,
    required this.title,
    required this.scrollOffset,
  });

  final Object id;
  final String title;
  final double scrollOffset;
}
