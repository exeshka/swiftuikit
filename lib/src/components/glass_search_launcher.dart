import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/swift_ui_theme.dart';
import 'glass_search_bar.dart';

/// Builds what the search layer shows under the field for the current [query] (it rebuilds on every keystroke).
typedef GlassSearchResultsBuilder = Widget Function(BuildContext context, String query);

/// The search field of a page that does not type in place. It looks like a [GlassSearchBar] but is not editable: tapping it opens a
/// search layer above the whole page. The field slides up to the top, the page fades out, the results are shown under it, and a
/// cancel button sits next to the field (and an optional [bottomBuilder] rides above the keyboard). Cancel, the system back
/// gesture or popping the route closes the layer, the field slides back to where it was and the query is cleared.
///
/// This is how a messenger or a native large-title app searches: the page keeps its own list, the layer is where the query lives.
/// Put the launcher where the search bar would be (a [CollapsibleBar] section, a [ChromeBar] column...):
///
/// ```dart
/// GlassSearchLauncher(
///   hintText: 'Ticker or channel',
///   onChanged: bloc.search,
///   resultsBuilder: (context, query) => ResultsList(query: query),
/// )
/// ```
///
/// The layer is a route of the nearest ([useRootNavigator]: the root) [Navigator], so what [resultsBuilder] and [bottomBuilder]
/// build lives under the app, not under the page: an inherited value that only the page provides (a `BlocProvider`, say) has to be
/// re-provided inside the builder.
class GlassSearchLauncher extends StatefulWidget {
  const GlassSearchLauncher({
    super.key,
    required this.resultsBuilder,
    this.bottomBuilder,
    this.controller,
    this.hintText = 'Search',
    this.cancelLabel = 'Cancel',
    this.onChanged,
    this.onSubmitted,
    this.onOpened,
    this.onClosed,
    this.height = 44,
    this.liquid = true,
    this.fill,
    this.cancelAsButton = true,
    this.backgroundColor,
    this.layerPadding = const EdgeInsets.symmetric(horizontal: 16),
    this.useRootNavigator = true,
  });

  /// What the layer shows under the field.
  final GlassSearchResultsBuilder resultsBuilder;

  /// Something docked at the bottom of the layer, above the keyboard (a filter segmented control, say). It slides in with the layer.
  final WidgetBuilder? bottomBuilder;

  /// The query. Owned by the launcher when null. Cleared when the layer closes.
  final TextEditingController? controller;
  final String hintText;
  final String cancelLabel;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// The layer started opening.
  final VoidCallback? onOpened;

  /// The layer is closed (the query has been cleared). Tell the page to drop the filter here.
  final VoidCallback? onClosed;
  final double height;

  /// true (default): the field is a glass plate, as [GlassSearchBar.liquid]. false: a flat field, no backdrop pass.
  final bool liquid;
  final Color? fill;

  /// true (default): a round cross button, the messenger look. false: the text [cancelLabel].
  final bool cancelAsButton;

  /// The layer's page colour; the theme background when null.
  final Color? backgroundColor;

  /// The inset of the field from the sides of the screen once the layer is open (the launcher itself sits where you put it).
  final EdgeInsets layerPadding;

  /// true (default): the layer covers the whole app (the bars of an enclosing shell too), not only the nested navigator the page is in.
  final bool useRootNavigator;

  @override
  State<GlassSearchLauncher> createState() => GlassSearchLauncherState();
}

/// The state of a [GlassSearchLauncher]; [open] opens the layer from code (a shortcut, a test).
class GlassSearchLauncherState extends State<GlassSearchLauncher> {
  final _fieldKey = GlobalKey();
  TextEditingController? _ownController;
  TextEditingController get _controller => widget.controller ?? (_ownController ??= TextEditingController());
  bool _open = false;

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  /// Opens the search layer, as a tap on the field does.
  Future<void> open() async {
    if (_open) return;
    final box = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final from = box.localToGlobal(Offset.zero) & box.size;
    final nav = Navigator.of(context, rootNavigator: widget.useRootNavigator);
    setState(() => _open = true);
    widget.onOpened?.call();
    await nav.push<void>(
      _GlassSearchRoute(
        builder: (context, animation) => _SearchLayer(
          animation: animation,
          from: from,
          launcher: widget,
          controller: _controller,
        ),
      ),
    );
    if (!mounted) return;
    _controller.clear();
    setState(() => _open = false);
    widget.onClosed?.call();
  }

  @override
  Widget build(BuildContext context) {
    // Visibility, not Opacity: an Opacity layer would put the glass field into an offscreen layer and it would lose its backdrop.
    return Visibility(
      visible: !_open,
      maintainState: true,
      maintainSize: true,
      maintainAnimation: true,
      child: GestureDetector(
        key: _fieldKey,
        behavior: HitTestBehavior.opaque,
        onTap: open,
        child: AbsorbPointer(
          child: GlassSearchBar(
            controller: _controller,
            hintText: widget.hintText,
            height: widget.height,
            liquid: widget.liquid,
            fill: widget.fill,
          ),
        ),
      ),
    );
  }
}

/// Transparent while it opens or closes (the page under it is still seen), opaque once it is open (the page is no longer painted).
class _GlassSearchRoute extends PageRoute<void> {
  _GlassSearchRoute({required this.builder});

  final Widget Function(BuildContext context, Animation<double> animation) builder;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 380);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 150);

  @override
  bool get opaque => true;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) =>
      builder(context, animation);

  // the layer animates itself
  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

class _SearchLayer extends StatefulWidget {
  const _SearchLayer({
    required this.animation,
    required this.from,
    required this.launcher,
    required this.controller,
  });

  final Animation<double> animation;
  final Rect from;
  final GlassSearchLauncher launcher;
  final TextEditingController controller;

  @override
  State<_SearchLayer> createState() => _SearchLayerState();
}

class _SearchLayerState extends State<_SearchLayer> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // the keyboard comes up with the layer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _close() {
    _focus.unfocus();
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.launcher;
    final t = SwiftUiTheme.of(context);
    final mq = MediaQuery.of(context);
    final top = mq.padding.top + 6;
    final insetBottom = mq.viewInsets.bottom;
    final screenW = mq.size.width;
    final resultsPadding = mq.padding.copyWith(top: 0, bottom: math.max(mq.padding.bottom, insetBottom));
    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, _) {
        final p = Curves.easeOutCubic.transform(widget.animation.value.clamp(0.0, 1.0));
        final y = widget.from.top + (top - widget.from.top) * p;
        final left = widget.from.left + (l.layerPadding.left - widget.from.left) * p;
        final right = (screenW - widget.from.right) + (l.layerPadding.right - (screenW - widget.from.right)) * p;
        return Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: p,
                child: ColoredBox(color: l.backgroundColor ?? t.colors.background),
              ),
            ),
            // what is under the field
            Positioned(
              left: 0,
              right: 0,
              top: top + l.height + 6,
              bottom: 0,
              child: Opacity(
                opacity: Curves.easeIn.transform(((p - 0.35) / 0.65).clamp(0.0, 1.0)),
                child: MediaQuery(
                  data: mq.copyWith(padding: resultsPadding),
                  child: ListenableBuilder(
                    listenable: widget.controller,
                    builder: (context, _) => l.resultsBuilder(context, widget.controller.text),
                  ),
                ),
              ),
            ),
            Positioned(
              left: left,
              right: right,
              top: y,
              child: GlassSearchBar(
                controller: widget.controller,
                focusNode: _focus,
                hintText: l.hintText,
                cancelLabel: l.cancelLabel,
                height: l.height,
                liquid: l.liquid,
                fill: l.fill,
                cancelAsButton: l.cancelAsButton,
                alwaysShowCancel: true,
                onChanged: l.onChanged,
                onSubmitted: l.onSubmitted,
                onCancel: _close,
              ),
            ),
            if (l.bottomBuilder != null)
              Positioned(
                left: 12,
                right: 12,
                // max(), not a switch at 0: the bar rides on the keyboard and must not dip below its resting place on the way
                bottom: math.max(insetBottom, mq.padding.bottom) + 8,
                // slides in (a fade would put the glass into an offscreen layer and the track would lose its backdrop)
                child: Transform.translate(offset: Offset(0, (1 - p) * 80), child: l.bottomBuilder!(context)),
              ),
          ],
        );
      },
    );
  }
}
