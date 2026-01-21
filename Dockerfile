# Wind Lens Development Container
# Flutter + Claude Code with full permissions

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install base dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    wget \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev \
    liblzma-dev \
    libstdc++-12-dev \
    openjdk-17-jdk \
    ca-certificates \
    gnupg \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20.x (required for Claude Code)
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user (required for --dangerously-skip-permissions)
RUN useradd -m -s /bin/bash developer \
    && echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install Flutter as developer user
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="$FLUTTER_HOME/bin:$PATH"

RUN mkdir -p $FLUTTER_HOME && chown developer:developer $FLUTTER_HOME

USER developer
RUN git clone https://github.com/flutter/flutter.git -b stable $FLUTTER_HOME \
    && flutter precache \
    && flutter config --no-analytics \
    && dart --disable-analytics

# Switch back to root for npm install
USER root

# Install Claude Code globally via npm
RUN npm install -g @anthropic-ai/claude-code

# Create convenience alias for claude with skip permissions
RUN echo 'alias yolo="claude --dangerously-skip-permissions"' >> /home/developer/.bashrc
RUN echo 'echo "🚀 Wind Lens Dev Container Ready"' >> /home/developer/.bashrc
RUN echo 'echo "   Run: yolo    (launches Claude Code with full permissions)"' >> /home/developer/.bashrc
RUN echo 'echo "   Run: flutter doctor    (check Flutter setup)"' >> /home/developer/.bashrc
RUN echo 'echo ""' >> /home/developer/.bashrc

# Set up workspace
WORKDIR /workspace
RUN chown developer:developer /workspace

# Switch to non-root user
USER developer

# Set up user directories for Claude config
RUN mkdir -p /home/developer/.claude /home/developer/.config/claude-code

# Default to bash shell
ENTRYPOINT ["/bin/bash"]
