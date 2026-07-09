# My Dotfiles

These are my personal configuration files for my development environment, meticulously managed using `make` for consistency and ease of setup across different machines.

## Features

*   **Automated Setup:** Quickly set up a consistent development environment on new machines with a single command.
*   **Modular Organization:** Configuration files are logically grouped, making it easy to find and manage settings for various applications.
*   **Version Controlled:** All configurations are tracked with Git, allowing for easy rollback, history tracking, and synchronization.
*   **Language Tool Management:** Includes commands to update and manage language-specific tools (Go, Node.js, Python, Rust).
*   **Custom Scripts:** A dedicated directory for personal scripts and binaries to extend functionality.

## Prerequisites

Before you begin, ensure you have the following installed:

*   `make`: Essential for running the installation and management commands.
*   `git`: Required for cloning the repository and its external dependencies under `_modules/`.
*   **SSH access to GitHub**: `_modules/` dependencies (e.g. `fzf`, `nvm`, `pyenv`, `goenv`) are cloned via `git@github.com:...`, so your SSH key must already be registered with GitHub.
*   `curl` and `jq`: Used to resolve and download the latest release assets for versioned tools (e.g. tmux, zellij, aws-vault). `jq` in particular is required just to parse the GitHub API responses.
*   A C compiler and standard build tools (e.g., `build-essential` on Debian/Ubuntu): Necessary for compiling various tools and dependencies.
*   tmux build dependencies (tmux is built from source via `autoreconf` + `./configure --enable-utf8proc`): on Debian/Ubuntu, `autoconf automake pkg-config libevent-dev libutf8proc-dev bison`; on macOS, `autoconf automake pkg-config libevent utf8proc`.

## Installation

1.  **Backup Existing Dotfiles (Recommended):**
    If you have existing dotfiles, it's highly recommended to back them up before proceeding to avoid conflicts.

2.  **Clone the repository:**

    ```bash
    git clone git@github.com:yowcow/dotfiles.git ~/dotfiles
    cd ~/dotfiles
    ```

3.  **Install the dotfiles:**

    This command will create symbolic links from your home directory to the corresponding configuration files within this repository, integrating them into your system.

    ```bash
    make install
    ```

## Usage

### Updating

The `Makefile` includes a powerful `update` command designed to keep your environment current:

*   Pulls the latest changes for all external dependencies under `_modules/` (e.g., `fzf`, `nvm`).
*   Updates language-specific tools and package managers for Go, Node.js, Python, and Rust, ensuring you have the latest versions of your development tools.

To run the update:

```bash
make update
```

Versioned tools (e.g. tmux, zellij, aws-vault) are **not** refreshed by `make update` — because refreshing them rebuilds tmux from source, which is slow enough that it's left as an explicit, opt-in step:

```bash
make update/versioned
```

### Cleaning

*   **`make clean`**: This command removes the files created by `make install` from your home directory, including symbolic links and any generated AI instruction files, effectively deactivating the dotfiles.
*   **`make realclean`**: Performs everything `make clean` does, and additionally removes the `_modules` directory, which contains the cloned external dependencies.

## Structure

*   `config/`: Houses configuration files for a wide array of applications, including terminal emulators (`alacritty`, `wezterm`), text editors (`nvim`), window managers (`sway`), and more.
*   `ai/`: Shared AI assistant guidelines (`GUIDELINES.md`), shared skills, and custom agent definitions. On install, the shared guideline is applied to Claude, Gemini, and Codex; targets symlink to the shared file by default, and can be generated with an agent-specific overlay when needed.
*   `local/bin/`: A dedicated location for your custom shell scripts and personal binaries, which are typically added to your system's PATH.
*   `_modules/`: Contains third-party tools and plugins cloned via SSH by the Makefile (not Git submodules — there is no `.gitmodules`), such as `fzf` (a command-line fuzzy finder) and `nvm` (Node Version Manager).
*   `Makefile`: The central script that orchestrates the entire dotfile management process, handling installation, updates, and cleanup operations.
