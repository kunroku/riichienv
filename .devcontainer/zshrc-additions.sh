#!/usr/bin/env zsh
# /etc/zshrc-additions.sh
# Sourced at the end of /etc/zsh/zshrc for every interactive zsh session.

# ---- Rust / Cargo ----
export RUSTUP_HOME=/usr/local/rustup
export CARGO_HOME=/usr/local/cargo
export PATH="$CARGO_HOME/bin:$PATH"

# ---- uv ----
export PATH="$HOME/.local/bin:$PATH"

# ---- nvm (installed by post-create) ----
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    source "$NVM_DIR/nvm.sh"
    # Auto-use version from .nvmrc when entering a directory
    autoload -U add-zsh-hook
    load-nvmrc() {
        local nvmrc_path
        nvmrc_path="$(nvm_find_nvmrc)"
        if [[ -n "$nvmrc_path" ]]; then
            local nvmrc_node_version
            nvmrc_node_version=$(nvm version "$(cat "$nvmrc_path")")
            if [[ "$nvmrc_node_version" == "N/A" ]]; then
                nvm install
            elif [[ "$nvmrc_node_version" != "$(nvm version)" ]]; then
                nvm use
            fi
        fi
    }
    add-zsh-hook chpwd load-nvmrc
    load-nvmrc
fi

# ---- Python venv auto-activation ----
autoload -U add-zsh-hook
_auto_venv() {
    local venv_path
    # Walk up from cwd looking for a .venv
    venv_path=""
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/.venv/bin/activate" ]]; then
            venv_path="$dir/.venv"
            break
        fi
        dir="$(dirname "$dir")"
    done

    if [[ -n "$venv_path" ]]; then
        if [[ "$VIRTUAL_ENV" != "$venv_path" ]]; then
            source "$venv_path/bin/activate"
        fi
    else
        # Deactivate if we've left all venv-containing directories
        if [[ -n "$VIRTUAL_ENV" ]]; then
            deactivate 2>/dev/null || true
        fi
    fi
}
add-zsh-hook chpwd _auto_venv
_auto_venv  # run once on shell start

# ---- starship prompt ----
if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
fi
