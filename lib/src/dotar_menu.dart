import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dotar_menu_controller.dart';

/// The company's site, opened by the signature at the menu's foot.
const _dotarUrl = 'http://dotarsoluciones.com.ar';

/// Plus Jakarta Sans as the package bundles it (fonts/, OFL), named with the
/// package so any app draws it without declaring the font itself.
TextStyle _jakarta({
  required Color color,
  required double fontSize,
  FontWeight? fontWeight,
}) => TextStyle(
  fontFamily: 'PlusJakartaSans',
  package: 'dotar_flutter_menu',
  color: color,
  fontSize: fontSize,
  fontWeight: fontWeight,
);

/// Who is signed in, shown at the top of the menu.
@immutable
class DotarMenuUser {
  const DotarMenuUser({required this.name, this.subtitle, this.avatarUrl});

  /// Shown whole, over as many lines as it needs (DEAM-Resto #233: "me
  /// gustaria que figurara el nombre completo"; one line cut with an ellipsis
  /// until then).
  final String name;

  /// Under the name, a role say. Null shows nothing.
  final String? subtitle;

  /// A photo for the avatar; without one, the avatar shows [initials].
  final String? avatarUrl;

  /// The first letters of the first and the last word of [name], upper case:
  /// "Juan Pérez" is "JP".
  String get initials {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.first.isEmpty) return '';
    final first = words.first.characters.first;
    final last = words.length > 1 ? words.last.characters.first : '';
    return '$first$last'.toUpperCase();
  }
}

/// What [DotarMenu.items] and [DotarMenu.bottomItems] hold: a
/// [DotarMenuItem] on its own, or a [DotarMenuSection] of them under a title.
@immutable
sealed class DotarMenuEntry {
  const DotarMenuEntry();
}

/// One entry of the menu: [onTap] runs and the menu closes.
class DotarMenuItem extends DotarMenuEntry {
  const DotarMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.visible = true,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// False leaves the item out, and only it (DEAM-Resto #207: the panel hid
  /// Estadísticas and Logs each on its own).
  final bool visible;

  /// True marks the entry of the screen the user is on: it is drawn on a
  /// brand-tinted background and screen readers announce it as selected. The
  /// app works it out from its current route.
  final bool selected;
}

/// A group of [items] under a [title], among the menu's loose items. A
/// section whose items are all hidden is left out, title included.
class DotarMenuSection extends DotarMenuEntry {
  const DotarMenuSection({required this.title, required this.items});

  final String title;
  final List<DotarMenuItem> items;
}

/// The light/dark switch above the bottom items. The app owns the mode: it
/// passes the current one and changes it in [onChanged].
@immutable
class DotarMenuModeSwitch {
  const DotarMenuModeSwitch({
    required this.isDark,
    required this.onChanged,
    this.label = 'Modo',
  });

  final bool isDark;

  /// Called with the mode chosen: true for dark.
  final ValueChanged<bool> onChanged;

  /// DEAM-Resto #235: "dice Tema y deberia decir Modo".
  final String label;
}

/// The side menu, as DEAM-Resto's `AnimatedDrawerContent` draws it: a
/// rotating dark gradient with three drifting orbs under a blur, and a 240 px
/// column with [header], [user], the logout, [items], and at the bottom
/// [modeSwitch], [bottomItems] and the company's signature with [version].
///
/// It closes itself after an item or the logout through the
/// [DotarMenuController] of the [DotarMenuShell] it is the menu of.
class DotarMenu extends StatefulWidget {
  const DotarMenu({
    super.key,
    this.header,
    this.user,
    this.onLogout,
    this.logoutLabel = 'Cerrar Sesión',
    this.items = const [],
    this.bottomItems = const [],
    this.modeSwitch,
    this.version,
    this.brandColor,
    this.brandLightColor,
  });

  /// At the top, centred, with 16 px above and below: an app's brand, say
  /// (DEAM-Resto shows its logo 72 px tall). Null leaves a 50 px gap.
  final Widget? header;

  final DotarMenuUser? user;

  /// Under the user, after the menu closes. Null hides the logout.
  final VoidCallback? onLogout;

  final String logoutLabel;

  /// Under the logout: items, sections of them, or both mixed.
  final List<DotarMenuEntry> items;

  /// At the bottom, compact, under [modeSwitch]: items, sections, or both.
  final List<DotarMenuEntry> bottomItems;

  /// Null hides the switch.
  final DotarMenuModeSwitch? modeSwitch;

  /// The app's version, shown as "v[version]" under the signature. Null,
  /// while it is not known say, shows nothing.
  final String? version;

  /// The avatar's border and the first orb. Null is the theme's primary
  /// color.
  final Color? brandColor;

  /// The third orb. Null is [brandColor] lightened 20% toward white.
  final Color? brandLightColor;

  @override
  State<DotarMenu> createState() => _DotarMenuState();
}

class _DotarMenuState extends State<DotarMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  void _close() => context
      .getInheritedWidgetOfExactType<DotarMenuScope>()
      ?.notifier
      ?.close();

  @override
  Widget build(BuildContext context) {
    final brand = widget.brandColor ?? Theme.of(context).colorScheme.primary;
    final brandLight =
        widget.brandLightColor ?? Color.lerp(brand, Colors.white, 0.2)!;
    final user = widget.user;
    final onLogout = widget.onLogout;
    final modeSwitch = widget.modeSwitch;
    final version = widget.version;

    return Stack(
      children: [
        // Animated gradient background
        AnimatedBuilder(
          animation: _bgController,
          builder: (context, _) {
            final t = _bgController.value;
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(
                    math.cos(t * 2 * math.pi) * 0.5,
                    math.sin(t * 2 * math.pi) * 0.5,
                  ),
                  end: Alignment(
                    math.sin(t * 2 * math.pi + 1) * 0.5,
                    math.cos(t * 2 * math.pi + 1) * 0.5,
                  ),
                  colors: const [
                    Color(0xFF1E1E2C),
                    Color(0xFF4A2010),
                    Color(0xFF1E1E2C),
                    Color(0xFF102030),
                  ],
                  stops: [
                    0.0,
                    0.3 + math.sin(t * math.pi) * 0.1,
                    0.7 + math.cos(t * math.pi) * 0.1,
                    1.0,
                  ],
                ),
              ),
            );
          },
        ),
        // Floating orbs with blur
        ..._buildOrbs(brand, brandLight),
        // Blur overlay
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              color: const Color(0xFF1E1E2C).withValues(alpha: 0.15),
            ),
          ),
        ),
        // Content
        SafeArea(
          child: SizedBox(
            width: 240,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.header case final header?) ...[
                  const SizedBox(height: 16),
                  Center(child: header),
                  const SizedBox(height: 16),
                ] else
                  const SizedBox(height: 50),
                if (user != null) ...[
                  _buildUser(user, brand),
                  const SizedBox(height: 12),
                ],
                if (onLogout != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: GestureDetector(
                      onTap: () {
                        _close();
                        onLogout();
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: Colors.redAccent.withValues(alpha: 0.7),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.logoutLabel,
                            style: _jakarta(
                              color: Colors.redAccent.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 50),
                ..._buildEntries(widget.items, brand),
                const Spacer(),
                if (modeSwitch != null) _buildModeSwitch(modeSwitch),
                ..._buildEntries(widget.bottomItems, brand, compact: true),
                const SizedBox(height: 16),
                // DEAM-Resto #211 (S10): at the bottom, centred, with the
                // version installed.
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          try {
                            await launchUrl(
                              Uri.parse(_dotarUrl),
                              mode: LaunchMode.externalApplication,
                            );
                          } catch (_) {}
                        },
                        child: Text(
                          'por Dotar Soluciones SAS',
                          style: _jakarta(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (version != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'v$version',
                          style: _jakarta(color: Colors.white24, fontSize: 10),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Avatar + name
  Widget _buildUser(DotarMenuUser user, Color brand) {
    final avatarUrl = user.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final subtitle = user.subtitle;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: brand, width: 3),
              color: hasAvatar ? Colors.transparent : Colors.grey.shade800,
              image: hasAvatar
                  ? DecorationImage(
                      image: NetworkImage(avatarUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: hasAvatar
                ? null
                : Center(
                    child: Text(
                      user.initials,
                      style: _jakarta(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: _jakarta(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: _jakarta(color: Colors.white70, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOrbs(Color brand, Color brandLight) {
    return [
      // Orb 1 - brand
      AnimatedBuilder(
        animation: _bgController,
        builder: (context, _) {
          final t = _bgController.value;
          return Positioned(
            left: 20 + math.sin(t * 2 * math.pi) * 30,
            top: 120 + math.cos(t * 2 * math.pi) * 40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    brand.withValues(alpha: 0.6),
                    brand.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      // Orb 2 - purple/blue
      AnimatedBuilder(
        animation: _bgController,
        builder: (context, _) {
          final t = _bgController.value;
          return Positioned(
            right: -20 + math.cos(t * 2 * math.pi + 2) * 25,
            bottom: 200 + math.sin(t * 2 * math.pi + 2) * 35,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6C3BDB).withValues(alpha: 0.45),
                    const Color(0xFF6C3BDB).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      // Orb 3 - brand, lighter
      AnimatedBuilder(
        animation: _bgController,
        builder: (context, _) {
          final t = _bgController.value;
          return Positioned(
            left: 60 + math.sin(t * 2 * math.pi + 4) * 20,
            bottom: 80 + math.cos(t * 2 * math.pi + 4) * 30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    brandLight.withValues(alpha: 0.4),
                    brandLight.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ];
  }

  /// The visible items of [entries], each section's under its title; a
  /// section with no visible item draws nothing.
  List<Widget> _buildEntries(
    List<DotarMenuEntry> entries,
    Color brand, {
    bool compact = false,
  }) => [
    for (final entry in entries)
      if (entry case final DotarMenuItem item when item.visible)
        _buildItem(item, brand, compact: compact)
      else if (entry case DotarMenuSection(
        :final title,
        :final items,
      ) when items.any((item) => item.visible)) ...[
        _buildSectionTitle(title),
        for (final item in items)
          if (item.visible) _buildItem(item, brand, compact: compact),
      ],
  ];

  /// A section's title, lined up with the items' icons.
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
      child: Text(
        title,
        style: _jakarta(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// One entry; the menu closes after its action. A selected one sits on a
  /// brand-tinted background inset 12 px, so its icon and label keep the
  /// place they have unselected.
  Widget _buildItem(DotarMenuItem item, Color brand, {bool compact = false}) {
    Widget content = Padding(
      padding: EdgeInsets.symmetric(
        vertical: compact ? 10.0 : 16.0,
        horizontal: 12.0,
      ),
      child: Row(
        children: [
          Icon(item.icon, color: Colors.white, size: 28),
          const SizedBox(width: 16),
          Text(
            item.label,
            style: _jakarta(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
    if (item.selected) {
      // A DecoratedBox, not a Container: a Container insets its child by the
      // border's width, and the label would move.
      content = DecoratedBox(
        decoration: BoxDecoration(
          color: brand.withValues(alpha: 0.2),
          border: Border.all(color: brand.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: content,
      );
    }
    return Semantics(
      selected: item.selected,
      child: InkWell(
        onTap: () {
          item.onTap();
          _close();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: content,
        ),
      ),
    );
  }

  Widget _buildModeSwitch(DotarMenuModeSwitch modeSwitch) {
    final isDark = modeSwitch.isDark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 24.0),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => RotationTransition(
              turns: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              key: ValueKey(isDark),
              color: isDark ? Colors.amber : Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            modeSwitch.label,
            style: _jakarta(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 28,
            child: Switch(
              value: isDark,
              onChanged: modeSwitch.onChanged,
              activeThumbColor: Colors.amber,
              activeTrackColor: Colors.amber.withValues(alpha: 0.3),
              inactiveThumbColor: Colors.white70,
              inactiveTrackColor: Colors.white24,
            ),
          ),
        ],
      ),
    );
  }
}
