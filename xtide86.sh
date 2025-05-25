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


#!/bin/bash

# Check if tmux session 'console' exists
if tmux has-session -t console 2>/dev/null; then
    # Attach to existing session
    tmux attach-session -t console
else
    # Create new tmux session
    tmux new-session -d -s console
    tmux split-window -h
    tmux send-keys -t console:0.1 'nvim' C-m
    tmux send-keys -t console:0.0 'nvim' C-m

    # Remap prefix from Ctrl-b to Ctrl-q
    tmux unbind C-b
    tmux set-option -g prefix C-q
    tmux bind-key C-q send-prefix

    # Set up keybindings
    tmux bind-key -n C-a resize-pane -R 999 \; select-pane -t 1  # Maximize left pane
    tmux bind-key -n C-d resize-pane -L 999 \; select-pane -t 0  # Maximize right pane
    tmux bind-key -n C-s resize-pane -x 50%                      # Reset to vertical split

    # Enable session saving (requires tmux-resurrect plugin for persistence)
    # Ensure tmux-resurrect is installed, or this won't work
    tmux set-option -g @resurrect-capture-pane-contents 'on'

    # Attach to the newly created session
    tmux attach-session -t console
fi
