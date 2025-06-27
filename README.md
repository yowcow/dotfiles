# My Dotfiles

These are my personal configuration files for my development environment. They are managed using `make`.

## Prerequisites

Before you begin, ensure you have the following installed:

*   `make`
*   `git`
*   `curl`
*   A C compiler and standard build tools (e.g., `build-essential` on Debian/Ubuntu)
*   `rebar3` (for Erlang Language Server)

## Installation

1.  **Clone the repository:**

    ```bash
    git clone --recurse-submodules https://github.com/your-username/dotfiles.git ~/.dotfiles
    cd ~/.dotfiles
    ```

2.  **Install the dotfiles:**

    This will create symlinks from your home directory to the files in this repository.

    ```bash
    make install
    ```

## Usage

### Updating

The `Makefile` includes a powerful update command that does the following:

*   Pulls the latest changes for all git submodules.
*   Updates language-specific tools for Go, Node.js, Python, and Rust.

To run the update:

```bash
make update
```

### Cleaning

*   **`make clean`**: Removes the symlinks from your home directory.
*   **`make realclean`**: Does everything `make clean` does, but also removes the `_modules` directory.

## Structure

*   `config/`: Contains configuration for various applications like `alacritty`, `nvim`, `sway`, etc.
*   `local/bin/`: For custom scripts and binaries.
*   `_modules/`: Git submodules for third-party tools like `fzf` and `nvm`.
*   `Makefile`: The main script for managing the dotfiles. All the magic happens here.