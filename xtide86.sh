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

# Force truecolor inside tmux if needed
if [[ $TERM == "xterm-256color" && -n "$TMUX" ]]; then
  export TERM=tmux-256color
fi
export COLORTERM=truecolor

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





