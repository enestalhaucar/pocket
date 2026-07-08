# pocket 📥

A tiny macOS menu bar vault. Keep the things you reach for — addresses, IBANs, API
keys, snippets, small files — one click from the menu bar, and lock the sensitive
ones behind **Touch ID**.

Built for the "I'm out somewhere and just need to paste that one thing" moments.
Native SwiftUI, minimal, open source.

## Features

- **Menu bar first** — lives in your menu bar, no dock icon, no window clutter.
- **Global hotkey** — summon pocket from anywhere with **⌘⇧Space**, even fullscreen.
- **Keyboard driven** — search is focused on open; arrow keys move the selection,
  Enter copies and closes. No mouse needed.
- **Click to copy** — tap any item and it's on your clipboard. A ✓ confirms it.
- **Kasa (vault)** — mark items as locked; a single Touch ID unlocks the whole vault
  for the session. It **auto-locks** after inactivity or when the Mac sleeps.
- **Text, secrets & files** — store snippets, sensitive strings, or small files.
- **Clipboard history** — auto-captures what you copy (skips password-manager
  secrets) and lets you promote any capture into a saved item.
- **Quick-add** — one click saves whatever is on the clipboard right now.
- **Pin & reorder** — pin the things you reach for; drag to reorder.
- **Encrypted at rest** — everything is stored AES-GCM encrypted in pocket's own
  file. Only a single master key lives in the keychain, so your secrets are **not**
  duplicated across Keychain Access.
- **Search** — filter across everything instantly.
- **Launch at login** — optional, toggled from Settings.

## Security model

- On first launch pocket generates a 256-bit master key and stores it as a single
  generic-password item in your login keychain.
- All items (locked or not) are serialized to JSON and written **AES-GCM encrypted**
  to `~/Library/Application Support/pocket/store.dat`.
- Opening the vault or revealing a locked item requires
  `LAPolicy.deviceOwnerAuthentication` → Touch ID, with automatic password fallback.
- pocket never sends anything anywhere. No network code, no telemetry.

## Install (download)

Grab the latest `pocket-x.y.z.dmg` from the
[Releases page](https://github.com/enestalhaucar/pocket/releases), open it, and
drag **pocket** into Applications.

pocket is ad-hoc signed (no paid Apple Developer account), so the first time you
open it macOS may say it's from an unidentified developer. Either:

- Right-click the app → **Open** → **Open**, or
- Run once: `xattr -cr /Applications/pocket.app`

To have it start with your Mac: open pocket → ⚙️ Settings → **Girişte otomatik başlat**.

## Package a shareable build

```bash
./package.sh          # builds dist/pocket-<version>.dmg
```

## Build & run

Requires macOS 14+ and a recent Swift toolchain (ships with Xcode).

```bash
git clone https://github.com/enestalhaucar/pocket.git
cd pocket
./build.sh                 # compiles + assembles build/pocket.app (ad-hoc signed)
open build/pocket.app      # launches it into the menu bar
```

To install it permanently:

```bash
cp -R build/pocket.app /Applications/
```

To have it start at login: System Settings → General → Login Items → add pocket.

## Development

```bash
swift build      # debug build
swift run        # run straight from the terminal
```

Project layout:

```
Sources/pocket/
  App/        PocketApp.swift        # @main, MenuBarExtra scene
  Models/     Item.swift             # the data model
  Security/   Keychain, Crypto,      # master key + AES-GCM + Touch ID
              Biometrics
  Store/      Store.swift            # source of truth + persistence
              Clipboard.swift        # copy to pasteboard
  Views/      RootView, ItemRowView, # the UI
              EditItemView
```

## License

MIT © Enes Talha Ucar
