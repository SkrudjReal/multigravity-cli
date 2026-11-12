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

## Windows WPF Profile Manager (Frost / Neon)

This branch adds a graphite-and-magenta Windows profile manager with a soft
moving backdrop, airborne frosted dust, glowing click sparkles and a short
cursor glitter trail. It is built on native WPF, not Electron or a browser.

- **Independent login** is checked by default. This still uses an undocumented
  file-backed credential workaround; profile token files must stay private.
  Untick the option to use the Windows Credential Manager path.
- Modern **Segoe UI Variable Text** typography with ClearType rendering.
- Dark charcoal panels, soft neon-pink accents on selection and hover,
  hand-tuned dark/disabled buttons, and a subtle frost highlight at button edges.
- Custom thin rounded scrollbar that turns pink when hovered/dragged.
- Gentle header fade/slide and selected-profile fade, plus low-amplitude
  glowing background movement.
- 23 slow snow/dust particles behind content, a 34 ms cursor-trail throttle,
  and small click bursts. Transient particles are capped at **55**.
  The canvas cannot intercept clicks; the particle engine releases all elements
  when the window closes.

The animation implementation lives in `multigravity-effects.cs` and is
compiled locally by Windows PowerShell's built-in .NET Framework compiler.
If compilation fails, the profile manager still opens without particle effects.
For a low-motion / low-power session, set `MULTIGRAVITY_DISABLE_FX=1`
before running `multigravity gui`; profile management remains unchanged.

### Install this experimental branch

Open a new Windows PowerShell 5.1 window:

```powershell
$env:MULTIGRAVITY_REPO = 'SkrudjReal/multigravity-cli'
$env:MULTIGRAVITY_REF = 'feature/frosted-neon-effects'
irm https://raw.githubusercontent.com/SkrudjReal/multigravity-cli/feature/frosted-neon-effects/install.ps1 | iex
multigravity gui
```

The installer preserves existing profile directories including `agy` and
`op-agy`. It also updates the custom-icon GUI launcher and the
**Multigravity Profile Manager** Start Menu shortcut. Unpin any stale
PowerShell shortcut and pin the branded launcher if necessary.

### Windows checks

```powershell
powershell.exe -NoProfile -STA -File .\tests\Test-WindowsGui.ps1
```

The tests inspect WPF XAML, verify the default-login state, compile and attach
the particle engine, and validate the upper bound on transient particles.
Animation smoothness, brightness, resize behavior, and separate-account login
still need a manual interactive check on Windows.

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
