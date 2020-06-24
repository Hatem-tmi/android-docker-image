FROM openjdk:8-jdk
MAINTAINER Hatem Toumi

## ANDROID_SDK_BUILD_TOOLS: '29.0.2 or higher' corresponding to android gradle plugin v4.0.0
ENV ANDROID_TARGET_SDK="29" \
    ANDROID_SDK_BUILD_TOOLS="29.0.2" \
    ANDROID_HOME="/opt/android-sdk-linux" \
    KOTLIN_HOME="/opt/kotlinc"
ENV ANDROID_SDK_ROOT="$ANDROID_HOME"

ENV GRADLE_VERSION="6.1.1"
ENV GRADLE_HOME /opt/gradle/gradle-${GRADLE_VERSION}


# Update and Install Git and Maven and ftp-upload
RUN apt-get update && apt-get --assume-yes install -y zip unzip apt-utils wget git maven jq ruby-dev ruby-build


## Install Android SDK

# Install dependencies:
# support multiarch: i386 architecture
# install essential tools
# install Qt
RUN dpkg --add-architecture i386 && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends libncurses5:i386 libc6:i386 libstdc++6:i386 lib32gcc1 lib32ncurses6 lib32z1 zlib1g:i386 && \
    apt-get install -y --no-install-recommends git wget unzip && \
    apt-get install -y --no-install-recommends qt5-default && \
    apt-get clean && \
    rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*

# download and install Kotlin compiler
# https://github.com/JetBrains/kotlin/releases/latest
ARG KOTLIN_VERSION=1.3.72
RUN cd /opt && \
    wget -q https://github.com/JetBrains/kotlin/releases/download/v${KOTLIN_VERSION}/kotlin-compiler-${KOTLIN_VERSION}.zip && \
    unzip *kotlin*.zip && \
    rm *kotlin*.zip

# Add tools to path
ENV PATH ${PATH}:/opt/tools

# Download and Install Linux Android SDK Tools - https://developer.android.com/studio/index.html#command-tools
ARG ANDROID_SDK_BUILD=6514223
ARG ANDROID_SDK_SHA256=ef319a5afdb41822cb1c88d93bc7c23b0af4fc670abca89ff0346ee6688da797

RUN wget -q -O sdk-tools-linux.zip "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_BUILD}_latest.zip" \
    && echo "${ANDROID_SDK_SHA256} sdk-tools-linux.zip" | sha256sum -c \
    && unzip -C sdk-tools-linux.zip -d "${ANDROID_HOME}" \
    && rm *.zip

# Setup environment
ENV PATH ${PATH}:${KOTLIN_HOME}/bin:${ANDROID_HOME}/cmdline-tools/tools/bin:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/emulator
ENV _JAVA_OPTIONS -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap

RUN echo "Accepting licenses"; \
    yes | sdkmanager --sdk_root=${ANDROID_HOME} --licenses

RUN echo "Updating SDK"; \
    sdkmanager --sdk_root=${ANDROID_HOME} --update

RUN echo "Installing packages"; \
    sdkmanager --sdk_root=${ANDROID_HOME} --no_https --verbose \
    "platforms;android-${ANDROID_TARGET_SDK}" \
    "build-tools;${ANDROID_SDK_BUILD_TOOLS}" \
    "platform-tools"  \
    "add-ons;addon-google_apis-google-24" \
    "extras;android;m2repository" \
    "extras;google;m2repository" \
    "extras;google;google_play_services" \
    "extras;google;market_apk_expansion" \
    "extras;google;market_licensing" \
    "ndk-bundle" \
    "cmake;3.6.4111459" \
    "emulator"
####"lldb;3.0" \
####"system-images;android-${ANDROID_TARGET_SDK};google_apis;x86_64"

RUN echo "Installed packages"; \
    sdkmanager --sdk_root=${ANDROID_HOME} --list

# Create AVD
# RUN echo "Creating AVD"
# RUN echo n | avdmanager -v create avd -n pixel -k "system-images;android-$ANDROID_TARGET_SDK;google_apis;x86_64" -b x86_64 -d pixel

RUN which adb


## Install Gradle
#RUN sdk install gradle

RUN wget https://downloads.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip
RUN ls -al
RUN mkdir /opt/gradle && unzip -d /opt/gradle gradle-${GRADLE_VERSION}-bin.zip

ENV PATH ${PATH}:${GRADLE_HOME}/bin
RUN gradle -v

## Install Fastlane
RUN gem install fastlane

# Cleaning
RUN apt-get clean

CMD tail -f /dev/null
