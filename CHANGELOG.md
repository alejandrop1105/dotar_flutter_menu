# Changelog

## 0.2.0

- `DotarMenuItem.selected`: the current screen's entry sits on a `brandColor`-tinted background and is announced as selected, without moving its icon or label. Works in `items` and `bottomItems`.
- `DotarMenuSection(title, items)`: groups items under a title, among loose items. A section with every item hidden is left out, title included.
- `items` and `bottomItems` now take `List<DotarMenuEntry>` (`DotarMenuItem` or `DotarMenuSection`); code passing a list of items compiles and looks as in 0.1.0.

## 0.1.0

- `DotarMenuShell`, `DotarMenu` and `DotarMenuController`: DEAM-Resto's animated side menu as a package, with Plus Jakarta Sans bundled.
