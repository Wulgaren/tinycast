# iCloud Tabs

Search open Safari tabs synced from your other Apple devices. First-party Swift reads Safari’s local
`CloudTabs.db` cache; there is no Raycast extension and no JavaScript runtime involved.

## Invariants

- **iCloud tabs only.** Local Safari windows, History, Bookmarks and Reading List are out of scope.
- **`Model/` stays Foundation-only.** `icloud-tabs-test` compiles it standalone.
- **Off by default.** `iCloudTabsEnabled` gates the launcher command and its hotkey; an import must
  not turn it on (`SettingsBackupCoverage.deliberatelyExcluded`).
- **Full Disk Access is a fallback, not the first gate.** The screen tries to open Safari’s
  `CloudTabs.db` read-only. If that works, tabs load — even when the classic TCC.db FDA probe fails.
  Only an unreadable database surfaces the Full Disk Access empty state (`FullDiskAccess` / System
  Settings). The FDA button uses the current Privacy & Security deep link.
- **Returning from System Settings re-probes.** Becoming active while the screen is waiting on access
  runs `refresh()` again, so a grant does not require leaving and re-entering the command.
- **Safari wake is background-only.** When Safari is not running, Tinycast launches it with
  `activates = false` and `hides = true` (same idea as `open -jg`), waits ~1.5s for CloudKit to
  settle, reads the DB, then quits Safari only if Tinycast started it. A Safari that was already
  running is never quit.
- **This Mac’s CloudTabs device stays in the list** when it has tabs. Empty devices never appear.

## Surfaces

| Surface | Role |
| --- | --- |
| Settings → iCloud Tabs | Enable toggle, command visibility / shortcut, Full Disk Access button |
| Launcher command `iCloud Tabs` | Opens the palette screen |
| Palette mode `.iCloudTabs` | Device-grouped search; ↵ opens the URL in the default browser; ⌘↵ copies the URL |

## Data path

1. `ICloudTabsCoordinator.show()` opens `.iCloudTabs` and calls `ICloudTabsSession.refresh()`.
2. Access policy (`ICloudTabsPolicy.access`) checks FDA and that `CloudTabs.db` exists under Safari’s
   container.
3. Optional background Safari launch via `SafariCloudSync`.
4. `CloudTabsReader` opens the DB read-only and joins `cloud_tabs` to `cloud_tab_devices`.
5. `ICloudTabsPolicy.devices` groups rows; the screen filters by title, URL and device name.

## Manual check

- Enable in Settings, grant Full Disk Access, run **iCloud Tabs**.
- With Safari quit: the screen shows “Refreshing…”, Safari may appear briefly in the background,
  then device sections fill in and Safari quits again.
- With Safari already open: tabs appear without quitting Safari afterward.
- ↵ opens in the default browser; ⌘↵ copies the URL; ⌘K offers both.
