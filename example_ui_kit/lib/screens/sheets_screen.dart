import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

import '../router/app_router.dart';

/// The iOS 26 resizable sheet (`.sheet` with detents) in the three ways the kit offers it, over a striped page like the native
/// reference (`tools/native_sheet_detents_ref`):
///  * `showGlassSheet(context, ...)`: from any callback;
///  * `GlassSheetAutoRoute`: the sheet is a page of the router (here [SheetContentScreen]);
///  * `GlassSheetPresenter`: inside this page, driven by a bool, with the page behind it still usable.
@RoutePage()
class SheetsScreen extends StatefulWidget {
  const SheetsScreen({super.key});

  @override
  State<SheetsScreen> createState() => _SheetsScreenState();
}

// (label, detents, dismissible, initial)
final _variants = <(String, List<GlassSheetDetent>, bool, GlassSheetDetent?)>[
  ('large only', const [GlassSheetDetent.large], true, null),
  ('medium only', const [GlassSheetDetent.medium], true, null),
  ('small .25', const [GlassSheetDetent.fraction(0.25)], true, null),
  (
    '3 stops',
    const [
      GlassSheetDetent.fraction(0.3),
      GlassSheetDetent.fraction(0.6),
      GlassSheetDetent.large,
    ],
    true,
    null,
  ),
  (
    'height 320',
    const [GlassSheetDetent.height(320), GlassSheetDetent.large],
    true,
    null,
  ),
  (
    'no dismiss',
    const [GlassSheetDetent.medium, GlassSheetDetent.large],
    false,
    null,
  ),
  (
    'start large',
    const [GlassSheetDetent.medium, GlassSheetDetent.large],
    true,
    GlassSheetDetent.large,
  ),
];

class _SheetsScreenState extends State<SheetsScreen> {
  final _originMain = GlassSheetOriginController();
  final _originCircle = GlassSheetOriginController();
  final _originMenu = GlassSheetOriginController();
  final _originGroup = GlassSheetOriginController();
  final _name = TextEditingController();

  bool _inPage = false;
  int _taps = 0;

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    return Scaffold(
      backgroundColor: t.colors.background,
      body: GlassSheetPresenter(
        isPresented: _inPage,
        onDismissed: () => setState(() => _inPage = false),
        modal: false,
        detents: const [
          GlassSheetDetent.fraction(0.22),
          GlassSheetDetent.medium,
          GlassSheetDetent.large,
        ],
        sheetChild: const _Rows(title: 'In the page'),
        child: Stack(
          children: [
            Column(
              children: [
                for (var i = 0; i < 40; i++)
                  Expanded(
                    child: ColoredBox(
                      color: i.isEven
                          ? const Color(0xFFE53935)
                          : const Color(0xFF1E88E5),
                      child: const SizedBox.expand(),
                    ),
                  ),
              ],
            ),
            Positioned(
              left: 16,
              bottom: 34,
              child: GlassSheetOrigin(
                controller: _originCircle,
                child: GlassButton.circle(
                  icon: RavelIcon(RavelIconKind.plus),
                  semanticLabel: 'Attach',
                  onPressed: () => showGlassSheet<void>(
                    context,
                    origin: _originCircle,
                    detents: const [
                      GlassSheetDetent.fraction(0.5),
                      GlassSheetDetent.large,
                    ],
                    child: const _Rows(title: 'From a circle'),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    GlassSheetOrigin(
                      controller: _originMain,
                      child: GlassButton(
                        label: 'showGlassSheet (medium + large)',
                        style: GlassButtonStyle.glassProminent,
                        onPressed: () => showGlassSheet<void>(
                          context,
                          origin: _originMain,
                          child: const _Rows(title: 'showGlassSheet'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassButton(
                      label: 'Router page (GlassSheetAutoRoute)',
                      onPressed: () =>
                          context.router.push(const SheetContentRoute()),
                    ),
                    const SizedBox(height: 12),
                    GlassButton(
                      label: _inPage
                          ? 'Close the sheet in the page'
                          : 'GlassSheetPresenter (in the page)',
                      onPressed: () => setState(() => _inPage = !_inPage),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final v in _variants)
                          GlassButton(
                            label: v.$1,
                            size: GlassButtonSize.small,
                            onPressed: () => showGlassSheet<void>(
                              context,
                              child: _Rows(title: v.$1),
                              detents: v.$2,
                              dismissible: v.$3,
                              initialDetent: v.$4,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        GlassButton(
                          label: 'alert',
                          size: GlassButtonSize.small,
                          onPressed: () => showGlassAlert<bool>(
                            context,
                            title: 'Delete the file?',
                            message: 'This cannot be undone. The file will be removed from every device.',
                            actions: const [
                              GlassAlertAction(label: 'OK', value: true),
                              GlassAlertAction(
                                label: 'Cancel',
                                role: GlassAlertRole.cancel,
                                value: false,
                              ),
                            ],
                          ),
                        ),
                        GlassButton(
                          label: 'alert x3',
                          size: GlassButtonSize.small,
                          onPressed: () => showGlassAlert<int>(
                            context,
                            title: 'Delete the file?',
                            message: 'This cannot be undone. The file will be removed from every device.',
                            actions: const [
                              GlassAlertAction(label: 'Keep both', value: 1),
                              GlassAlertAction(label: 'Replace', value: 2),
                              GlassAlertAction(
                                label: 'Cancel',
                                role: GlassAlertRole.cancel,
                              ),
                            ],
                          ),
                        ),
                        GlassButton(
                          label: 'destructive',
                          size: GlassButtonSize.small,
                          onPressed: () => showGlassAlert<bool>(
                            context,
                            title: 'Delete the file?',
                            message: 'This cannot be undone. The file will be removed from every device.',
                            actions: const [
                              GlassAlertAction(
                                label: 'Delete',
                                role: GlassAlertRole.destructive,
                                value: true,
                              ),
                              GlassAlertAction(
                                label: 'Cancel',
                                role: GlassAlertRole.cancel,
                                value: false,
                              ),
                            ],
                          ),
                        ),
                        GlassButton(
                          label: 'field',
                          size: GlassButtonSize.small,
                          onPressed: () => showGlassAlert<bool>(
                            context,
                            title: 'Delete the file?',
                            message: 'This cannot be undone. The file will be removed from every device.',
                            fields: [
                              GlassAlertField(
                                controller: _name,
                                placeholder: 'Name',
                                autofocus: true,
                              ),
                            ],
                            actions: const [
                              GlassAlertAction(
                                label: 'OK',
                                role: GlassAlertRole.preferred,
                                value: true,
                              ),
                              GlassAlertAction(
                                label: 'Cancel',
                                role: GlassAlertRole.cancel,
                                value: false,
                              ),
                            ],
                          ),
                        ),
                        GlassButton(
                          label: 'short',
                          size: GlassButtonSize.small,
                          onPressed: () => showGlassAlert<void>(
                            context,
                            title: 'Saved',
                            actions: const [GlassAlertAction(label: 'OK')],
                          ),
                        ),
                        GlassButton(
                          label: 'preferred',
                          size: GlassButtonSize.small,
                          onPressed: () => showGlassAlert<void>(
                            context,
                            title: 'Delete the file?',
                            message: 'This cannot be undone. The file will be removed from every device.',
                            actions: const [
                              GlassAlertAction(
                                label: 'Delete',
                                role: GlassAlertRole.destructive,
                              ),
                              GlassAlertAction(
                                label: 'Save',
                                role: GlassAlertRole.preferred,
                              ),
                              GlassAlertAction(
                                label: 'Cancel',
                                role: GlassAlertRole.cancel,
                              ),
                            ],
                          ),
                        ),
                        GlassSheetOrigin(
                          controller: _originMenu,
                          child: GlassButton(
                            label: 'dialog',
                            size: GlassButtonSize.small,
                            onPressed: () => showGlassActionDialog<void>(
                              context,
                              origin: _originMenu,
                              title: 'Choose an action',
                              message:
                                  'Pick what to do with the selected items.',
                              actions: const [
                                GlassAlertAction(label: 'Duplicate'),
                                GlassAlertAction(label: 'Move to folder'),
                                GlassAlertAction(
                                  label: 'Delete',
                                  role: GlassAlertRole.destructive,
                                ),
                                GlassAlertAction(
                                  label: 'Cancel',
                                  role: GlassAlertRole.cancel,
                                ),
                              ],
                            ),
                          ),
                        ),
                        GlassButton(
                          label: 'dialog (bottom)',
                          size: GlassButtonSize.small,
                          onPressed: () => showGlassActionDialog<void>(
                            context,
                            title: 'Choose an action',
                            message: 'Pick what to do with the selected items.',
                            actions: const [
                              GlassAlertAction(label: 'Duplicate'),
                              GlassAlertAction(label: 'Move to folder'),
                              GlassAlertAction(
                                label: 'Delete',
                                role: GlassAlertRole.destructive,
                              ),
                              GlassAlertAction(
                                label: 'Cancel',
                                role: GlassAlertRole.cancel,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // a toolbar group: the menu grows out of the whole capsule
                    Align(
                      alignment: Alignment.centerRight,
                      child: GlassSheetOrigin(
                        controller: _originGroup,
                        child: GlassToolbarCapsule(
                          items: [
                            GlassToolbarItem(
                              id: 'search',
                              child: const Icon(Icons.search, size: 22),
                              onPressed: () {},
                            ),
                            GlassToolbarItem(
                              id: 'compose',
                              child: const Icon(Icons.edit_square, size: 22),
                              onPressed: () => showGlassMenu(
                                context,
                                origin: _originGroup,
                                entries: [
                                  GlassMenuItem(
                                    label: 'New chat',
                                    leading: const Icon(Icons.edit_square),
                                  ),
                                  GlassMenuItem(
                                    label: 'New folder',
                                    leading: const Icon(Icons.folder_outlined),
                                  ),
                                  const GlassMenuDivider(),
                                  GlassMenuItem(
                                    label: 'Delete all',
                                    destructive: true,
                                    leading: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassButton(
                      label: 'Page taps behind the sheet: $_taps',
                      style: GlassButtonStyle.bordered,
                      onPressed: () => setState(() => _taps++),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The content of the sheet when it is a router page: the kit's own [ChromeScaffold] (a title bar with glass buttons on top, a bottom
/// action bar, progressive blur under both) lives inside the sheet. The list uses the scroll controller of the sheet, so dragging the
/// content moves the sheet and, once it is full, scrolls. The router entry says `scrollable: false` for that.
@RoutePage()
class SheetContentScreen extends StatelessWidget {
  const SheetContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: ChromeScaffold(
        // transparent: the glass of the sheet shows through at the partial detents
        backgroundColor: Colors.transparent,
        // a sheet has no status bar: the bar sits a few points under the grabber
        minTopInset: 15.5,
        // like a native bottom toolbar: the button is lifted by the whole home-indicator inset of the sheet
        bottomBarSafeAreaShare: 1,
        // the native header: a 44 pt bar with glass buttons and a small centered title
        topBar: LargeTitleHeader(
          title: 'Filters',
          style: NavTitleStyle.inline,
          automaticallyImplyLeading: false,
          leading: GlassCircleButton(
            icon: RavelIcon(RavelIconKind.close),
            semanticLabel: 'Close',
            onPressed: () => context.router.maybePop(),
          ),
          trailing: [
            GlassButton(
              label: 'Done',
              style: GlassButtonStyle.glassProminent,
              size: GlassButtonSize.toolbar,
              onPressed: () => context.router.maybePop(),
            ),
          ],
        ),
        // edge: bottom, or the bar would register as a top one and push the list down by its height
        bottomBar: ChromeBar(
          edge: ChromeEdge.bottom,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GlassButton(
              label: 'Show 128 results',
              size: GlassButtonSize.large,
              expand: true,
              style: GlassButtonStyle.glassProminent,
              onPressed: () => context.router.maybePop(),
            ),
          ),
        ),
        body: ListView.builder(
          controller: GlassSheet.scrollControllerOf(context),
          physics: const AlwaysScrollableScrollPhysics(),
          // the scaffold gives the list the room under its bars through MediaQuery.padding
          itemCount: 30,
          itemBuilder: (context, i) => Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: t.colors.separator)),
            ),
            child: Text('Filter $i', style: t.typography.body),
          ),
        ),
      ),
    );
  }
}

class _Rows extends StatelessWidget {
  const _Rows({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final t = SwiftUiTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              title,
              style: t.typography.title.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < 14; i++)
            Container(
              height: 52,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: t.colors.separator)),
              ),
              child: Text('Row $i', style: t.typography.body),
            ),
        ],
      ),
    );
  }
}
