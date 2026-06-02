# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

This is a personal **home-directory / dotfiles repository** (referred to internally as `$NFS` / `$NFSPATH`). It is checked out and used to bootstrap a fresh machine's home directory: shell config (`.bashrc.my`, `.zshrc.my`), Powerlevel10k prompt (`.p10k.zsh`), tmux (`.tmux.conf*`), SpaceVim (`.SpaceVim.d/`), GDB (`.gdbinit*`), plus a large library of personal shell utilities under `common/sh/`.

There is no build system, no test suite, and no package manager. "Developing" here means editing shell scripts and dotfiles. Most committed files are dotfiles that get symlinked into `$HOME`, or standalone scripts run from `$PATH`.

## How the pieces wire together

- **`.bashrc.my`** is the entry point. A real `~/.bashrc` is expected to `source` it. It:
  - Resolves `$NFSPATH`/`$NFS` by probing a long list of candidate paths (NFS mounts, `$HOME`, `$PWD`), falling back gracefully. This is the repo root at runtime.
  - Prepends `common/sh` and `common/py` to `$PATH`, and `common/$OS/bin` (where `$OS` is `uname -s`, or `win` for Cygwin) for vendored binaries.
  - Exports the shortcuts `$SH=$NFS/common/sh`, `$PY=$NFS/common/py`, `$WINSH=$NFS/common/winsh`.
  - Has large per-host (`case $(uname -n)`) and per-OS (`Linux`/`SunOS`/`AIX`) blocks. When changing host/OS-specific behavior, edit the matching `case` arm rather than the global section.
- **`MYSELFID`** (defaults to `zhaoyong.zzy`) is the canonical user id woven through paths and host configs. Many older scripts also hardcode `zhaoyong.zzy` / `zhaozhan` — be aware both appear.
- Scripts are invoked by bare name (e.g. `mylink.sh`, `mykilltree.sh`) because `common/sh` is on `$PATH`. They call each other this way too — don't assume relative-path invocation.

## The `mycommon.sh` shell framework

`common/sh/mycommon.sh` is a sourced bash framework that the more structured scripts build on (`myk8s.sh`, `myawk.sh`, `mysshforward.sh`, `mytest.sh`, `showfullpath.sh`). `common/sh/mytemplate.sh` is the standalone copy-paste starting point for a new script. When writing or editing a framework-style script, follow these conventions:

- Source it with the directory-relative idiom: `source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/mycommon.sh"`.
- Define `typeset -a g_mandatory_utilities=(...)` — `main` checks each is on `$PATH` before running.
- Implement `my_entry` (your logic) and optionally `my_show_usage`; the framework's `main` parses common flags and dispatches to `my_entry`.
- Standard flags handled by the framework `main`: `-d` (DBG logging via `MYDBG=DEBUG`), `-D` (`set -vx` shell trace), `-F` (verbose framework/alias debug), `-h` (usage).
- Logging helpers: `DBG` / `LOG` / `ERR` / `WARN` / `MSG` (timestamped, with source file + function + line). `DBG` only prints when `MYDBG=DEBUG`.
- Error handling is done via heredoc-fed aliases — pipe a message into them on the line *after* the command whose `$?` you want to check:
  - `BCS_CHK_RC0 <<<"msg"` — return non-zero with error if last command failed.
  - `BCS_CHK_ACT_RC0 <<<"msg &&& err_action ||| ok_action !!! both_action"` — conditional actions on failure/success.
  - `BCS_RUN_AND_CHK <<<"cmd @@@ extra"`, `BCS_ASSERT <<<"cond @@@ msg"`, `BCS_WARN_RC0`.
  - The `&&&` / `|||` / `!!!` / `@@@` tokens are the delimiters these aliases parse; preserve them exactly.
- `mycommon.sh` sets `set -o posix`, `pipefail`, `nounset` (`set -u`) and several `shopt`s, and installs `INT`/`EXIT` traps that use `mykilltree.sh` to reap child process trees via a `$PIDFILE`. Scripts assume `nounset`, so reference possibly-unset vars as `${VAR:-}`.

Note: `mytemplate.sh` carries an older, simpler inline copy of these helpers (no `nounset`, fewer aliases). The authoritative versions live in `mycommon.sh`.

## Directory map

- `common/sh/` — the bulk of the repo: personal bash/ksh utilities. Naming: `my*.sh` = personal tools (process mgmt, ssh/scp, git wrappers, k8s, vim/tmux launchers, markdown sharing, etc.); `install_*.sh` = installers for tooling (vim8, tmux, golang, docker, bazel, oh-my-zsh…); a few non-`.sh` helpers (`date2.pl`, the `vim` shell shim).
- `common/py/` — Python 3 helpers (`myapp.py` is a small argparse/logging framework analogous to `mycommon.sh`; plus `k8s.py`, `ps.py`, `mygentags.py`, `mydockerns.py`).
- `common/winsh/` — Windows/Cygwin scripts, heavy on `adb*` (Android) and wifi/network utilities.
- `common/Linux/`, `common/win/` — vendored prebuilt binaries (`bin/`) and libs added to `$PATH`/`$LD_LIBRARY_PATH` per-OS at runtime; `common/Linux/mybox/` holds static dropbear/busybox.
- `common/k/` — Kubernetes scratch (`gen.sh`).
- `.SpaceVim.d/` — SpaceVim config (`init.toml`) and a local patch.

## Bootstrapping a machine

- `common/sh/mylink.sh` — manage dotfile symlinks and (with `-s`/`-v`/`-m`) share/preview markdown files to a remote `$MYVM` via `scp` + a `bashttpd` markdown viewer, registering them in `~/docs/md_index.md`. Flags: `-v` view, `-s` send, `-f` force overwrite, `-m <machine>` source machine, `-i <index>` which index file.
- `common/sh/myhomelink.sh` / `common/sh/myinit.sh` — create soft links for core dotfiles (`.bashrc`, `.tmux`, `.vim`, …) and reset/clean the environment.
- `common/sh/install_*.sh` — run individually to install a given tool.

## Conventions to respect

- **Target shell is bash** (some scripts are ksh, e.g. `myinit.sh`). `mycommon.sh` hard-exits if `$BASH_VERSION` is unset. Keep POSIX-mode-compatible bash.
- Scripts must work across **Linux, SunOS (Solaris), AIX, and Cygwin/Windows** — old vendored toolchains and quirky `ls`/`id`/`resize` handling exist deliberately. Don't "modernize" away the OS `case` branches.
- Comments and user-facing strings are frequently in **Chinese**; keep `LANG`/`LESSCHARSET=utf-8` assumptions intact.
- Indentation is mixed (tabs and spaces) across files — match the surrounding file rather than reformatting.
- This is a single-author personal repo committed straight to `master`. There's no CI, lint, or review gate; verify shell changes by running the script (use `-d` for debug logging, `-D` for `set -vx` trace).
