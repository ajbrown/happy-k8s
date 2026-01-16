# Claude Agents Container Image
# Runs Claude Code via Happy for persistent AI-assisted development
FROM ubuntu:24.04

ARG NODE_VERSION=22
ARG MAVEN_VERSION=3.9.9

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/home/agent
ENV WORKSPACE=/workspace

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    jq \
    openssh-client \
    ca-certificates \
    gnupg \
    sudo \
    python3 \
    python3-pip \
    python3-venv \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI (for running docker commands inside the container)
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

# Install Maven
RUN wget -q https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz -O /tmp/maven.tar.gz \
    && tar -xzf /tmp/maven.tar.gz -C /opt \
    && ln -s /opt/apache-maven-${MAVEN_VERSION} /opt/maven \
    && rm /tmp/maven.tar.gz

ENV MAVEN_HOME=/opt/maven
ENV PATH="${MAVEN_HOME}/bin:${PATH}"

# Create non-root user for running the agent
# Ubuntu 24.04 has a default 'ubuntu' user with UID 1000, so we rename it
RUN usermod -l agent -d /home/agent -m ubuntu \
    && groupmod -n agent ubuntu \
    && echo "agent ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install Claude Code CLI and Happy CLI globally (as root)
RUN npm install -g @anthropic-ai/claude-code happy-coder

# Create directories
RUN mkdir -p ${WORKSPACE} ${HOME}/.claude ${HOME}/.happy \
    && chown -R agent:agent ${WORKSPACE} ${HOME}

# Switch to non-root user
USER agent
WORKDIR ${HOME}

# Copy healthcheck and restart scripts
COPY --chown=agent:agent healthcheck.sh /healthcheck.sh
COPY --chown=agent:agent restart-watchdog.sh /restart-watchdog.sh
COPY --chown=agent:agent restart-trigger-server.sh /restart-trigger-server.sh
RUN chmod +x /healthcheck.sh /restart-watchdog.sh /restart-trigger-server.sh

# Set working directory to workspace
WORKDIR ${WORKSPACE}

# Default command - runs Happy with Claude
# The actual command will be configured via Kubernetes
CMD ["happy", "run"]
