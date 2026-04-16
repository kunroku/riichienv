# CUDA + Python + Rust + Node.js devcontainer for riichienv
FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

ARG DEBIAN_FRONTEND=noninteractive
ARG NODE_VERSION=22
ARG RUST_VERSION=1.92.0

# --------------------------------------------------------------------------- #
# System packages
# --------------------------------------------------------------------------- #
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        clang \
        curl \
        git \
        git-lfs \
        jq \
        less \
        libssl-dev \
        lsb-release \
        pkg-config \
        sudo \
        unzip \
        wget \
        zsh \
    && rm -rf /var/lib/apt/lists/*

# --------------------------------------------------------------------------- #
# GitHub CLI
# --------------------------------------------------------------------------- #
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
        https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# --------------------------------------------------------------------------- #
# starship prompt
# --------------------------------------------------------------------------- #
RUN curl -fsSL https://starship.rs/install.sh | sh -s -- --yes

# --------------------------------------------------------------------------- #
# Python (via deadsnakes PPA) + uv
# --------------------------------------------------------------------------- #
RUN apt-get update \
    && apt-get install -y --no-install-recommends software-properties-common \
    && add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        python3.12 python3.12-dev python3.12-venv python3-pip \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 10 \
    && update-alternatives --install /usr/bin/python  python  /usr/bin/python3.12 10 \
    && rm -rf /var/lib/apt/lists/*

RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && ln -s /root/.local/bin/uv /usr/local/bin/uv \
    && ln -s /root/.local/bin/uvx /usr/local/bin/uvx

# --------------------------------------------------------------------------- #
# Rust (rustup)
# --------------------------------------------------------------------------- #
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
        sh -s -- -y \
            --no-modify-path \
            --default-toolchain ${RUST_VERSION} \
            --component rustfmt \
            --component clippy \
            --target wasm32-unknown-unknown \
    && chmod -R a+w ${RUSTUP_HOME} ${CARGO_HOME}

# wasm-pack (needed for ui build)
RUN curl https://rustwasm.github.io/wasm-pack/installer/init.sh -sSf | sh

# --------------------------------------------------------------------------- #
# Node.js (via NodeSource) + npm tools
# --------------------------------------------------------------------------- #
ARG BIOME_VERSION=2.4.6
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g @biomejs/biome@${BIOME_VERSION}

# nvm is installed per-user in post-create; system Node is just a fallback.

# --------------------------------------------------------------------------- #
# zsh configuration skeleton (applied to any user)
# --------------------------------------------------------------------------- #
COPY zshrc-additions.sh /etc/zshrc-additions.sh
RUN chmod +x /etc/zshrc-additions.sh \
    && echo '\n# ---- devcontainer additions ----\nsource /etc/zshrc-additions.sh' >> /etc/zsh/zshrc

# --------------------------------------------------------------------------- #
# Default shell
# --------------------------------------------------------------------------- #
RUN chsh -s /bin/zsh root

WORKDIR /workspace

CMD ["/bin/zsh"]
