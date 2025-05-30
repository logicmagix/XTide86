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
COLOR_FLAG_PROVIDED=false

# === Flag Parsing ===
while [ $# -gt 0 ]; do
  case "$1" in
    --no-color|-nc)
      IS_NO_COLOR=true
      COLOR_FLAG_PROVIDED=true
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
      COLOR_FLAG_PROVIDED=true
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
      echo "[XTide86] Checking for updates from GitHub..."
      # Resolve repository root
      REPO_DIR="$(git rev-parse --show-toplevel 2>/dev/null || true)"
      if [ -z "$REPO_DIR" ] || [ ! -d "$REPO_DIR/.git" ]; then
        echo "[XTide86] Error: Not in a git repository or .git directory missing."
        echo "Run 'git clone <your-repo-url>' and execute from the repository directory."
        exit 1
      fi
      # Change to repository root
      cd "$REPO_DIR" || { echo "[XTide86] Error: Failed to change to repository directory."; exit 1; }
      echo "[XTide86] Working in repository: $REPO_DIR"
      if ! command -v git >/dev/null 2>&1; then
        echo "[XTide86] Error: git not installed. Please install git."
        exit 1
      fi
      if ! git diff --quiet || ! git diff --cached --quiet; then
        echo "[XTide86] Error: You have unstaged or uncommitted changes."
        echo "Run 'git status' to see them."
        echo "Options: Commit ('git add . && git commit'), stash ('git stash'), or discard ('git restore .')."
        exit 1
      fi
      CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || { echo "[XTide86] Error: Failed to get current branch."; exit 1; })
      echo "[XTide86] Current branch: $CURRENT_BRANCH"
      if ! git fetch origin "$CURRENT_BRANCH" 2>/dev/null; then
        echo "[XTide86] Error: Failed to fetch from origin. Check network or repository access."
        exit 1
      fi
      LOCAL_HASH=$(git rev-parse HEAD 2>/dev/null || { echo "[XTide86] Error: Failed to get local commit hash."; exit 1; })
      REMOTE_HASH=$(git rev-parse "origin/$CURRENT_BRANCH" 2>/dev/null || { echo "[XTide86] Error: Failed to get remote commit hash."; exit 1; })
      if [ "$LOCAL_HASH" = "$REMOTE_HASH" ]; then
        echo "[XTide86] No update needed: Repository is up-to-date."
        exit 0
      fi
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
        # Update termic.sh if present
        if [ -f "termic.sh" ]; then
          if sudo cp "termic.sh" /usr/local/bin/termic && sudo chmod +x /usr/local/bin/termic; then
            echo "[XTide86] termic.sh updated and installed to /usr/local/bin/termic."
          else
            echo "[XTide86] Warning: Failed to update termic.sh."
          fi
        fi
      else
        echo "[XTide86] Error: Failed to pull changes. Check for merge conflicts or connectivity."
        exit 1
      fi
      exit 0
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
