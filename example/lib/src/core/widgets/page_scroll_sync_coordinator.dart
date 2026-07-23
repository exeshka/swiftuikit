import 'package:flutter/material.dart';

class PageScrollSyncCoordinator {
  PageScrollSyncCoordinator({required this.snapPoint});

  final double snapPoint;
  final Set<ScrollController> _controllers = {};
  bool _isRevealed = false;

  bool get isRevealed => _isRevealed;
  double get initialOffsetForNewController => _isRevealed ? snapPoint : 0.0;

  void attach(ScrollController controller) {
    _controllers.add(controller);
    controller.addListener(() => _onScroll(controller));
  }

  void detach(ScrollController controller) {
    _controllers.remove(controller);
  }

  /// Публичный метод — вызывай его при каждой сборке страницы, а не только
  /// один раз при создании контроллера. Безопасно дергать сколько угодно раз:
  /// если всё уже синхронизировано — ничего не произойдёт.
  void syncIfNeeded(ScrollController controller) {
    if (!controller.hasClients) return;
    final position = controller.position;
    if (position.isScrollingNotifier.value)
      return; // не мешаем активному жесту/полёту

    final target = _isRevealed ? snapPoint : 0.0;
    if ((controller.offset - target).abs() > 0.5) {
      controller.jumpTo(target);
    }
  }

  void _onScroll(ScrollController controller) {
    if (!controller.hasClients) return;
    final position = controller.position;
    if (position.isScrollingNotifier.value) return;

    final revealed = controller.offset >= snapPoint - 1;
    if (revealed != _isRevealed) {
      _isRevealed = revealed;
      for (final c in _controllers) {
        if (c != controller) syncIfNeeded(c);
      }
    }
  }

  void dispose() {
    _controllers.clear();
  }
}
