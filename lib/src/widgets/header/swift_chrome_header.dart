import 'dart:math' show min, max;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'swift_header_chrome.dart';

class SwiftPinnedHeaderChromeSliver extends SingleChildRenderObjectWidget {
  const SwiftPinnedHeaderChromeSliver({
    super.key,
    required this.height,
    required this.chromeController,
    required Widget child,
  }) : super(child: child);

  final double height;
  final SwiftPinnedHeaderChromeController chromeController;

  @override
  RenderSwiftPinnedHeaderChrome createRenderObject(BuildContext context) {
    return RenderSwiftPinnedHeaderChrome(
      height: height,
      chromeController: chromeController,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderSwiftPinnedHeaderChrome renderObject) {
    renderObject
      ..height = height
      ..chromeController = chromeController
      ..devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
  }
}

class RenderSwiftPinnedHeaderChrome extends RenderSliverSingleBoxAdapter {
  RenderSwiftPinnedHeaderChrome({
    required double height,
    required SwiftPinnedHeaderChromeController chromeController,
    required double devicePixelRatio,
  })  : _height = height,
        _chromeController = chromeController,
        _devicePixelRatio = devicePixelRatio;

  double _height;
  double get height => _height;
  set height(double value) {
    if (_height == value) return;
    _height = value;
    markNeedsLayout();
  }

  SwiftPinnedHeaderChromeController _chromeController;
  set chromeController(SwiftPinnedHeaderChromeController value) {
    if (_chromeController == value) return;
    _chromeController = value;
    _chromeEntryRegistered = false;
    markNeedsLayout();
  }

  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (_devicePixelRatio == value) return;
    _devicePixelRatio = value;
    markNeedsLayout();
  }

  final Object _chromeId = Object();
  final LayerLink _link = LayerLink();
  bool _chromeEntryRegistered = false;

  @override
  void dispose() {
    _chromeController.remove(_chromeId);
    _chromeEntryRegistered = false;
    super.dispose();
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      geometry = SliverGeometry.zero;
      _unregisterChrome();
      return;
    }

    child.layout(
      BoxConstraints(
        maxWidth: constraints.crossAxisExtent,
        minHeight: _height,
        maxHeight: _height,
      ),
      parentUsesSize: true,
    );

    final childExtent = _height;
    final overlap = constraints.overlap;

    final pinned = overlap < -1e-10;
    final paintOrigin = pinned ? overlap : 0.0;
    final paintExtent = max(
      0.0,
      min(
        childExtent - constraints.scrollOffset,
        constraints.remainingPaintExtent + overlap,
      ),
    );

    geometry = SliverGeometry(
      scrollExtent: childExtent,
      paintOrigin: paintOrigin,
      paintExtent: paintExtent,
      maxPaintExtent: childExtent,
      hitTestExtent: childExtent,
      hasVisualOverflow: paintExtent < childExtent,
      maxScrollObstructionExtent: childExtent,
    );

    if (pinned) {
      _registerChrome(constraints.crossAxisExtent);
    } else {
      _unregisterChrome();
    }
  }

  void _registerChrome(double crossAxisExtent) {
    if (_chromeEntryRegistered) return;
    _chromeEntryRegistered = true;

    _chromeController.update(
      id: _chromeId,
      height: _height,
      visibleHeight: _height,
      child: SizedBox(width: crossAxisExtent, height: _height),
      link: _link,
      signature: 'chrome_$_height',
      replaceAll: true,
    );
  }

  void _unregisterChrome() {
    if (!_chromeEntryRegistered) return;
    _chromeEntryRegistered = false;
    _chromeController.remove(_chromeId);
  }

  @override
  double childMainAxisPosition(covariant RenderBox child) => 0;
}
