# Changelog

## 0.2.2

- An app's SnackBars sit above its own bottom bar again: the shell paints its background with a `Material` instead of a `Scaffold`, so the app's `Scaffold` is the one the `ScaffoldMessenger` shows them on. A screen inside the shell needs its own `Scaffold` to show SnackBars or to call `Scaffold.of`.
- Screen readers hear the open menu when the app has its own `Navigator`: the app sits in a semantics container, so its routes' barriers no longer drop the menu's semantics.
- Reported and fixed by InvoiceLens. No API change.

## 0.2.1

- An item's label, the logout's and the mode switch's no longer overflow the 240 px column: one longer than the column holds goes on to a second line and reads whole. Labels that fit look as in 0.2.0. No API change.

## 0.2.0

- `DotarMenuItem.selected`: the current screen's entry sits on a `brandColor`-tinted background and is announced as selected, without moving its icon or label. Works in `items` and `bottomItems`.
- `DotarMenuSection(title, items)`: groups items under a title, among loose items. A section with every item hidden is left out, title included.
- `items` and `bottomItems` now take `List<DotarMenuEntry>` (`DotarMenuItem` or `DotarMenuSection`); code passing a list of items compiles and looks as in 0.1.0.

## 0.1.0

- `DotarMenuShell`, `DotarMenu` and `DotarMenuController`: DEAM-Resto's animated side menu as a package, with Plus Jakarta Sans bundled.
