FROM ubuntu:22.04

# Setup timezone for cmake
RUN ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# The package dependencies are written in pubspec.yaml
WORKDIR /app
COPY . .

RUN apt-get update && apt-get install -y git vim curl unzip wget cmake libgtk-3-dev x11-apps wget gnupg xz-utils clang ninja-build pkg-config

# Install Chrome
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-linux-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-linux-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && \
    apt-get install -y google-chrome-stable && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
ENV CHROME_EXECUTABLE=/usr/bin/google-chrome-stable
    
# clone flutter
ENV FLUTTER_VERSION=stable
ARG FLUTTER_SDK=/flutter
RUN git clone https://github.com/flutter/flutter.git $FLUTTER_SDK
RUN cd $FLUTTER_SDK && git fetch && git checkout $FLUTTER_VERSION
ENV PATH="${PATH}:$FLUTTER_SDK/bin:$FLUTTER_SDK/bin/cache/dart-sdk/bin"

# Install ROS2 and rosbridge_suite
RUN apt-get update && apt-get install -y locales
RUN locale-gen en_US en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Setup sources.list
RUN apt-get update && apt-get install -y curl gnupg2 lsb-release
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -
RUN sh -c 'echo "deb http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" > /etc/apt/sources.list.d/ros2-latest.list'

# Install ROS2 packages
RUN apt-get update && apt-get install -y \
    ros-foxy-desktop \
    python3-rosdep \
    python3-argcomplete \
    ros-foxy-rosbridge-server

# Initialize rosdep
RUN rosdep init && rosdep update

# Source ROS2 setup script
SHELL ["/bin/bash", "-c"]
RUN echo "source /opt/ros/foxy/setup.bash" >> ~/.bashrc
RUN /bin/bash -c "source ~/.bashrc"

# FIXME: androidの設定が必要
RUN flutter channel $FLUTTER_VERSION && \
    flutter upgrade && \
    flutter config --enable-web && \
    flutter pub get && \
    flutter pub outdated

# Chromeをrootユーザーで実行するための設定
ARG USERNAME=flutteruser
RUN useradd -ms /bin/bash $USERNAME && \
    chown -R $USERNAME /flutter && \
    chown -R $USERNAME /app && \
    chown -R $USERNAME /var && \
    chmod -R 777 /app
USER $USERNAME

# Start rosbridge server
CMD ["ros2", "launch", "rosbridge_server", "rosbridge_websocket_launch.xml"]