FROM gitpod/workspace-base
USER root

# Elixir 
RUN wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb \
    && sudo dpkg -i erlang-solutions_2.0_all.deb \
    && apt update \
    && install-packages \
        esl-erlang \
    && install-packages \
        elixir


# Rust
RUN curl -s https://packagecloud.io/install/repositories/wasmcloud/core/script.deb.sh | bash && \
    apt update && \
    install-packages wash zsh inotify-tools
USER gitpod
RUN cp /home/gitpod/.profile /home/gitpod/.profile_orig && \
    curl -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain stable \
    && .cargo/bin/rustup component add \
        rust-analysis \
        rust-src \
        rustfmt \
    && .cargo/bin/rustup completions bash | sudo tee /etc/bash_completion.d/rustup.bash-completion > /dev/null \
    && .cargo/bin/rustup completions bash cargo | sudo tee /etc/bash_completion.d/rustup.cargo-bash-completion > /dev/null \
    && grep -v -F -x -f /home/gitpod/.profile_orig /home/gitpod/.profile > /home/gitpod/.bashrc.d/80-rust
ENV PATH=$PATH:$HOME/.cargo/bin
# share env see https://github.com/gitpod-io/workspace-images/issues/472
RUN echo "PATH="${PATH}"" | sudo tee /etc/environment
RUN rustup target add wasm32-unknown-unknown

# Node
RUN curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | PROFILE=/dev/null bash \
    && bash -c ". .nvm/nvm.sh \
        && nvm install v16 \
        && nvm alias default v16 \
        && npm install -g typescript yarn pnpm node-gyp" \
    && echo ". ~/.nvm/nvm-lazy.sh"  >> /home/gitpod/.bashrc.d/50-node
# above, we are adding the lazy nvm init to .bashrc, because one is executed on interactive shells, the other for non-interactive shells (e.g. plugin-host)
COPY --chown=gitpod:gitpod nvm-lazy.sh /home/gitpod/.nvm/nvm-lazy.sh
ENV PATH=/home/gitpod/.nvm/versions/node/v16/bin:$PATH


USER gitpod

# Go ahead and install hex and rebar for building the phoenix apps
RUN mix local.hex --force
RUN mix local.rebar --force