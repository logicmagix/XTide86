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
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
# Credits

#This project includes TermiC from [Yusuf Kagan Hanoglu/Max Schillinger/TermiC], licensed under the [GPL3] License.

#!/usr/bin/env bash
set -e

SESSION_NAME="xtide86"
TMUX_CONF="$HOME/.tmux.conf"
IS_NO_COLOR=false

# === Flag Parsing ===
case "$1" in
  --no-color|-nc)
    IS_NO_COLOR=true
    echo "[XTide86] Applying hybrid minimal color scheme..."

    # Write tmux.conf for 88-color mode
    cat <<EOF > "$TMUX_CONF"
# XTide86: Hybrid minimal color scheme
set -g default-terminal "xterm-88color"
set -sa terminal-overrides ",xterm-88color*:colors=88"
set -g mouse on
EOF

    echo "[XTide86] Hybrid minimal color config applied."
    ;;
  --color|-c)
    IS_NO_COLOR=false
    echo "[XTide86] Enabling full color mode..."

    [ -f "$TMUX_CONF" ] && cp "$TMUX_CONF" "$TMUX_CONF.bak"

    cat <<EOF > "$TMUX_CONF"
# XTide86: Full color mode
set -g default-terminal "tmux-256color"
set -as terminal-overrides ',*:Tc'
set -g mouse on
EOF

    echo "[XTide86] Applied full color config."
    ;;
  *)
    IS_NO_COLOR=false
    echo "[XTide86] No flag provided, applying default 256-color mode..."

    [ -f "$TMUX_CONF" ] && cp "$TMUX_CONF" "$TMUX_CONF.bak"

    cat <<EOF > "$TMUX_CONF"
# XTide86: Default 256-color mode
set -g default-terminal "tmux-256color"
set -as terminal-overrides ',*:Tc'
set -g mouse on
EOF

    echo "[XTide86] Applied default 256-color config."
    ;;
esac

# Shift remaining args (do this only once!)
(( $# )) && shift

# === Apply environment variables *after* flag handling ===
if [ "$IS_NO_COLOR" = false ]; then
  export TERM="xterm-256color"
  export COLORTERM=truecolor
  unset NVIM_NO_COLOR
else
  export TERM="xterm-88color"  # 88-color palette
  unset COLORTERM
  export NVIM_NO_COLOR=1
fi

# Ensure mouse support is enabled in user's tmux.conf
if [ -f "$TMUX_CONF" ]; then
  if ! grep -q "set -g mouse on" "$TMUX_CONF"; then
    echo "set -g mouse on" >> "$TMUX_CONF"
    echo "[XTide86] Enabled mouse support in ~/.tmux.conf"
  fi
else
  echo "set -g mouse on" > "$TMUX_CONF"
  echo "[XTide86] Created ~/.tmux.conf with mouse support"
fi

# Start tmux session only if it doesn't exist
if ! tmux has-session -t xtide86 2>/dev/null; then
  tmux new-session -d -s xtide86
  tmux split-window -h
  tmux send-keys -t xtide86:0.0 'nvim' C-m
  tmux send-keys -t xtide86:0.1 'nvim' C-m

  # Keybindings
  tmux unbind C-b
  tmux set-option -g prefix C-q
  tmux bind-key C-q send-prefix
  tmux bind-key -n C-a resize-pane -R 999 \; select-pane -t 1
  tmux bind-key -n C-d resize-pane -L 999 \; select-pane -t 0
  tmux bind-key -n C-s resize-pane -x 50%
fi

tmux attach-session -t xtide86
