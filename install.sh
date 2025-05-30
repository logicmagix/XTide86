#! /usr/bin/env bash

set -e

# === Detect OS and Package Manager ===
detect_os_and_pkg() {
  OS=$(uname -s)

  case "$OS" in
    Darwin)
      PKG_MANAGER="brew"
      INSTALL_CMD="brew install"
      INSTALL_PATH="/usr/local/bin/xtide86"
      [ -d "/opt/homebrew/bin" ] && INSTALL_PATH="/opt/homebrew/bin/xtide86"  # Apple Silicon support
      ;;
    Linux)
      if [ -f "/etc/arch-release" ]; then
        PKG_MANAGER="pacman"
        INSTALL_CMD="sudo pacman -S --noconfirm"
        INSTALL_PATH="/usr/local/bin/xtide86"
      elif [ -f "/etc/debian_version" ]; then
        PKG_MANAGER="apt"
        INSTALL_CMD="sudo apt install -y"
        INSTALL_PATH="/usr/local/bin/xtide86"
      else
        PKG_MANAGER="unknown"
        INSTALL_CMD="echo 'Please install manually:'"
        INSTALL_PATH="/usr/local/bin/xtide86"
      fi
      ;;
    *)
      PKG_MANAGER="unknown"
      INSTALL_CMD="echo 'Please install manually:'"
      INSTALL_PATH="/usr/local/bin/xtide86"
      ;;
  esac

  echo "[XTide86] Detected OS: $OS"
  echo "[XTide86] Using package manager: $PKG_MANAGER"
  echo "[XTide86] Install path: $INSTALL_PATH"
}

update_package_manager() {
  case "$PKG_MANAGER" in
    apt)
      echo "[XTide86] Updating apt..."
      sudo apt update
      ;;
    pacman)
      echo "[XTide86] Updating pacman..."
      sudo pacman -Sy
      ;;
    brew)
      echo "[XTide86] Updating Homebrew..."
      brew update
      ;;
    *)
      echo "[XTide86] Skipping package manager update (unsupported or unknown)."
      ;;
  esac
}

# === Run OS detection and update ===
detect_os_and_pkg
update_package_manager
  # Exit on error

echo "Installing xtide86 dependencies..."

# === Update and install system packages ===
sudo apt update
sudo apt install -y \
  tmux \
  ncurses-term \
  neovim \
  python3 \
  python3-pip \
  python3-ipython \
  curl \
  git \
  fonts-powerline
  

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

# === Copy xtide86.sh and termic.sh to system path ===
echo "Installing xtide86 and TermiC launch scripts..."

# === Check if files exist ===
for script in "$SCRIPT_DIR/xtide86.sh" "$SCRIPT_DIR/termic.sh"; do
  if [ ! -f "$script" ]; then
    echo "Error: $script not found in $SCRIPT_DIR. Please ensure the file exists."
    exit 1
  fi
done

# === Set executable permissions locally (temporary for copying) ===
echo "Setting temporary executable permissions for xtide86.sh and termic.sh..."
if ! chmod +x "$SCRIPT_DIR/xtide86.sh" "$SCRIPT_DIR/termic.sh"; then
  echo "Error: Failed to set executable permissions on scripts."
  exit 1
fi

# === Copy xtide86.sh to /usr/local/bin ===
echo "Creating wrapper script at /usr/local/bin/xtide86..."

cat <<EOF | sudo tee /usr/local/bin/xtide86 > /dev/null
#!/usr/bin/env bash
SCRIPT_DIR="$SCRIPT_DIR"
bash "\$SCRIPT_DIR/xtide86.sh" "\$@"
EOF

sudo chmod +x /usr/local/bin/xtide86
echo "Wrapper script created."

echo "xtide86.sh installed to /usr/local/bin/xtide86."

# === Copy termic.sh to /usr/local/bin ===
echo "Copying termic.sh to /usr/local/bin/..."
if ! sudo cp -f "$SCRIPT_DIR/termic.sh" /usr/local/bin/termic; then
  echo "Error: Failed to copy termic.sh to /usr/local/bin. Check permissions or disk space."
  exit 1
fi
echo "termic.sh installed to /usr/local/bin/termic."

# === Ensure destination files are executable ===
echo "Ensuring installed scripts are executable..."
if ! sudo chmod 755 /usr/local/bin/xtide86 /usr/local/bin/termic; then
  echo "Error: Failed to set executable permissions on installed scripts."
  exit 1
fi

# === Remove executable permissions from source scripts and installer ====
echo "Removing executable permissions from source scripts and installer..."
if ! chmod -x "$SCRIPT_DIR/xtide86.sh" "$SCRIPT_DIR/termic.sh" "$SCRIPT_DIR/${BASH_SOURCE[0]}"; then
  echo "Warning: Failed to remove executable permissions from some source files."
fi
echo "Source scripts are no longer executable. Use 'xtide86' or 'termic' from /usr/local/bin."

echo "Ensuring IPython is available..."

# === Try apt install for system-wide fallback ===
if ! command -v ipython3 &> /dev/null; then
  echo "Attempting to install ipython3 via apt..."
  sudo apt update
  sudo apt install -y python3-ipython || echo "Warning: apt install failed. You may need to install IPython manually."
fi

# === Ensure IPython is available ===
ensure_ipython() {
  echo "[XTide86] Ensuring IPython is available..."

  # Check if ipython or ipython3 is already available
  if command -v ipython &> /dev/null; then
    echo "[XTide86] 'ipython' is available."
    return 0
  elif command -v ipython3 &> /dev/null; then
    echo "[XTide86] 'ipython3' is available. Creating symlink for 'ipython'..."
    sudo ln -sf "$(which ipython3)" /usr/local/bin/ipython
    if command -v ipython &> /dev/null; then
      echo "[XTide86] Symlink created successfully."
      return 0
    else
      echo "[XTide86] Warning: Failed to create 'ipython' symlink."
    fi
  fi

  # No ipython or ipython3 found, try installing
  if command -v conda &> /dev/null; then
    echo "[XTide86] Conda detected. Installing IPython via conda..."
    if conda install -y ipython; then
      echo "[XTide86] IPython installed via conda."
    else
      echo "[XTide86] Warning: Conda install failed. Check your environment."
    fi
  else
    echo "[XTide86] Attempting to install ipython3 via apt..."
    sudo apt update
    if sudo apt install -y python3-ipython; then
      echo "[XTide86] IPython installed via apt."
    else
      echo "[XTide86] Warning: apt install failed. You may need to install IPython manually."
    fi
  fi

  # Final check for ipython
  if ! command -v ipython &> /dev/null && ! command -v ipython3 &> /dev/null; then
    echo "[XTide86] Warning: No 'ipython' or 'ipython3' detected. XTide86 may not function properly."
  elif command -v ipython3 &> /dev/null && ! command -v ipython &> /dev/null; then
    echo "[XTide86] Creating symlink for 'ipython' -> 'ipython3'..."
    sudo ln -sf "$(which ipython3)" /usr/local/bin/ipython
    if ! command -v ipython &> /dev/null; then
      echo "[XTide86] Warning: Failed to create 'ipython' symlink."
    fi
  fi
}

echo "Removing executable permissions from source scripts and installer..."
if ! chmod -x "$SCRIPT_DIR/xtide86.sh" "$SCRIPT_DIR/termic.sh" "$SCRIPT_DIR/${BASH_SOURCE[0]}"; then
  echo "Warning: Failed to remove executable permissions from some source files."
fi
echo "Source scripts are no longer executable. Use 'xtide86' or 'termic' from /usr/local/bin."

ensure_ipython


# === Install man page ===
MANPAGE_SOURCE="$SCRIPT_DIR/xtide86.1"
MANPAGE_TARGET="/usr/share/man/man1/xtide86.1.gz"

if [ -f "$MANPAGE_SOURCE" ]; then
    echo "[XTide86] Compressing man page..."
    if gzip -f -c "$MANPAGE_SOURCE" > xtide86.1.gz; then
        echo "[XTide86] Installing man page to $MANPAGE_TARGET..."
        sudo cp xtide86.1.gz "$MANPAGE_TARGET"
        sudo mandb
        echo "[XTide86] Man page installed. Try: man xtide86"
    else
        echo "[XTide86] Error: Failed to compress man page."
    fi
else
    echo "[XTide86] Warning: xtide86.1 not found. Skipping man page install."
fi

# Desktop launcher
GLOBAL_INSTALL=false
if [ "$1" == "--global" ]; then
  GLOBAL_INSTALL=true
fi

if [ "$GLOBAL_INSTALL" = true ]; then
  echo "Installing system-wide .desktop launcher..."
  sudo cp ./xtide86.desktop /usr/share/applications/
  sudo cp ./xtide86.png /usr/share/icons/hicolor/64x64/apps/
  sudo update-desktop-database /usr/share/applications || true
else
  echo "Installing user-local .desktop launcher..."
  cp ./xtide86.desktop ~/.local/share/applications/
  mkdir -p ~/.local/share/icons/hicolor/64x64/apps
  cp ./xtide86.png ~/.local/share/icons/hicolor/64x64/apps/
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

echo "XTide86 installed! You can now launch it from the app menu or by typing 'xtide86'."
