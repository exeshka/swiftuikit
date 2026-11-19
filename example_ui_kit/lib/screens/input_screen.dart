import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

/// Chat composer on liquid glass (native reference: tools/native_glass_ref `input`): a plus circle and a text field plate
/// that grows with its text, with a mic or a send button inside.
@RoutePage()
class InputScreen extends StatefulWidget {
  const InputScreen({super.key});
  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _text = TextEditingController();
  bool _chips = true;
  bool _nav = true;
  bool _blur = true;
  int _tab = 0;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    final empty = _text.text.isEmpty;
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset:
          false, // ChromeScaffold follows the keyboard itself
      body: ChromeScaffold(
        topBar: const LargeTitleHeader(title: 'Input'),
        bottomBlur: _blur,
        bottomBar: BottomDock(
          floating: _chips
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      for (final label in const [
                        'Summarize',
                        'Translate',
                        'Explain',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: LiquidGlass(
                            height: 36,
                            interactive: true,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Center(
                                child: Text(
                                  label,
                                  style: t.typography.body.copyWith(
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              : null,
          composer: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              // native: the plus button stays centered next to a growing field
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GlassCircleButton(
                  icon: RavelIcon(RavelIconKind.plus),
                  size: 56,
                  onPressed: () => setState(() => _chips = !_chips),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassTextField(
                    controller: _text,
                    hintText: 'Message',
                    onChanged: (_) => setState(() {}),
                    trailing: empty
                        ? Icon(
                            Icons.mic_none_rounded,
                            size: 22,
                            color: t.glass.glassIcon.withValues(alpha: 0.6),
                          )
                        : GestureDetector(
                            onTap: () => setState(_text.clear),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: t.colors.accent,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_upward_rounded,
                                size: 20,
                                color: t.colors.onAccent,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          navBar: _nav
              ? GlassTabBar(
                  tabs: const [
                    GlassTab(
                      icon: RavelIcon(RavelIconKind.chat),
                      label: 'Chats',
                    ),
                    GlassTab(
                      icon: RavelIcon(RavelIconKind.tasks),
                      label: 'Tasks',
                    ),
                    GlassTab(
                      icon: RavelIcon(RavelIconKind.artifacts),
                      label: 'Files',
                    ),
                  ],
                  selectedIndex: _tab,
                  onSelected: (i) => setState(() => _tab = i),
                )
              : null,
        ),
        body: ListView.separated(
          // explicit padding replaces the one ListView takes from MediaQuery: the header and the dock are added by hand
          padding: EdgeInsets.fromLTRB(
            16,
            16 + MediaQuery.paddingOf(context).top,
            16,
            16 + MediaQuery.paddingOf(context).bottom,
          ),
          itemCount: 30,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (_, i) => i == 0
              ? Row(
                  children: [
                    // demo toggles
                    GestureDetector(
                      onTap: () => setState(() => _nav = !_nav),
                      child: Text('[nav bar]', style: t.typography.body),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => setState(() => _blur = !_blur),
                      child: Text('[bottom blur]', style: t.typography.body),
                    ),
                  ],
                )
              : Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF262626),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      'Message $i — The quick brown fox jumps over the lazy dog',
                      style: t.typography.body,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
