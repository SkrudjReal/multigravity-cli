![Multigravity](assets/multigravity-logo.jpg)

# Multigravity

**Run multiple Antigravity IDE profiles simultaneously — each with its own accounts, extensions, and settings.**

No more logging in and out. Launch as many profiles as you need, all at once.

[![GitHub repository](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/sujitagarwal/multigravity-cli)
[![GitHub profile](https://img.shields.io/badge/GitHub-Profile-lightgrey?logo=github)](https://github.com/sujitagarwal)
[![GitHub stars](https://img.shields.io/github/stars/sujitagarwal/multigravity-cli?style=social)](https://github.com/sujitagarwal/multigravity-cli/stargazers)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey)](#install)

---

## Install

**macOS / Linux**

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/sujitagarwal/multigravity-cli/main/install.sh)"
```

**Windows** — open PowerShell and run:

```powershell
irm https://raw.githubusercontent.com/sujitagarwal/multigravity-cli/main/install.ps1 | iex
```

---

## Windows: independent Antigravity logins (experimental)

**Why two regular profiles may still show the same Google account:** Windows
Antigravity can read OAuth credentials from a *single* Windows Credential Manager
entry named `gemini:antigravity`. Creating separate profile folders does not
isolate that system credential.

Windows profile launches now pass an explicit `--user-data-dir` and
`--extensions-dir` to reduce Electron instance reuse and ensure separate
local IDE state. However, the system keyring can still share a login between
multiple profiles.

For profile-local file-based auth **opt in per launch**:

```powershell
multigravity agy --isolated-auth
multigravity op-agy --isolated-auth
```

Or check **Independent login** before launching from the WPF GUI.
Close all existing Antigravity windows before the first test; then start each
profile and explicitly select a different Google account in the browser.

**Security and compatibility caveats:**

- This sets an `SSH_CONNECTION` marker **only in the launched process**.
  Antigravity currently may treat it as a remote session and use a
  profile-local file-based token store instead of Windows Credential Manager.
  This is undocumented behavior and could stop working after an update.
- Profile-local OAuth token files may have weaker protection than Windows
  Credential Manager. Protect your Windows account and the directories under
  `AntigravityProfiles`; never upload these profiles to a public repository.
- The GUI toggle is session-scoped, not a persistent setting.
- This does not migrate old logins or copy credentials. Log in again in each
  isolated profile. The original global Windows credential is not erased.
- Confirm account identity **inside each Antigravity window**, and again after
  closing and relaunching each profile. If both still show the same login,
  the installed Antigravity build is ignoring the file-token workaround.
  In that case, separate Windows user accounts are the reliable isolation
  boundary. Do not assume the fix worked merely because two windows opened.

Test this branch of the fork without touching `main`:

```powershell
$env:MULTIGRAVITY_REPO = 'SkrudjReal/multigravity-cli'
$env:MULTIGRAVITY_REF = 'fix/windows-independent-auth-profiles'
irm https://raw.githubusercontent.com/SkrudjReal/multigravity-cli/fix/windows-independent-auth-profiles/install.ps1 | iex
multigravity gui
```

Existing profile folders are retained; the installer replaces only the CLI
scripts under `~/.local/bin`. For the first test, back up important data.
Do not run `multigravity update` until this fork branch is merged.

---

## Windows WPF Profile Manager (Glass / Sakura)

This branch combines the charcoal-and-neon glass profile UI with the **same
micro-sakura cursor motion** used in the author's
[‌aura-companion-plus CursorTrail.tsx](https://github.com/SkrudjReal/aura-companion-plus/blob/main/src/components/CursorTrail.tsx).

### Glass interface

- Dark pill-shaped buttons and profile rows with a soft satin reflection.
- Pink **radial gradient occupying the rightmost 25%** of each pill.
- Active profiles show a subtle diffuse pink ambient shadow and a slender
  neon accent at the right edge.
- Button hover adds a diffused magenta halo; high-contrast text stays above
  the glass effect.
- Frosted highlights, rounded charcoal scrollbar, low-opacity moving backdrop.
- **Independent login** remains enabled by default; it relies on an
  undocumented file-backed authentication workaround and should not be
  considered hardened token isolation. Protect profile directories.

### Cursor effects (port from AURA)

The original React trail is in `src/components/CursorTrail.tsx`:
- Spawn a micro-petal every **32ms** while moving.
- **6-12 px** glossy pink sakura petals drift **-15 to +15 px** horizontally
  and **10-30 px** downward.
- Each petal rotates **180 degrees**, scales down to **40%**, and fades over
  **700ms** with ease-out. A faint pink halo surrounds each petal.

The WPF code in `multigravity-effects.cs` ports those specific
parameters, geometry and timing. The additional click effect is a short
circular pink glow surrounded by 10 drifting petals. Background frost/dust
remains subtle. Transient particles are capped at 60 and removed on completion;
both canvases ignore pointer events so they never block buttons. All motion
can be disabled using:

```powershell
$env:MULTIGRAVITY_DISABLE_FX = '1'
multigravity gui
```

### Install development build

Close Multigravity GUI, then in Windows PowerShell 5.1:

```powershell
$env:MULTIGRAVITY_REPO = 'SkrudjReal/multigravity-cli'
$env:MULTIGRAVITY_REF = 'feature/glass-sakura-cursor'
irm https://raw.githubusercontent.com/SkrudjReal/multigravity-cli/feature/glass-sakura-cursor/install.ps1 | iex
multigravity gui
```

The installer updates scripts and the branded launcher in
`~/.local/bin`, **not** the existing profiles in
`~/AntigravityProfiles`.

### Portable single-file EXE release

The new `multigravity-gui-portable-launcher.cs` embeds the CLI,
WPF manager, custom icon, and particle source into **one runnable Windows EXE**.
It extracts its bundled source files to
`%LOCALAPPDATA%\Multigravity\GlassSakuraPortable-v0.1.0`
at startup. Antigravity IDE remains a separate prerequisite; no private
Google OAuth tokens or profile directories are included in the executable.

The Windows build and GitHub prerelease pipeline is defined in
`.github/workflows/release-windows-gui.yml`.
The workflow is configured to publish prerelease tag
`v0.1.0-glass-sakura` with the EXE and ZIP. A release only exists once
GitHub Actions successfully runs and uploads those assets.

If GitHub Actions cannot allocate a Windows runner, build and publish on a
Windows machine with Windows PowerShell 5.1 and authenticated GitHub CLI:

```powershell
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\scripts\Build-PortableGui.ps1
gh auth login
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\scripts\Publish-PortableGuiRelease.ps1
```

The local build output will be `dist/MultigravityProfileManager.exe`
and `dist/Multigravity-Glass-Sakura-Windows.zip`.

### Validate on Windows

```powershell
powershell.exe -NoProfile -STA -File .\tests\Test-WindowsGui.ps1
```

CI / static checks are not a replacement for interactive visual confirmation
of pointer glow and WPF animations on Windows 11.

---

## Quick Start

```bash
# Create profiles
multigravity new work
multigravity new personal

# Launch a profile
multigravity work

# Pass arguments straight through to Antigravity
multigravity work .
multigravity work path/to/project
multigravity work --new-window
```

Each profile gets an automatic clickable launcher:

| Platform | Location |
|----------|----------|
| macOS    | `~/Applications/Multigravity <name>.app` |
| Windows  | Start Menu → Programs |
| Linux    | `~/.local/share/applications/multigravity-<name>.desktop` |

---

## Commands

### Profile Management

| Command | Description |
|---------|-------------|
| `multigravity new <name>` | Create a new full profile |
| `multigravity new <name> --shared` | Create a lightweight profile (shared extensions & settings, isolated accounts) |
| `multigravity new <name> --from <template>` | Create a profile from a saved template |
| `multigravity <name>` | Launch a profile |
| `multigravity list` | List all profiles |
| `multigravity gui` | Open the Windows WPF profile manager |
| `multigravity status` | Show running state, type, last used, and size per profile |
| `multigravity clone <src> <dest>` | Copy an existing profile |
| `multigravity rename <old> <new>` | Rename a profile |
| `multigravity delete <name>` | Delete a profile and all its data |

### Templates

| Command | Description |
|---------|-------------|
| `multigravity template save <profile> <name>` | Save a profile as a reusable template |
| `multigravity template list` | List saved templates |
| `multigravity template delete <name>` | Remove a template |

### Backup & Transfer

| Command | Description |
|---------|-------------|
| `multigravity export <name> [path]` | Archive a profile to `.tar.gz` (`.zip` on Windows) |
| `multigravity import <archive> [name]` | Restore a profile from an archive |

### Utilities

| Command | Description |
|---------|-------------|
| `multigravity stats` | Show disk usage per profile |
| `multigravity doctor` | Diagnose your environment |
| `multigravity update` | Update Multigravity to the latest version |
| `multigravity completion` | Set up shell tab-completion |
| `multigravity help` | Show help |

---

## Shared Profiles

Full profiles are fully isolated — separate extensions, settings, and accounts. That's the default.

**Shared profiles** go lighter: they symlink extensions and settings from your main Antigravity install, isolating only the account/auth layer. Useful when you need a second account but don't want to duplicate gigabytes of extensions.

```bash
multigravity new client-x --shared
```

---

## Templates

Save a configured profile as a template, then spin up new profiles from it instantly:

```bash
# Save your ideal setup as a template
multigravity template save work base

# Create new profiles from it
multigravity new project-a --from base
multigravity new project-b --from base

# See what templates you have
multigravity template list
```

---

## Shell Completion

Enable tab-completion for commands and profile names:

```bash
multigravity completion
```

Follow the instructions to add it to your `.zshrc`, `.bashrc`, or PowerShell `$PROFILE`.

---

## Uninstall

**macOS / Linux**

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/sujitagarwal/multigravity-cli/main/uninstall.sh)"
```

**Windows**

```powershell
irm https://raw.githubusercontent.com/sujitagarwal/multigravity-cli/main/uninstall.ps1 | iex
```

You'll be asked whether to remove your profile data — nothing is deleted without confirmation.

---

## Profile Name Rules

Letters, numbers, and hyphens only. Must start with a letter or number.

```
✅  work   client-a   test1
❌  -name  my_profile
```

---

## Credits

- **Windows support** — [Samin Yeasar](https://github.com/Solez-ai)
- **Linux support** — [Md Rayyan Nawaz](https://github.com/therayyanawaz)
