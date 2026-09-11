---
title: Apple Shortcuts
description: Run shortcuts from your Shortcuts library from the launcher, with optional text input.
---

Each shortcut in your Shortcuts library is its own launcher row: searchable, bindable to a global
shortcut, and able to take optional text when you run it.

**Settings → Apple Shortcuts** holds the feature switch. It ships **off**.

| Setting            | Default |
| ------------------ | ------- |
| Enable Apple Shortcuts | Off |
| Show in launcher   | On      |

While the feature is off there is no section and nothing runs — but **bindings stay registered**, so
re-enabling restores every shortcut you had.

## Running a shortcut

Select a row and press <kbd>↵</kbd>. An optional **Text** field sits in the header: leave it empty to
run with no input, or type or paste something (a URL for an Open URL shortcut, for example).

Non-empty output from the shortcut appears briefly in a HUD. Failures report the same way.

## Hide and hotkeys

In **Settings → Apple Shortcuts** each row has a checkbox to hide it from the launcher and a
recorder for a global shortcut. Favorites and usage ranking work like other launcher kinds.
Identity follows the Shortcuts app's own identifier, so renaming a shortcut in Shortcuts.app does
not break a binding.
