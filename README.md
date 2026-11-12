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

## Windows WPF Profile Manager (Astral theme)

This fork includes a WPF profile manager with an original purple-and-gold
space-opera interface. It draws on the visual *language* of Honkai: Star Rail:
deep amethyst surfaces, gold accents, gently animated controls and a subtle
celestial glow. No HoYoverse artwork or assets are included.

- Shows existing full/shared Antigravity profiles; no account migration.
- Create, launch, rename, and remove profiles using the existing CLI.
- **Independent login** is an opt-in mode with documented credential-storage
  caveats (see the section above). Its implementation is still undocumented.
- Responsive panels stack in narrow windows, while scrolling keeps controls
  reachable at small heights.
- Buttons and checkboxes have custom muted WPF templates, including disabled
  states; there are no white Windows-themed default buttons.
- A gentle header entrance, star pulse and fast hover transitions enhance
  feedback without distracting from work.

### Branded taskbar icon

The installer downloads a custom PNG, writes a Windows ICO and tries to build
`MultigravityProfileManager.exe` using the .NET Framework C# compiler
included with Windows. The tiny launcher runs the PowerShell WPF interface in
its own process with a native executable icon. The Start Menu shortcut and
`multigravity gui` prefer this executable when present.

If the compiler is unavailable, the installer falls back to launching the
PowerShell script; the script sets a dedicated AppUserModelID and a window icon.
**An already-pinned PowerShell shortcut may need to be unpinned and replaced
with the new Multigravity Profile Manager shortcut.**

### Install this development branch

From a fresh Windows PowerShell 5.1 terminal:

```powershell
$env:MULTIGRAVITY_REPO = 'SkrudjReal/multigravity-cli'
$env:MULTIGRAVITY_REF = 'feature/astral-purple-wpf'
irm https://raw.githubusercontent.com/SkrudjReal/multigravity-cli/feature/astral-purple-wpf/install.ps1 | iex
multigravity gui
```

Existing profile folders are not overwritten by the installer.
`install.ps1` is BOM-free to work when piped into `iex`; the
installed PowerShell scripts retain a UTF-8 BOM for PowerShell 5.1.

### Validate on Windows

```powershell
powershell.exe -NoProfile -File .\tests\Test-WindowsGui.ps1
```

A GitHub Actions Windows runner also performs PowerShell syntax and WPF XAML
loading checks for this branch. Interactive resize, animation and two-account
tests still need a local Windows verification.

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
