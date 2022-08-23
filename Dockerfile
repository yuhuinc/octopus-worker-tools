FROM ubuntu:20.04

ARG POWERSHELL_VERSION=7.1.3\*
ARG NODEJS_VERSION=16


SHELL ["/bin/bash", "-eux", "-o", "pipefail", "-c"]

# Do not include CMD or ENTRYPOINT directives.
# These will cause Octopus Deploy steps to fail.

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
        apt-transport-https \
        curl \
        software-properties-common \
        unzip \
        wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    curl -fsSL https://get.pulumi.com | sh

RUN wget -O- https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | tee /usr/share/keyrings/yarnpkg-archive-keyring.gpg ; \
    echo "deb [signed-by=/usr/share/keyrings/yarnpkg-archive-keyring.gpg] https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list ; \
    curl -fsSL https://deb.nodesource.com/setup_${NODEJS_VERSION}.x | bash - && \
    apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    nodejs \
    yarn && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* ; \
    if [ "_$(uname -m)_" == "_aarch64_" ] ; then \
      echo "Arm architecture"; \
      curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip" ; \
    else \
      echo "x86_64 architecture"; \
      curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" ; \
    fi; \
    unzip awscliv2.zip ; \
    ./aws/install ; \
    rm -rf ./aws awscliv2.zip

ENV PATH="/root/.pulumi/bin:$PATH"

# Powershell core
# https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-7.1#ubuntu-2004
RUN if [ "_$(uname -m)_" == "_x86_64_" ] ; then \
        curl -LO -k "https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb" && \
        dpkg -i packages-microsoft-prod.deb && \
        apt-get update && \
        add-apt-repository universe && \
        apt-get install -y --no-install-recommends \
            powershell=${POWERSHELL_VERSION} && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/* && \
        rm -f packages-microsoft-prod.deb ; \
    else \
        echo "Not installing Powershell core ${POWERSHELL_VERSION}" ; \
        echo "Build using x86_64 architecture to work with Octopus Deploy." ; \
    fi
