FROM ubuntu:22.04

# Setup timezone for cmake
RUN ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# The package dependencies are written in pubspec.yaml
WORKDIR /app
COPY . .

RUN apt-get update && apt-get install -y git vim curl unzip wget cmake libgtk-3-dev x11-apps wget gnupg xz-utils clang ninja-build pkg-config

# Install Chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && \
    apt-get install -y google-chrome-stable && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
ENV CHROME_EXECUTABLE /usr/bin/google-chrome-stable

# clone flutter
ENV FLUTTER_VERSION stable
ARG FLUTTER_SDK=/flutter
RUN git clone https://github.com/flutter/flutter.git $FLUTTER_SDK
RUN cd $FLUTTER_SDK && git fetch && git checkout $FLUTTER_VERSION
ENV PATH="${PATH}:$FLUTTER_SDK/bin:$FLUTTER_SDK/bin/cache/dart-sdk/bin"

# FIXME: androidのセットアップはまだ
RUN flutter channel $FLUTTER_VERSION && \
    flutter upgrade && \
    flutter config --enable-web && \
    flutter pub get && \
    flutter pub outdated

# Chromeはrootユーザーでの実行を推奨していないためユーザー作成
ARG USERNAME=flutteruser
RUN useradd -ms /bin/bash $USERNAME && \
    chown -R $USERNAME /flutter && \
    chown -R $USERNAME /app && \
    chown -R $USERNAME /var && \
    chmod -R 777 /app
USER $USERNAME
