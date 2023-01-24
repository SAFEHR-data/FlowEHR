#  Copyright (c) University College London Hospitals NHS Foundation Trust
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
# limitations under the License.
# You can pick any Debian/Ubuntu-based image. 😊
FROM mcr.microsoft.com/vscode/devcontainers/python:3.10

COPY library-scripts/*.sh /tmp/library-scripts/

# [Option] Install zsh
ARG INSTALL_ZSH="true"
# [Option] Upgrade OS packages to their latest versions
ARG UPGRADE_PACKAGES="false"

# Install needed packages and setup non-root user. Use a separate RUN statement to add your own dependencies.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && bash /tmp/library-scripts/common-debian.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" "true" "true" \ 
    && apt-get install -y graphviz --no-install-recommends \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# [Option] Install Docker CLI
ARG INSTALL_DOCKER="true"

RUN if [ "${INSTALL_DOCKER}" = "true" ]; then \
        bash /tmp/library-scripts/docker-debian.sh "true" "/var/run/docker-host.sock" "/var/run/docker.sock" "${USERNAME}"; \
    else \
        printf '#!/bin/bash\n"$@"' > /usr/local/share/docker-init.sh && chmod +x /usr/local/share/docker-init.sh; \
    fi \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js for GH actions tests
ARG NODE_VERSION="lts/*"
RUN su $USERNAME -c "umask 0002 && . /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"

ENTRYPOINT [ "/usr/local/share/docker-init.sh" ]
CMD [ "sleep", "infinity" ]

# Install additional tools
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends yamllint

ARG YQ_VERSION="v4.30.6"
RUN export ARCH=$(dpkg --print-architecture); curl -L --fail -o /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${ARCH}" \
    && chmod +x /usr/local/bin/yq

ARG SC_VERSION="v0.9.0"
RUN export ARCH="$(dpkg --print-architecture)"; \
    if [ "$ARCH" = arm64 ]; then export ARCH=aarch64; fi; \
    if [ "$ARCH" = amd64 ]; then export ARCH=x86_64; fi; \
    wget -qO- "https://github.com/koalaman/shellcheck/releases/download/${SC_VERSION}/shellcheck-${SC_VERSION}.linux.${ARCH}.tar.xz" | tar -xJv \
    && cp "shellcheck-${SC_VERSION}/shellcheck" /usr/local/bin/

ARG PAJV_VERSION="1.2.0"
RUN npm install -g pajv@${PAJV_VERSION}

ARG PRECOMMIT_VERSION="2.21.0"
RUN pip3 install pre-commit=="${PRECOMMIT_VERSION}" --no-cache-dir
