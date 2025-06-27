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
*   `git`: Required for cloning the repository and managing submodules.
*   `curl`: Used by some installation scripts for downloading tools.
*   A C compiler and standard build tools (e.g., `build-essential` on Debian/Ubuntu): Necessary for compiling various tools and dependencies.
*   `rebar3` (for Erlang Language Server): Specifically required if you use Erlang and its language server.

## Installation

1.  **Backup Existing Dotfiles (Recommended):**
    If you have existing dotfiles, it's highly recommended to back them up before proceeding to avoid conflicts.

2.  **Clone the repository:**

    ```bash
    git clone --recurse-submodules https://github.com/your-username/dotfiles.git ~/.dotfiles
    cd ~/.dotfiles
    ```

3.  **Install the dotfiles:**

    This command will create symbolic links from your home directory to the corresponding configuration files within this repository, integrating them into your system.

    ```bash
    make install
    ```

## Usage

### Updating

The `Makefile` includes a powerful `update` command designed to keep your environment current:

*   Pulls the latest changes for all git submodules (e.g., `fzf`, `nvm`).
*   Updates language-specific tools and package managers for Go, Node.js, Python, and Rust, ensuring you have the latest versions of your development tools.

To run the update:

```bash
make update
```

### Cleaning

*   **`make clean`**: This command removes the symbolic links created by `make install` from your home directory, effectively deactivating the dotfiles.
*   **`make realclean`**: Performs everything `make clean` does, and additionally removes the `_modules` directory, which contains the cloned git submodules.

## Structure

*   `config/`: Houses configuration files for a wide array of applications, including terminal emulators (`alacritty`), text editors (`nvim`), window managers (`sway`), and more.
*   `local/bin/`: A dedicated location for your custom shell scripts and personal binaries, which are typically added to your system's PATH.
*   `_modules/`: Contains Git submodules for third-party tools and plugins, such as `fzf` (a command-line fuzzy finder) and `nvm` (Node Version Manager).
*   `Makefile`: The central script that orchestrates the entire dotfile management process, handling installation, updates, and cleanup operations.