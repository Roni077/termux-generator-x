# Termux Generator

`termux-generator` is a utility designed to build custom versions of the [Termux](https://github.com/termux/termux-app) Android application and its associated ecosystem. Its primary purpose is to enable users to change the base package name (from the default `com.termux`) and pre-configure the environment with specific packages and settings.

## Project Overview

-   **Core Functionality:** Automates cloning, patching, and building Termux and its addons (API, Boot, Float, Styling, Tasker, Widget, GUI, X11).
-   **Customization:** Supports custom package names, pre-installed packages in the bootstrap, and enabling an SSH server by default.
-   **Variants:** Supports both `f-droid` and `play-store` styles of Termux.
-   **Architecture:**
    -   **Orchestration:** Bash scripts (`build-termux.sh`, `scripts/*.sh`) manage the build lifecycle.
    -   **Patching:** A robust patching system (`f-droid-patches/`, `play-store-patches/`) modifies upstream source code.
    -   **Environment:** Uses Docker (`ghcr.io/termux/package-builder`) to ensure a consistent build environment for Termux packages.
    -   **CI/CD:** GitHub Actions workflow (`.github/workflows/build-termux.yml`) for automated builds.

## Building and Running

### Prerequisites

-   **Operating System:** Linux (Ubuntu 24.04 recommended) or macOS.
-   **Dependencies:** Docker, Android SDK, OpenJDK 21, `git`, `patch`, `bash`.
-   **Android SDK Setup:** Ensure `ANDROID_SDK_ROOT` is set and licenses are accepted.

### Build Commands

The main entry point is `build-termux.sh`.

```bash
# Basic usage
./build-termux.sh --name your.custom.package.name

# Advanced usage with pre-installed packages and specific architectures
./build-termux.sh --name com.my.termux \
                  --add clang,make,git,python \
                  --architectures aarch64,x86_64 \
                  --enable-ssh-server
```

### Key Options

-   `-n, --name`: The custom package name (e.g., `com.my.termux`).
-   `-a, --add`: Comma-separated list of additional packages to include in the bootstrap.
-   `-t, --type`: App variant, either `f-droid` (default) or `play-store`.
-   `--architectures`: Comma-separated list of architectures (e.g., `aarch64,arm,i686,x86_64`).
-   `--enable-ssh-server`: Bundles OpenSSH and sets a default password (`changeme`).
-   `-p, --plugin`: Applies a plugin from the `plugins/` directory.

## Development Conventions

### Scripting Standards

-   Scripts use `#!/bin/bash` and should include `set -e -u -o pipefail` for robustness.
-   Utility functions are centralized in `scripts/termux_generator_utils.sh`.
-   Build steps are defined in `scripts/termux_generator_steps.sh`.

### Patching Workflow

1.  **Upstream Source:** The `download` step clones fresh copies of upstream repositories into `termux-packages-main` and `termux-apps-main`.
2.  **Name Replacement:** The `replace_termux_name` function performs a global find-and-replace for `com.termux` and handles folder migration for the Java/Kotlin source tree.
3.  **Applying Patches:** Custom patches are applied using the `patch` command. Patches should be generated against the upstream state and placed in the appropriate `*-patches/` directory.

### Project Structure

-   `build-termux.sh`: Main CLI entry point.
-   `f-droid-patches/`, `play-store-patches/`: Patches specific to each Termux variant.
-   `plugins/`: Optional extensions that follow the same patching structure.
-   `scripts/`: Internal helper scripts for the build process.
-   `.github/workflows/`: CI configuration for GitHub Actions.

## Troubleshooting

-   **Docker Issues:** Ensure the current user is in the `docker` group. Use `./build-termux.sh` to trigger a clean build if container states become inconsistent.
## Build process optimizations

-   **Parallel App Building:** For `f-droid` builds, independent addon apps are built in parallel, significantly reducing the total build time. Logs for these parallel builds are stored in `termux-apps-main/<app-name>/build-<app-name>.log`.
-   **Gradle Performance Flags:** All Gradle builds utilize `--parallel`, `--build-cache`, `--configure-on-demand`, and `--daemon` for optimal performance.
-   **Selective Downloading:** The build script only clones the repositories for apps that are not disabled, saving bandwidth and disk space.
-   **Dirty Builds:** Use the `-d` or `--dirty` flag to skip cleaning and speed up iterations during development.
-   **Package Name Conflicts:** Avoid names that are substrings of `com.termux` or contain invalid characters (underscores, dashes) to prevent replacement side effects.
