import 'package:flutter/widgets.dart';

class ToolbarButton extends StatelessWidget {
  final Widget child;
  final void Function() onTap;
  final EdgeInsetsGeometry? paddings;
  const ToolbarButton({
    super.key,
    required this.child,
    required this.onTap,
    this.paddings,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        onTap();
      },
      child: Container(
        constraints: BoxConstraints(
          maxWidth: .infinity,
          minWidth: 36,
          maxHeight: 36,
          minHeight: 36,
        ),
        padding: paddings,
        child: child,
      ),
    );
  }
}
