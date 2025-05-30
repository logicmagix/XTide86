#!/usr/bin/env bash
# xtide86 - a terminal IDE powered by tmux and nvim
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
echo "[XTide86] Running..."  # Debug: Confirm script runs


IS_NO_COLOR=false
IS_QUIET=false
FILENAME=""
XTIDE_VERSION="1.1.0"
COLOR_FLAG_PROVIDED=false
UPDATE_PROCESSED=false
SESSION_NAME="xtide86"
TMUX_CONF="$HOME/.tmux.conf"


log() {
  $IS_QUIET || echo "[XTide86] $@"
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
    --quiet|-q)
      IS_QUIET=true
      ;;
    --color|-c)
      IS_NO_COLOR=""
      COLOR_FLAG_PROVIDED=true
      log "Enabling full neon 256-color config..."
      [ -s "$TMUX_CONF" ] && cp "$TMUX_CONF" "$TMUX_CONF.bak"
      cat <<EOF > "$TMUX_CONF"
# XTide86: 256-color config
set -g default-terminal "tmux-256color"
set -sa terminal-overrides ",*:Tc"
set -g mouse on
EOF
      log "Applied 256-color config."
      ;;
    --update)
          UPDATE_PROCESSED=true
          log "Checking for updates from GitHub..."

          SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
          SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
          cd "$SCRIPT_DIR" || exit 1

          if [ -d .git ]; then
            log "Working in repository: $SCRIPT_DIR"
            CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
            log "Current branch: $CURRENT_BRANCH"
            git pull origin "$CURRENT_BRANCH"
          else
            log "Not a git repository. Cannot perform update."
            log "Update failed: This install isn't a Git clone."
            log "To enable automatic updates, clone XTide86 from GitHub like so:"
            log "    git clone https://github.com/logicmagix/XTIDE86.git"
            exit 1
          fi

          INSTALL_SCRIPT="$SCRIPT_DIR/install.sh"
          log "INSTALL_SCRIPT is: $INSTALL_SCRIPT"

          if [ -f "$INSTALL_SCRIPT" ]; then
            chmod +x "$INSTALL_SCRIPT"
            bash "$INSTALL_SCRIPT"
          else
            log "Error: install.sh not found at $INSTALL_SCRIPT"
          fi
      exit 0
      ;;
    --version)
      log "XTide86 version $XTIDE_VERSION"
      exit 0
      ;;
    --help|-h)
      echo "Usage: ./xtide86.sh [--color | --no-color] [--update] [--quiet] [--version]"
      echo ""
      echo "Options:"
      echo "  --color,  -c       Enable 256-color mode"
      echo "  --quiet,  -q       Suppress log output"
      echo "  --update           Pull latest Git changes and reinstall"
      echo "  --version          Show current version"
      echo "  --help,   -h       Show this help message"
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


# === Handle --update logic ===
if [ "$UPDATE_PROCESSED" = true ]; then
  log "Pulling latest changes..."
  git -C "$SCRIPT_DIR" pull --rebase

  log "Re-running installer..."
  bash "$SCRIPT_DIR/install.sh"

  exit 0
fi

# Exit if --update was processed
if [ "$UPDATE_PROCESSED" = true ]; then
  echo "[XTide86] Update process completed, exiting."
  exit 0
fi


# === Apply environment variables ===
if [ -z "$IS_NO_COLOR" ]; then
  export TERM="xterm-256color"
  export COLORTERM=truecolor
  unset NVIM_NO_COLOR
else
  export TERM="xterm-88color"
  unset COLORTERM
  export NVIM_NO_COLOR=1
fi


# === Write default tmux.conf only if no color flag provided ===
if [ "$COLOR_FLAG_PROVIDED" = false ] && [ -z "$FILENAME" ]; then
  IS_NO_COLOR=true
  echo "[XTide86] No color flag provided, applying default hybrid 88-color scheme..."
  cat <<EOF > "$TMUX_CONF"
# XTide86: Default hybrid 88-color scheme
set -g default-terminal "xterm-88color"
set -sa terminal-overrides ",xterm-88color*:colors=88"
set -g mouse on
EOF
  echo "[XTide86] Applied default hybrid 88-color config."
fi


# === Check for existing session ===
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  if tmux list-clients -t "$SESSION_NAME" >/dev/null 2>&1; then
    tmux detach-client -s "$SESSION_NAME" 2>/dev/null || true
    echo "[XTide86] Detached existing clients to apply new color profile."
  else
    echo "[XTide86] Detached session '$SESSION_NAME' found."
  fi
  # Apply color profile to the session
  if [ -n "$FILENAME" ]; then
    if tmux list-panes -t "$SESSION_NAME":0.0 >/dev/null 2>&1; then
      tmux select-pane -t "$SESSION_NAME":0.0
      tmux send-keys -t "$SESSION_NAME":0.0 C-c ":qall!" C-m "nvim \"$FILENAME\"" C-m
      echo "[XTide86] Opened $FILENAME in left pane of existing session."
    else
      echo "[XTide86] Warning: Left pane not available. Attaching without opening $FILENAME."
    fi
  fi
  # Attach to the session with the new color profile
  if tmux attach-session -t "$SESSION_NAME"; then
    exit 0
  else
    echo "[XTide86] Error: Failed to attach to session '$SESSION_NAME'. Try 'tmux kill-session -t $SESSION_NAME'."
    exit 1
  fi
fi


# === Ensure mouse support in tmux.conf ===
if [ -s "$TMUX_CONF" ]; then
  if ! grep -q "set -g mouse on" "$TMUX_CONF"; then
    echo "set -g mouse on" >> "$TMUX_CONF"
    echo "[XTide86] Enabled mouse support in ~/.tmux.conf"
  fi
else
  echo "set -g mouse on" > "$TMUX_CONF"
  echo "[XTide86] Created ~/.tmux.conf with mouse support"
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


# Keybindings
tmux unbind C-b
tmux set-option -g prefix C-q
tmux bind-key C-q send-prefix
tmux bind-key -n C-a resize-pane -R 999 \; select-pane -t 1
tmux bind-key -n C-d resize-pane -L 999 \; select-pane -t 0
tmux bind-key -n C-s resize-pane -x 50%


tmux attach-session -t "$SESSION_NAME"
