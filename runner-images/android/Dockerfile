# Runner image for the "infra-android-heavy" ARC scale-set
# (cluster/services/actions-runner-scale-set-android). Preinstalls everything
# build-submit-android.yml would otherwise install on every run: Java 17,
# Node/pnpm, Android SDK + NDK, eas-cli + eas-cli-local-build-plugin.
#
# Android SDK/NDK/cmake are lifted from react-native-community/docker-android
# (battle-tested, actively maintained) instead of hand-rolled sdkmanager calls.
# Pin bumped from https://github.com/react-native-community/docker-android/releases
#
# Assumes amd64 k3s nodes (standard Hetzner instances). If your nodes are ARM
# (Hetzner CAX), swap "x64"/"linux-x64" for "aarch64"/"linux-arm64" below.

FROM reactnativecommunity/react-native-android:v21.0 AS android-tools

FROM ghcr.io/actions/actions-runner:latest

USER root

ARG NODE_VERSION=20.18.1
ARG PNPM_VERSION=9.15.0

# curl/unzip/ca-certificates: needed for the manual downloads below.
# gcc/g++/make/ninja-build/python3/ccache/patch/rsync/git: needed to actually
# invoke the NDK/cmake toolchain copied from android-tools (CMake configure
# steps, Hermes compilation, etc). If a build later fails with a missing
# shared library error (e.g. "libc++.so.1: cannot open shared object file"),
# install the matching package here — the community image installs several
# more (libc++, libgl1, libtcmalloc-minimal4, libicu-dev) that Ubuntu 24.04
# may package under different names than on their Ubuntu 22.04 base.
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl \
      ca-certificates \
      unzip \
      xz-utils \
      gcc \
      g++ \
      make \
      ninja-build \
      ccache \
      patch \
      rsync \
      python3 \
      git \
    && rm -rf /var/lib/apt/lists/*

# ---------- Java (Temurin 17, matches actions/setup-java in the workflow) ----------
# Official Adoptium API: always resolves to the latest JDK 17 GA build for linux/x64.
RUN curl -fsSL "https://api.adoptium.net/v3/binary/latest/17/ga/linux/x64/jdk/hotspot/normal/eclipse" \
      -o /tmp/temurin17.tar.gz \
    && mkdir -p /opt/java/temurin-17 \
    && tar -xzf /tmp/temurin17.tar.gz -C /opt/java/temurin-17 --strip-components=1 \
    && rm /tmp/temurin17.tar.gz

ENV JAVA_HOME=/opt/java/temurin-17
ENV PATH=${JAVA_HOME}/bin:${PATH}

# ---------- Node.js + pnpm (official nodejs.org tarball, no third-party script) ----------
RUN curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
      -o /tmp/node.tar.xz \
    && mkdir -p /opt/node \
    && tar -xJf /tmp/node.tar.xz -C /opt/node --strip-components=1 \
    && rm /tmp/node.tar.xz

ENV PATH=/opt/node/bin:${PATH}

# Plain npm install, not corepack: corepack (as bundled with this Node
# version) fails signature verification against npm's rotated registry
# signing key ("Cannot find matching keyid").
RUN npm install -g pnpm@${PNPM_VERSION} yarn

# ---------- Android SDK + NDK + cmake, copied from react-native-community/docker-android ----------
ENV ANDROID_HOME=/opt/android
ENV ANDROID_SDK_ROOT=${ANDROID_HOME}
ENV ANDROID_NDK_HOME=${ANDROID_HOME}/ndk/27.1.12297006
ENV REACT_NATIVE_DOWNLOADS_DIR=/opt/react-native-downloads
ENV PATH=${ANDROID_HOME}/cmake/3.30.5/bin:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}

COPY --from=android-tools /opt/android /opt/android
# Pre-fetched RN native C++ deps (boost, folly, glog, ...) so Gradle doesn't
# re-download them on every ephemeral runner pod.
COPY --from=android-tools /opt/react-native-downloads /opt/react-native-downloads

# The upstream image ships platforms;android-37.0 / build-tools;37.0.0 by
# default. compileSdkVersion=35 / buildToolsVersion=35.0.0 come from the
# defaults set by ExpoRootProjectPlugin.kt (expo-modules-autolinking) — the
# actual plugin apps/mobile/android/build.gradle applies as "expo-root-project" —
# and apps/mobile has no gradle/libs.versions.toml overriding them. Re-check
# these two values if that ever changes.
RUN sdkmanager \
      "platforms;android-35" \
      "build-tools;35.0.0"

# ---------- Global CLI tools used by build-submit-android.yml ----------
RUN npm install -g eas-cli eas-cli-local-build-plugin

RUN chown -R runner:runner /opt/android /opt/react-native-downloads /opt/node /opt/java \
    && git config --system --add safe.directory '*'

USER runner

# Fail the build immediately if any tool is broken, instead of on the first real job.
RUN java -version && node -v && pnpm -v && yarn -v && sdkmanager --version && eas --version
