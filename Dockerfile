FROM openjdk:8-jdk
MAINTAINER Hatem Toumi

ENV ANDROID_TARGET_SDK="27" \
    ANDROID_SDK_BUILD_TOOLS="27.0.2" \
    ANDROID_HOME="/opt/android-sdk-linux"
ENV ANDROID_SDK_ROOT="$ANDROID_HOME"

ENV GRADLE_VERSION="4.5.1"
ENV GRADLE_HOME /opt/gradle/gradle-${GRADLE_VERSION}


# Update and Install Git and Maven and ftp-upload
RUN apt-get update && apt-get --assume-yes install -y zip unzip apt-utils wget git maven jq ruby-dev ruby-build


## Install Android SDK

# Install dependencies
RUN dpkg --add-architecture i386 && apt-get update && apt-get install -y --force-yes expect git wget libc6-i386 lib32stdc++6 lib32gcc1 lib32ncurses5 lib32z1 python curl libqt5widgets5 && apt-get clean && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add tools to path
ENV PATH ${PATH}:/opt/tools

# https://developer.android.com/studio/index.html#command-tools
ARG ANDROID_SDK_BUILD=3859397
ARG ANDROID_SDK_SHA256=444e22ce8ca0f67353bda4b85175ed3731cae3ffa695ca18119cbacef1c1bea0

RUN wget -q -O sdk-tools-linux.zip "https://dl.google.com/android/repository/sdk-tools-linux-${ANDROID_SDK_BUILD}.zip" \
    && echo "${ANDROID_SDK_SHA256} sdk-tools-linux.zip" | sha256sum -c \
    && unzip -C sdk-tools-linux.zip -d "${ANDROID_HOME}" \
    && rm *.zip

# Setup environment
ENV PATH ${ANDROID_HOME}/emulator:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools:${PATH}

RUN echo "Accepting licenses"; \
    yes | sdkmanager --licenses

RUN echo "Updating SDK"; \
    sdkmanager --update

RUN echo "Installing packages"; \
    sdkmanager --verbose \
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
    "lldb;3.0" \
    "cmake;3.6.4111459" \
    "emulator" \
####"system-images;android-${ANDROID_TARGET_SDK};google_apis;x86_64"

RUN echo "Installed packages"; \
    sdkmanager --list

# Create AVD
# RUN echo "Creating AVD"
# RUN echo n | avdmanager -v create avd -n pixel -k "system-images;android-$ANDROID_TARGET_SDK;google_apis;x86_64" -b x86_64 -d pixel

RUN which adb
RUN which android


## Install Gradle
#RUN sdk install gradle

RUN wget https://downloads.gradle.org/distributions/gradle-4.5.1-bin.zip
RUN ls -al
RUN mkdir /opt/gradle && unzip -d /opt/gradle gradle-${GRADLE_VERSION}-bin.zip

ENV PATH ${PATH}:${GRADLE_HOME}/bin
RUN gradle -v

## Install Fastlane
RUN gem install fastlane

# Cleaning
RUN apt-get clean

CMD tail -f /dev/null
