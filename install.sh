#!/bin/bash
set -e  # Exit on error

echo "Installing xtide86 dependencies..."

# Update and install system packages
sudo apt update
sudo apt install -y \
  tmux \
  neovim \
  python3 \
  python3-pip \
  python3-ipython \
  curl \
  git \
  fonts-powerline

# Install vim-plug
if [ ! -f ~/.local/share/nvim/site/autoload/plug.vim ]; then
  echo "Installing vim-plug for Neovim..."
  curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# Copy nvim config
echo "Copying Neovim config..."
mkdir -p ~/.config/nvim
cp ./init.vim ~/.config/nvim/init.vim

# Resolve the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copy xtide86.sh and termic.sh to system path
echo "Installing xtide86 and TermiC launch scripts..."

# Check if files exist
for script in "$SCRIPT_DIR/xtide86.sh" "$SCRIPT_DIR/termic.sh"; do
  if [ ! -f "$script" ]; then
    echo "Error: $script not found in $SCRIPT_DIR. Please ensure the file exists."
    exit 1
  fi
done

# Set executable permissions locally (temporary for copying)
echo "Setting temporary executable permissions for xtide86.sh and termic.sh..."
if ! chmod +x "$SCRIPT_DIR/xtide86.sh" "$SCRIPT_DIR/termic.sh"; then
  echo "Error: Failed to set executable permissions on scripts."
  exit 1
fi

# Copy xtide86.sh to /usr/local/bin
echo "Copying xtide86.sh to /usr/local/bin/..."
if ! sudo cp -f "$SCRIPT_DIR/xtide86.sh" /usr/local/bin/xtide86; then
  echo "Error: Failed to copy xtide86.sh to /usr/local/bin. Check permissions or disk space."
  exit 1
fi
echo "xtide86.sh installed to /usr/local/bin/xtide86."

# Copy termic.sh to /usr/local/bin
echo "Copying termic.sh to /usr/local/bin/..."
if ! sudo cp -f "$SCRIPT_DIR/termic.sh" /usr/local/bin/termic; then
  echo "Error: Failed to copy termic.sh to /usr/local/bin. Check permissions or disk space."
  exit 1
fi
echo "termic.sh installed to /usr/local/bin/termic."

# Ensure destination files are executable
echo "Ensuring installed scripts are executable..."
if ! sudo chmod 755 /usr/local/bin/xtide86 /usr/local/bin/termic; then
  echo "Error: Failed to set executable permissions on installed scripts."
  exit 1
fi

# Remove executable permissions from source scripts and installer
echo "Removing executable permissions from source scripts and installer..."
if ! chmod -x "$SCRIPT_DIR/xtide86.sh" "$SCRIPT_DIR/termic.sh" "$SCRIPT_DIR/${BASH_SOURCE[0]}"; then
  echo "Warning: Failed to remove executable permissions from some source files."
fi
echo "Source scripts are no longer executable. Use 'xtide86' or 'termic' from /usr/local/bin."

echo "Ensuring IPython is available..."

# Try apt install for system-wide fallback
if ! command -v ipython3 &> /dev/null; then
  echo "Attempting to install ipython3 via apt..."
  sudo apt update
  sudo apt install -y python3-ipython || echo "Warning: apt install failed. You may need to install IPython manually."
fi

# Check for conda-based installs
if command -v conda &> /dev/null; then
  echo "Conda detected. Ensuring IPython is installed via conda..."
  conda install -y ipython || echo "Warning: Conda install failed. Check your environment."
fi

# Create a symlink for 'ipython' if it's not already present
if ! command -v ipython &> /dev/null; then
  if command -v ipython3 &> /dev/null; then
    echo "Creating symlink for 'ipython' -> 'ipython3'"
    sudo ln -sf $(which ipython3) /usr/local/bin/ipython
  else
    echo "Warning: No 'ipython' or 'ipython3' detected. XTide86 may not function properly."
  fi
else
  echo "'ipython' is available."
fi

if command -v conda &> /dev/null; then
  echo "Conda detected. Checking for IPython..."
  if ! command -v ipython &> /dev/null && ! command -v ipython3 &> /dev/null; then
    conda install -y ipython || echo "Warning: Conda install failed. Check your environment."
  fi
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

# Install Neovim plugins
echo "Installing Neovim plugins..."
nvim +PlugInstall +qall

echo "XTide86 installed! You can now launch it from the app menu or by typing 'xtide86'."
