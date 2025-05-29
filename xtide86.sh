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

SESSION_NAME="xtide86"
TMUX_CONF="$HOME/.tmux.conf"
IS_NO_COLOR=false
FILENAME=""

# === Flag Parsing ===
while [ $# -gt 0 ]; do
  case "$1" in
    --no-color|-nc)
      IS_NO_COLOR=true
      echo "[XTide86] Applying hybrid 88-color scheme..."
      cat <<EOF > "$TMUX_CONF"
# XTide86: Hybrid 88-color scheme
set -g default-terminal "xterm-88color"
set -sa terminal-overrides ",xterm-88color*:colors=88"
set -g mouse on
EOF
      echo "[XTide86] Hybrid 88-color config applied."
      ;;
    --color|-c)
      IS_NO_COLOR=""
      echo "[>>>XTide86] Enabling full neon 256-color mode..."
      [ -s "$TMUX_CONF" ] && cp "$TMUX_CONF" "$TMUX_CONF.bak"
      cat <<EOF > "$TMUX_CONF"
# XTide86: Full neon 256-color mode
set -g default-terminal "tmux-256color"
set -sa terminal-overrides ",*:Tc"
set -g mouse on
EOF
      echo "[XTide86] Applied full neon 256-color config."
      ;;
    --update)
      echo "[XTide86] Updating script from GitHub..."
      if ! command -v git >/dev/null 2>&1; then
        echo "[XTide86] Error: git not installed. Please install git."
        exit 1
      fi
      if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "[XTide86] Error: Not in a git repository. Please run from the XTide86 repo clone."
        exit 1
      fi
      CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
      if git pull origin "$CURRENT_BRANCH" --rebase; then
        echo "[XTide86] Successfully pulled latest changes from GitHub."
        SCRIPT_NAME="xtide86.sh"
        if [ ! -f "$SCRIPT_NAME" ]; then
          echo "[XTide86] Error: $SCRIPT_NAME not found in repository."
          exit 1
        fi
        INSTALL_PATH="/usr/local/bin/xtide86"
        if sudo cp "$SCRIPT_NAME" "$INSTALL_PATH"; then
          if sudo chmod +x "$INSTALL_PATH"; then
            echo "[XTide86] Script updated and installed to $INSTALL_PATH."
          else
            echo "[XTide86] Error: Failed to make $INSTALL_PATH executable."
            exit 1
          fi
        else
          echo "[XTide86] Error: Failed to copy $SCRIPT_NAME to $INSTALL_PATH."
          exit 1
        fi
      else
        echo "[XTide86] Error: Failed to pull changes. Check for merge conflicts or connectivity."
        exit 1
      fi
      exit 0
      ;;
    --version)
      echo "[XTide86] Version 1.0.2"
      exit 0
      ;;
    *)
      if [ -z "$FILENAME" ]; then
        FILENAME="$1"
      else
        echo "[XTide86] Error: Only one filename can be provided."
        exit 1
      fi
      ;;
  esac
  shift
done

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

# === Write default tmux.conf if no flags provided (except filename) ===
if [ -z "$1" ] && [ -z "$FILENAME" ]; then
  IS_NO_COLOR=true
  echo "[XTide86] No flag provided, applying default hybrid 88-color scheme..."
  cat <<EOF > "$TMUX_CONF"
# XTide86: Default hybrid 88-color scheme
set -g default-terminal "xterm-88color"
set -sa terminal-overrides ",xterm-88color*:colors=88"
set -g mouse on
EOF
  echo "[XTide86] Applied default hybrid 88-color config."
fi

# === Check for detached session ===
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  if ! tmux list-clients -t "$SESSION_NAME" >/dev/null 2>&1; then
    echo "[XTide86] Warning: A detached tmux session named '$SESSION_NAME' exists."
    echo "Options: [a]ttach to existing session, [n]ew session (kill existing), [c]ancel"
    read -r -p "Choose an option (a/n/c): " choice
    case "$choice" in
      a|A)
        if [ -n "$FILENAME" ]; then
          if tmux list-panes -t "$SESSION_NAME":0.0 >/dev/null 2>&1; then
            tmux select-pane -t "$SESSION_NAME":0.0
            tmux send-keys -t "$SESSION_NAME":0.0 C-c "nvim \"$FILENAME\"" C-m
            echo "[XTide86] Opened $FILENAME in left pane of existing session."
          else
            echo "[XTide86] Warning: Left pane not available in existing session. Attaching without opening $FILENAME."
          fi
        fi
        if ! tmux attach-session -t "$SESSION_NAME"; then
          echo "[XTide86] Error: Failed to attach to session '$SESSION_NAME'. Try 'tmux kill-server' or check session state."
          echo "Run 'tmux list-sessions' to inspect."
          exit 1
        fi
        exit 0
        ;;
      n|N)
        tmux kill-session -t "$SESSION_NAME"
        echo "[XTide86] Killed existing session. Creating new session..."
        ;;
      c|C|*)
        echo "[XTide86] Operation cancelled."
        exit 1
        ;;
    esac
  else
    echo "[XTide86] Error: An active tmux session named '$SESSION_NAME' is already attached."
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

# === Start tmux session ===
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
