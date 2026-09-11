# Apple Shortcuts

Each shortcut in the Mac's Shortcuts library is a searchable launcher row: optional text input in
the header, a global hotkey, favorites, usage ranking, and per-row hide. The feature ships **off**.

## Invariants

- **Off is fully off.** `appleShortcutsEnabled` gates the library watcher, the launcher slice, and
  `AppleShortcutCoordinator.runShortcut` — the single funnel palette activation and global shortcuts
  both reach. Bindings stay registered, so re-enabling restores every chord without re-registering.
- **Identity is the Shortcuts identifier**, from `shortcuts list --show-identifiers`. The live
  **name** is what the row shows; hide, hotkeys, favorites and ranking key on
  `apple-shortcut:<identifier>`. Renaming a shortcut in Shortcuts.app does not break those.
- **Folders are ignored.** The list is flat; every shortcut is one row.
- **One shared icon.** Every row draws Shortcuts.app's icon — never a per-shortcut glyph.
- **`Model/` stays Foundation-only.** Parsing, entry ids and the run argv/stdin shape live there so
  `apple-shortcut-test` compiles the shipped sources. Process IO lives in `Service/`.
- **Optional text is never required.** The header chip is always present when a shortcut row is
  selected; empty means run with no stdin. Non-empty text is piped with `--input-path -`.

## Listing

`AppleShortcutStore` runs `/usr/bin/shortcuts list --show-identifiers` off-main, parses lines shaped
`Name (UUID)`, and sorts by name. It reloads when the feature turns on, when the palette opens, and
when `~/Library/Shortcuts` changes (a cheap directory watch, the same shape snippets use).

`applyEnabled` is the presence funnel: off stops the watcher and clears the `AppIndex` slice; on
starts the store and publishes when `appleShortcutsShowInLauncher` is also on. Settings still lists
shortcuts from the store while the launcher companion is off, so hotkeys and hide toggles keep
working.

## Running

`AppleShortcutRunner` builds argv through `AppleShortcutRunInvocation` and runs
`/usr/bin/shortcuts run <identifier>`. With non-empty input it adds `--input-path -` and writes the
text on stdin. Non-empty stdout becomes a short success HUD (first line, capped); empty stdout is
silent success. Failures report through the existing message HUD.

## Settings

**Settings → Apple Shortcuts** carries the master switch, the launcher companion, and a searchable
list with alias, shortcut recorder, and show-in-launcher checkbox per row — VisibilityStore and
`HotKeyAction.appleShortcut(id:)` on the Shortcuts identifier.

## Standalone harness

```sh
./Scripts/run-tests.sh apple-shortcut-test
```
