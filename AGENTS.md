# AGENTS.md

## Build Entrypoint
- `./build-termux.sh` is the primary CLI; default run deletes modified files, use `-d`/`--dirty` to preserve artifacts between iterations

## Variants & Patches
- Two build types: `f-droid` (default), `play-store` (set via `--type`)
- Type-specific patches live in `f-droid-patches/`, `play-store-patches/` with `app-patches/`/`bootstrap-patches/` subdirs
- Plugins follow identical patch structure in `plugins/`, applied via `--plugin <name>`

## Critical Flags & Gotchas
- `--enable-ssh-server` only works with `f-droid` type, requires bootstrap second stage
- `--disable-bootstrap-second-stage` only affects `f-droid` builds
- Avoid package names that are `com.termux` substrings or contain `_`/`-` (causes replacement side effects)
- Default preinstalled package: `xkeyboard-config` (for termux-x11-nightly)

## CI Notes
- Workflow: `.github/workflows/build-termux.yml` (runs on `ubuntu-24.04`, JDK 21)
- Mandatory: Fixes all `.sh` line endings with `dos2unix` to prevent Windows clone issues
- Cancels duplicate runs for the same ref; uploads APKs, zips, and build logs as artifacts

## Local Prerequisites
- Docker, Android SDK (`ANDROID_SDK_ROOT` set), OpenJDK 21, `git`, `patch`, `bash`
- Package builds use `ghcr.io/termux/package-builder` Docker container

## References
- Usage: `README.md`, `plugins/README.md`
- Extended instructions: `GEMINI.md`
