
## License

xtide86 is licensed under the GNU General Public License v3.0 or later.  
See the [LICENSE](./LICENSE) file for full details.

## TermiC Support

xtide86 includes `termic.sh`, a lightweight live shell launcher. It will be installed automatically to `/usr/local/bin/termic` unless it already exists.

This script is licensed under GPLv3 and included with permission.

# XTIDE86: eXTra IDE 86 

An ultra-efficient Neovim based IDE for Python and C/C++ prototyping.  

## Controls

## Keyboard hotkey layout quick reference:
Ctrl|\
====  =
qw  | wer        iop
asd | fg         l
|zxcvbn

Tmux based command: Ctrl-q + d (or gui exit button) = Exit and save tmux state (lost on restart of PC) 
Nvim based command:Q = Force-quit the program (reset for new session)

`Ctrl+ww` = Cycle between vim buffers within a tmux pane
`Ctrl+w` + <-, ^, ->, v = Selects vim buffer within current tmux panel
`\w` = fzf selects vim buffer from menu within current tmux panel (fuzzy finder, vim plugin)
`\e` = Locate file within current directory
`\r` = ripgrep within file
`\i` = vertical resize <NUMBER>
`\o` = optional OpenAI ChatGPT implementation with API key (stored in a global variable)
`\p` = Paste selected text into IPython panel and expand buffer, entering insert mode.

Tmux pane controls (work in insert or command mode)
`Ctrl+a` = Maximize left tmux pane
`Ctrl+s` = Split tmux panes
`Ctrl+d` = Maximize right tmux pane
`Ctrl+q`  + <-, -> = Switch between tmux panels (selected panel matches tmux bar color on the bottom)

`\f` = Grid (10x10)
`\g` = Grid (5x10)
`\l` = Paste selected text into TermiC panel and expand buffer, entering insert mode

`\z` = Maximize edit pane (lower)
`\x` = Maximize terminal group of panes (middle), main implementation of \i is to choose one of the two
`\c` = Maximize IPython pane (upper)

`\v` = Currently selected buffer
`\b` = Back to default settings
`\n` = Equalize vertical buffer dimensions

Once in insert mode in any ``nvim`` buffer, the recommended way of entering command mode is `ctrl+w`


## Features

- Full ``tmux`` and ``nvim`` '-powered terminal IDE with dynamic pane management
- Seamless integration with ``TermiC``, and ``IPython``
- Hotkey support for sending code directly into live interpreter sessions
- Single-interface fallback for simple edits
- Quick launch from Gnome via icon or keyboard shortcut
- Works in the tty as well as the terminal emulator

## Requirements

- ``tmux``
- ``neovim`` 0.9.0+ (tested on 0.9.5)
- ``vim-plug`` curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim (must run :PlugInstall within nvim to install plugins)
- ``TermiC`` wget "https://raw.githubusercontent.com/hanoglu/TermiC/main/TermiC.sh"  (live C/C++ shell)
- ``Anaconda3`` with ``IPython`` (preferred, but may work with base ``IPython``)
- ``bash``
- Works on aarch64. Tested on a Raspberry Pi5 and nvim 0.9.5 had to be built from source. Check your distro and dependencies on ARM. 

## Installation

Clone this repository:

```bash
git clone https://github.com/yourusername/xtide86.git
cd xtide86

Usage
Launch XTide86 from your terminal or assigned launcher. It will:

Open a tmux session with vertically split nvim, TermiC, and IPython

Send text from the file editor to the live interpreter buffer with \p for ipython and \l for TermiC

Automatic insert mode and buffer sizing for paste to Termic and paste to IPython functions.

Support session save (Ctrl+q+d) and reset with :Q

Without tmux?
Simply open nvim enjoy all the features without additional panes and ctrl q + d, ctrl q + a, ctrl q + s, and ctrl q + d controls.

Customization
See init.vim for plugin configuration, UI tweaks, and terminal behavior.
Feel free to remix pane sizes and colors to match your workflow.

TermiC Support
xtide86 includes termic.sh, a lightweight live shell.
It installs automatically to /usr/local/bin/termic.
Licensed under GPLv3 and included with permission.

Pull requests, stars, and forks welcome 

## Screenshots

![XTide86 full layout](./Screenshot1.png)
*A full IDE session running in terminal*

![Code sent to IPython](./Screenshot2.png)
*Pasting selected text into the IPython pane via hotkey*

![Code sent to TermiC](./Screenshot3.png)
*Pasting selected text into the TermiC pane via hotkey*

![Additional uses](./Screenshot4.png)
*Monitor system performance from within XTide86 and more*

![Panel sizing](./Screenshot5.png)
*Any configuration to match your workflow*

## Built With

xtide86 uses and integrates the following open-source tools:

- [Vim](https://www.vim.org/)
- [tmux](https://github.com/tmux/tmux)
- [Anaconda3](https://www.anaconda.com/)
- [IPython](https://ipython.org/)
- [vim-plug](https://github.com/junegunn/vim-plug)
- [NERDTree](https://github.com/preservim/nerdtree)
- [TermiC](https://github.com/your-source-if-public-or-forked)

Thanks to the developers of these projects for making powerful tools free and accessible.

## Acknowledgments

- Thanks to my dad, whose passion for logic and engineering inspired this project.
