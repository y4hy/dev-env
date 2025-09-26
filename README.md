# dev-env

A personal development environment bootstrap and dotfiles repository.

This project helps set up a consistent developer workstation by installing tools, configuring editors and shells, and applying GPU-related settings when needed. It also includes personal configuration files (dotfiles), likely including Neovim configuration written in Lua.

## Quick start

Clone the repository and run the installer:

```bash
git clone https://github.com/y4hy/dev-env.git
cd dev-env
chmod +x installer.sh
./installer.sh
```

Tip: Review `installer.sh` before running to understand exactly what it does on your system.

## What’s included

- installer.sh
  - Main bootstrap script to install packages, set up configurations, and apply system tweaks.
- dotfiles/
  - Personal configuration files (e.g., shell, editor, terminal). Given the repository language profile, Neovim/Lua configs are likely included here.
- keyring/
  - Keyring or repository keys required for certain package managers or external repositories.
- nvidia/
  - NVIDIA-specific configuration or helper scripts for systems with NVIDIA GPUs.

## Requirements

- A POSIX-compatible shell (bash/sh)
- git
- sudo privileges (for system-level installs)
- Linux or WSL environment (other platforms may work but are untested)

## Usage notes

- Run the installer from the repository root so relative paths resolve correctly.
- The script may ask for your password to install packages or modify system configuration.
- If you maintain custom preferences, consider forking the repo or keeping a local branch for your changes.

## Structure

```
.
├─ installer.sh
├─ dotfiles/
├─ keyring/
└─ nvidia/
```

## Customization

- Edit files in `dotfiles/` to change shell/editor settings.
- Adjust `installer.sh` steps (e.g., package lists, feature flags) to match your platform and preferences.
- Add or remove directories for additional components as needed.

## Troubleshooting

- Ensure you have network access and correct package repositories enabled.
- If a step fails, re-running `./installer.sh` after fixing the issue is often sufficient.
- For GPU-related issues, review the files under `nvidia/` and your driver versions.

## License

No license file is currently provided. If you intend to reuse or distribute this code, please add a license to clarify permitted use.
