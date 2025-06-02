#! /usr/bin/env bash

set -e

echo "[+] Installed tide42 and legacy xtide86 wrappers to $BIN_DIR"

# === Legacy xtide86 alias ===
cat <<EOF | sudo tee /usr/local/bin/xtide86 > /dev/null
#!/usr/bin/env bash
echo "[XTide86] XTide86 has been renamed to Tide42."
exec tide42 "\$@"
EOF

sudo chmod +x /usr/local/bin/xtide86

# === Detect OS and Package Manager ===
detect_os_and_pkg() {
  OS=$(uname -s)

  case "$OS" in
    Darwin)
      PKG_MANAGER="brew"
      INSTALL_CMD="brew install"
      INSTALL_PATH="/usr/local/bin/tide42"
      [ -d "/opt/homebrew/bin" ] && INSTALL_PATH="/opt/homebrew/bin/tide42"  # Apple Silicon support
      ;;
    Linux)
      if [ -f "/etc/arch-release" ]; then
        PKG_MANAGER="pacman"
        INSTALL_CMD="sudo pacman -S --noconfirm"
        INSTALL_PATH="/usr/local/bin/tide42"
      elif [ -f "/etc/debian_version" ]; then
        PKG_MANAGER="apt"
        INSTALL_CMD="sudo apt install -y"
        INSTALL_PATH="/usr/local/bin/tide42"
      else
        PKG_MANAGER="unknown"
        INSTALL_CMD="echo 'Please install manually:'"
        INSTALL_PATH="/usr/local/bin/tide42"
      fi
      ;;
    *)
      PKG_MANAGER="unknown"
      INSTALL_CMD="echo 'Please install manually:'"
      INSTALL_PATH="/usr/local/bin/tide42"
      ;;
  esac

  echo "[tide42] Detected OS: $OS"
  echo "[tide42] Using package manager: $PKG_MANAGER"
  echo "[tide42] Install path: $INSTALL_PATH"
}

update_package_manager() {
  case "$PKG_MANAGER" in
    apt)
      echo "[tide42] Updating apt..."
      sudo apt update
      ;;
    pacman)
      echo "[tide42] Updating pacman..."
      sudo pacman -Sy
      ;;
    brew)
      echo "[tide42] Updating Homebrew..."
      brew update
      ;;
    *)
      echo "[tide42] Skipping package manager update (unsupported or unknown)."
      ;;
  esac
}

# === Run OS detection and update ===
detect_os_and_pkg
update_package_manager

# === Install system packages ===
echo "[tide42] Installing tide42 dependencies..."

# Define packages (map different names if needed)
declare -A PKG_NAMES=(
  ["tmux"]="tmux"
  ["ncurses"]="ncurses-term"  # apt-specific, adjust below for others
  ["neovim"]="neovim"         # pacman uses 'neovim', brew uses 'neovim'
  ["python3"]="python3"
  ["python3-pip"]="python3-pip"
  ["ipython"]="python3-ipython"
  ["curl"]="curl"
  ["git"]="git"
  ["fonts-powerline"]="fonts-powerline"
)

# Adjust package names for specific package managers
case "$PKG_MANAGER" in
  pacman)
    PKG_NAMES["ncurses"]="ncurses"
    PKG_NAMES["python3-pip"]="python-pip"
    PKG_NAMES["ipython"]="python-ipython"
    PKG_NAMES["fonts-powerline"]="powerline-fonts"
    ;;
  brew)
    PKG_NAMES["ncurses"]="ncurses"
    PKG_NAMES["python3-pip"]="python-pip"
    PKG_NAMES["ipython"]="ipython"
    PKG_NAMES["fonts-powerline"]="powerline-fonts"
    ;;
esac

# Build package list for installation
PKG_LIST=""
for pkg in "${!PKG_NAMES[@]}"; do
  PKG_LIST="${PKG_LIST} ${PKG_NAMES[$pkg]}"
done

# Install packages using the appropriate command
if [ "$PKG_MANAGER" = "unknown" ]; then
  echo "[tide42] Unknown package manager. Please install the following packages manually:"
  for pkg in "${!PKG_NAMES[@]}"; do
    echo "- ${PKG_NAMES[$pkg]}"
  done
  exit 1
else
  echo "[tide42] Installing packages: $PKG_LIST"
  $INSTALL_CMD $PKG_LIST || {
    echo "[tide42] Failed to install packages. Please check the package manager and try again."
    exit 1
  }
fi
  

# === Install vim-plug ===
if [ ! -f ~/.local/share/nvim/site/autoload/plug.vim ]; then
  echo "Installing vim-plug for Neovim..."
  curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# === Copy nvim config ===
echo "Copying Neovim config..."
mkdir -p ~/.config/nvim
cp ./init.vim ~/.config/nvim/init.vim

# === Resolve the script's directory ===
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# === Copy tide42.sh and termic.sh to system path ===
echo "Installing tide42 and TermiC launch scripts..."

# === Check if files exist ===
for script in "$SCRIPT_DIR/tide42.sh" "$SCRIPT_DIR/termic.sh"; do
  if [ ! -f "$script" ]; then
    echo "Error: $script not found in $SCRIPT_DIR. Please ensure the file exists."
    exit 1
  fi
done

# === Set executable permissions locally (temporary for copying) ===
echo "Setting temporary executable permissions for tide42.sh and termic.sh..."
if ! chmod +x "$SCRIPT_DIR/tide42.sh" "$SCRIPT_DIR/termic.sh"; then
  echo "Error: Failed to set executable permissions on scripts."
  exit 1
fi

# === Copy tide42.sh to /usr/local/bin ===
echo "Creating wrapper script at /usr/local/bin/tide42..."

cat <<EOF | sudo tee /usr/local/bin/tide42 > /dev/null
#!/usr/bin/env bash
SCRIPT_DIR="$SCRIPT_DIR"
bash "\$SCRIPT_DIR/tide42.sh" "\$@"
EOF

sudo chmod +x /usr/local/bin/tide42
echo "Wrapper script created."

echo "tide42.sh installed to /usr/local/bin/tide42."

# === Copy termic.sh to /usr/local/bin ===
echo "Copying termic.sh to /usr/local/bin/..."
if ! sudo cp -f "$SCRIPT_DIR/termic.sh" /usr/local/bin/termic; then
  echo "Error: Failed to copy termic.sh to /usr/local/bin. Check permissions or disk space."
  exit 1
fi
echo "termic.sh installed to /usr/local/bin/termic."

# === Ensure destination files are executable ===
echo "Ensuring installed scripts are executable..."
if ! sudo chmod 755 /usr/local/bin/tide42 /usr/local/bin/termic; then
  echo "Error: Failed to set executable permissions on installed scripts."
  exit 1
fi

# === Try apt install for system-wide fallback ===
if ! command -v ipython3 &> /dev/null; then
  echo "Attempting to install ipython3 via apt..."
  sudo apt update
  sudo apt install -y python3-ipython || echo "Warning: apt install failed. You may need to install IPython manually."
fi

# === Ensure IPython is available ===
ensure_ipython() {
  echo "[tide42] Ensuring IPython is available..."

  # Check if ipython or ipython3 is already available
  if command -v ipython &> /dev/null; then
    echo "[tide42] 'ipython' is available."
    return 0
  elif command -v ipython3 &> /dev/null; then
    echo "[tide42] 'ipython3' is available. Creating symlink for 'ipython'..."
    sudo ln -sf "$(which ipython3)" /usr/local/bin/ipython
    if command -v ipython &> /dev/null; then
      echo "[tide42] Symlink created successfully."
      return 0
    else
      echo "[tide42] Warning: Failed to create 'ipython' symlink."
    fi
  fi

  # No ipython or ipython3 found, try installing
  if command -v conda &> /dev/null; then
    echo "[tide42] Conda detected. Installing IPython via conda..."
    if conda install -y ipython; then
      echo "[tide42] IPython installed via conda."
    else
      echo "[tide42] Warning: Conda install failed. Check your environment."
    fi
  else
    echo "[tide42] Attempting to install ipython3 via apt..."
    sudo apt update
    if sudo apt install -y python3-ipython; then
      echo "[tide42] IPython installed via apt."
    else
      echo "[tide42] Warning: apt install failed. You may need to install IPython manually."
    fi
  fi

  # Final check for ipython
  if ! command -v ipython &> /dev/null && ! command -v ipython3 &> /dev/null; then
    echo "[tide42] Warning: No 'ipython' or 'ipython3' detected. tide42 may not function properly."
  elif command -v ipython3 &> /dev/null && ! command -v ipython &> /dev/null; then
    echo "[tide42] Creating symlink for 'ipython' -> 'ipython3'..."
    sudo ln -sf "$(which ipython3)" /usr/local/bin/ipython
    if ! command -v ipython &> /dev/null; then
      echo "[tide42] Warning: Failed to create 'ipython' symlink."
    fi
  fi
}


# === Install man page ===
MANPAGE_SOURCE="$SCRIPT_DIR/tide42.1"
MANPAGE_TARGET="/usr/share/man/man1/tide42.1.gz"

if [ -f "$MANPAGE_SOURCE" ]; then
    echo "[tide42] Compressing man page..."
    if gzip -f -c "$MANPAGE_SOURCE" > tide42.1.gz; then
        echo "[tide42] Installing man page to $MANPAGE_TARGET..."
        sudo cp tide42.1.gz "$MANPAGE_TARGET"
        sudo mandb
        echo "[tide42] Man page installed. Try: man tide42"
    else
        echo "[tide42] Error: Failed to compress man page."
    fi
else
    echo "[tide42] Warning: tide42.1 not found. Skipping man page install."
fi

# Desktop launcher
GLOBAL_INSTALL=false
if [ "$1" == "--global" ]; then
  GLOBAL_INSTALL=true
fi

if [ "$GLOBAL_INSTALL" = true ]; then
  echo "Installing system-wide .desktop launcher..."
  sudo cp ./tide42.desktop /usr/share/applications/
  sudo cp ./tide42.png /usr/share/icons/hicolor/64x64/apps/
  sudo update-desktop-database /usr/share/applications || true
else
  echo "Installing user-local .desktop launcher..."
  cp ./tide42.desktop ~/.local/share/applications/
  mkdir -p ~/.local/share/icons/hicolor/64x64/apps
  cp ./tide42.png ~/.local/share/icons/hicolor/64x64/apps/
  update-desktop-database ~/.local/share/applications || true
fi

if [ ! -f "$HOME/.tmux.conf" ]; then
  cat <<EOF > "$HOME/.tmux.conf"
set -g default-terminal "tmux-256color"
set -as terminal-overrides ',*:Tc'
EOF
fi

# === Install Neovim plugins ===
echo "Installing Neovim plugins..."
nvim +PlugInstall +qall

echo "tide42 installed! You can now launch it from the app menu or by typing 'tide42'."
