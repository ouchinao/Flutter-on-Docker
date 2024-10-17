FROM ubuntu:22.04

# Setup timezone
RUN ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# Set working directory
WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa

# Install Flutter
ENV FLUTTER_VERSION=stable
ARG FLUTTER_SDK=/flutter
RUN git config --global http.postBuffer 524288000 && \
    git clone https://github.com/flutter/flutter.git $FLUTTER_SDK
RUN cd $FLUTTER_SDK && git fetch && git checkout $FLUTTER_VERSION
ENV PATH="${PATH}:$FLUTTER_SDK/bin"

# Setup non-root user
ARG USERNAME=flutteruser
RUN useradd -ms /bin/bash $USERNAME && \
    chown -R $USERNAME /flutter && \
    chown -R $USERNAME /app

# Switch to non-root user
USER $USERNAME
WORKDIR /app

# Enable Flutter web
RUN flutter channel $FLUTTER_VERSION && \
    flutter upgrade && \
    flutter config --enable-web

# Default command
CMD ["/bin/bash"]