#!/usr/bin/env bash
# tide42 - a terminal IDE powered by tmux and nvim
# Copyright (C) 2025 Pavle Dzakula
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# Credits
# This project includes `termic.sh` from [Yusuf Kagan Hanoglu/Max Schillinger/TermiC], licensed under the [GPL3] License.


set -e
echo "[tide86] Running..."

IS_LOW_COLOR=false
IS_QUIET=false
FILENAME=""
TIDE_VERSION="$(cat "$(dirname "$0")/VERSION")"
COLOR_FLAG_PROVIDED=false
UPDATE_PROCESSED=false
SESSION_NAME="tide42"
TMUX_CONF="$HOME/.tmux.conf"

log() {
  $IS_QUIET || echo "[tide42] $@"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --whereami)
      SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
      SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
      log "Script path: $SCRIPT_PATH"
      log "Source directory: $SCRIPT_DIR"
      exit 0
      ;;
      --lite)
      shift
      log "[tide42] Launching in lite mode (no tmux)..."
      exec nvim "$@"
      ;;
    --quiet|-q)
      IS_QUIET=true
      ;;
    --low-color|-lc) # 88 Color
      IS_LOW_COLOR=true
      COLOR_FLAG_PROVIDED=true
      log "Enabling low-color (88-color) mode. Warning: Home/End keys may not work."
      [ -s "$TMUX_CONF" ] && cp "$TMUX_CONF" "$TMUX_CONF.bak"
      cat <<EOF > "$TMUX_CONF"
# tide42: 88-color config
set -g default-terminal "xterm-88color"
set -sa terminal-overrides ",xterm-88color*:colors=88"
set -g mouse on
EOF
      log "Applied 88-color config."
      ;;
    --update)
      UPDATE_PROCESSED=true
      log "Checking for updates from GitHub..."

      SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
      SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
      cd "$SCRIPT_DIR" || { log "Error: Cannot access directory $SCRIPT_DIR"; exit 1; }

      if [ ! -d .git ]; then
        log "Error: This directory is not a Git repository."
        exit 1
      fi

      CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "detached")
      [ "$CURRENT_BRANCH" = "detached" ] && {
        log "Error: You are in a detached HEAD state. Cannot auto-update."
        exit 1
      }

      log "Current branch: $CURRENT_BRANCH"
      
      git fetch origin "$CURRENT_BRANCH" --prune || {
        log "Error: Failed to fetch updates from origin."
        exit 1
      }

      LOCAL_HASH=$(git rev-parse HEAD)
      REMOTE_HASH=$(git rev-parse "origin/$CURRENT_BRANCH")
      VERSION_FILE="$SCRIPT_DIR/VERSION"
      VERSION_NUMBER="unknown"
      [ -f "$VERSION_FILE" ] && VERSION_NUMBER=$(<"$VERSION_FILE")

      if [ "$LOCAL_HASH" = "$REMOTE_HASH" ]; then
        SHORT_HASH=$(git rev-parse --short HEAD)
        log "Already on the latest version: v$VERSION_NUMBER ($CURRENT_BRANCH@$SHORT_HASH)"
        exit 0
      fi

      log "Updating from $LOCAL_HASH to $REMOTE_HASH (v$VERSION_NUMBER)"
      log "Discarding local changes and syncing to latest commit..."

      git reset --hard "origin/$CURRENT_BRANCH" || {
        log "Error: Failed to reset to latest version."
        exit 1
      }

      log "Update complete."

      # === Re-run install script if present ===
      INSTALL_SCRIPT="$SCRIPT_DIR/install.sh"
      if [ -f "$INSTALL_SCRIPT" ]; then
        log "Running installer to apply updates..."
        chmod +x "$INSTALL_SCRIPT"
        "$INSTALL_SCRIPT" --quiet || log "Warning: Installer exited with errors"
      else
        log "No installer found. Skipping install step."
      fi

      exit 0
      ;;

    --version)
      log "tide42 version $TIDE_VERSION"
      exit 0
      ;;
    --help|-h)
      echo "Usage: tide42 [--color | --low-color] [--update] [--quiet] [--version] [filename]"
      echo ""
      echo "Options:"
      echo "  --whereami         Display git installation directory"
      echo "  --lite             Launch without tmux for quick editing or low-resource systems"
      echo "  --low-color, -lc   Enable 88-color mode (warning: Home/End keys may not work)"
      echo "  --quiet,  -q       Suppress log output"
      echo "  --update           Pull latest Git changes to clean repo and reinstall"
      echo "  --version          Show current version"
      echo "  --help,   -h       Show this help message"
      echo "  [filename]         Open specified file in Neovim"
      exit 0
      ;;
    *)
      if [ -z "$FILENAME" ]; then
        FILENAME="$1"
      else
        log "Error: Only one filename can be provided."
        exit 1
      fi
      ;;
  esac
  shift
done

# === Exit if --update was processed ===
if [ "$UPDATE_PROCESSED" = true ]; then
  log "Update process completed, exiting."
  exit 0
fi

# === Apply environment variables ===
if [ "$IS_LOW_COLOR" = true ]; then
  export TERM="xterm-88color"
  unset COLORTERM
  export NVIM_NO_COLOR=1
  log "Using 88-color mode. Note: Home/End keys may not function."
else
  export TERM="xterm-256color"
  export COLORTERM=truecolor
  unset NVIM_NO_COLOR
  log "Using default 256-color mode."
fi

# === Write default tmux.conf only if no color flag provided ===
if [ "$COLOR_FLAG_PROVIDED" = false ]; then
  log "No color flag provided, applying default 256-color scheme..."
  [ -s "$TMUX_CONF" ] && cp "$TMUX_CONF" "$TMUX_CONF.bak"
  cat <<EOF > "$TMUX_CONF"
# tide42: Default 256-color scheme
set -g default-terminal "tmux-256color"
set -sa terminal-overrides ",*:Tc"
set -g mouse on
EOF
  log "Applied default 256-color config."
fi

# === Check for existing session ===
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  if tmux list-clients -t "$SESSION_NAME" >/dev/null 2>&1; then
    tmux detach-client -s "$SESSION_NAME" 2>/dev/null || true
    log "Detached existing clients to apply new color profile."
  else
    log "Detached session '$SESSION_NAME' found."
  fi
  if [ -n "$FILENAME" ]; then
    if tmux list-panes -t "$SESSION_NAME":0.0 >/dev/null 2>&1; then
      tmux select-pane -t "$SESSION_NAME":0.0
      tmux send-keys -t "$SESSION_NAME":0.0 C-c ":qall!" C-m "nvim \"$FILENAME\"" C-m
      log "Opened $FILENAME in left pane of existing session."
    else
      log "Warning: Left pane not available. Attaching without opening $FILENAME."
    fi
  fi
  if tmux attach-session -t "$SESSION_NAME"; then
    exit 0
  else
    log "Error: Failed to attach to session '$SESSION_NAME'. Try 'tmux kill-session -t $SESSION_NAME'."
    exit 1
  fi
fi

# === Ensure mouse support in tmux.conf ===
if [ -s "$TMUX_CONF" ]; then
  if ! grep -q "set -g mouse on" "$TMUX_CONF"; then
    echo "set -g mouse on" >> "$TMUX_CONF"
    log "Enabled mouse support in ~/.tmux.conf"
  fi
else
  echo "set -g mouse on" > "$TMUX_CONF"
  log "Created ~/.tmux.conf with mouse support"
fi

# === Start new tmux session ===
tmux new-session -d -s "$SESSION_NAME"
tmux split-window -h

# Open file in left pane (pane 0) if filename provided, otherwise open nvim
if [ -n "$FILENAME" ]; then
  tmux send-keys -t "$SESSION_NAME":0.0 "nvim \"$FILENAME\"" C-m
else
  tmux send-keys -t "$SESSION_NAME":0.0 'nvim' C-m
fi
tmux send-keys -t "$SESSION_NAME":0.1 'nvim' C-m

# === Keybindings ===
tmux unbind C-b
tmux set-option -g prefix C-q
tmux bind-key C-q send-prefix
tmux bind-key -n C-a resize-pane -R 999 \; select-pane -t 1
tmux bind-key -n C-d resize-pane -L 999 \; select-pane -t 0
tmux bind-key -n C-s resize-pane -x 50%

tmux attach-session -t "$SESSION_NAME"
