#!/usr/bin/env bash
# .devcontainer/devcontainer-post-create.sh
# Runs once after the container is created (postCreateCommand).
set -euo pipefail

WORKSPACE=/workspace

echo "==> [post-create] Starting devcontainer setup..."

# --------------------------------------------------------------------------- #
# 1. zsh history: redirect to persistent volume so history survives recreates
# --------------------------------------------------------------------------- #
HIST_VOL=/root/.zsh_history_vol
HIST_FILE="$HIST_VOL/.zsh_history"
mkdir -p "$HIST_VOL"
touch "$HIST_FILE"
if ! grep -q 'HISTFILE=' /root/.zshrc 2>/dev/null; then
    cat >> /root/.zshrc <<'ZSHRC'

# ---- persistent history (devcontainer) ----
HISTFILE=/root/.zsh_history_vol/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE
ZSHRC
fi

# --------------------------------------------------------------------------- #
# 2. nvm + Node.js
# --------------------------------------------------------------------------- #
echo "==> [post-create] Installing nvm..."
export NVM_DIR="$HOME/.nvm"
if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi
# shellcheck source=/dev/null
source "$NVM_DIR/nvm.sh"

# Determine requested Node version (.nvmrc or fallback to LTS)
NODE_VER="lts/*"
if [[ -f "$WORKSPACE/ui/.nvmrc" ]]; then
    NODE_VER="$(cat "$WORKSPACE/ui/.nvmrc")"
fi
echo "==> [post-create] Installing Node ${NODE_VER}..."
nvm install "$NODE_VER"
nvm alias default "$NODE_VER"
nvm use default

# --------------------------------------------------------------------------- #
# 3. Rust toolchain pin (rust-toolchain.toml already present)
# --------------------------------------------------------------------------- #
echo "==> [post-create] Syncing Rust toolchain..."
export RUSTUP_HOME=/usr/local/rustup
export CARGO_HOME=/usr/local/cargo
export PATH="$CARGO_HOME/bin:$PATH"
# rustup reads rust-toolchain.toml automatically; run `rustup show` to install
(cd "$WORKSPACE" && rustup show)

# --------------------------------------------------------------------------- #
# 4. Python virtual environment
# --------------------------------------------------------------------------- #
echo "==> [post-create] Setting up Python venv..."
cd "$WORKSPACE"
if [[ ! -f .venv/bin/activate ]]; then
    uv venv .venv --python python3.12
fi
# shellcheck source=/dev/null
source .venv/bin/activate

# Install project + dev dependencies via uv
echo "==> [post-create] Installing Python dependencies..."
uv sync --group dev --index https://download.pytorch.org/whl/cu124 || \
    uv sync --group dev

# Install ml dependencies if the sub-package exists
if [[ -f ml/pyproject.toml ]]; then
    echo "==> [post-create] Installing ml dependencies..."
    uv pip install -e ml --extra-index-url https://download.pytorch.org/whl/cu124 || \
        uv pip install -e ml
fi

# pre-commit hooks
if command -v pre-commit &>/dev/null; then
    echo "==> [post-create] Installing pre-commit hooks..."
    pre-commit install --install-hooks || true
fi

# --------------------------------------------------------------------------- #
# 5. Node.js dependencies for ui
# --------------------------------------------------------------------------- #
if [[ -f "$WORKSPACE/ui/package.json" ]]; then
    echo "==> [post-create] Installing Node dependencies (ui)..."
    cd "$WORKSPACE/ui"
    npm ci --prefer-offline 2>/dev/null || npm install
    cd "$WORKSPACE"
fi

# --------------------------------------------------------------------------- #
# 6. Ensure /data/riichienv mount point exists
# --------------------------------------------------------------------------- #
mkdir -p /data/riichienv

# --------------------------------------------------------------------------- #
# 7. starship config (if not already present)
# --------------------------------------------------------------------------- #
STARSHIP_CFG="$HOME/.config/starship.toml"
if [[ ! -f "$STARSHIP_CFG" ]]; then
    mkdir -p "$(dirname "$STARSHIP_CFG")"
    cat > "$STARSHIP_CFG" <<'TOML'
# Starship config for riichienv devcontainer
"$schema" = 'https://starship.rs/config-schema.json'

format = """
$username\
$directory\
$git_branch\
$git_state\
$git_status\
$python\
$rust\
$nodejs\
$line_break\
$character"""

[directory]
truncation_length = 4
truncate_to_repo = true

[git_branch]
format = "[$symbol$branch]($style) "
symbol = " "

[git_status]
format = '([\[$all_status$ahead_behind\]]($style) )'

[python]
format = '([${symbol}${pyenv_prefix}(${version} )(\($virtualenv\) )]($style))'
symbol = " "

[rust]
format = "[$symbol$version]($style) "
symbol = " "

[nodejs]
format = "[$symbol$version]($style) "
symbol = " "
TOML
fi

echo "==> [post-create] Done! Container is ready."
