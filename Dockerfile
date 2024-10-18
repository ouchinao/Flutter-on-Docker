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

# install Edge
RUN apt-get install -y software-properties-common apt-transport-https wget
RUN wget -q https://packages.microsoft.com/keys/microsoft.asc -O /etc/apt/trusted.gpg.d/microsoft.asc
RUN add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main"
RUN apt-get install -y microsoft-edge-stable

# install ROS2
RUN apt-get install software-properties-common
RUN add-apt-repository universe
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" > /etc/apt/sources.list.d/ros2.list
RUN apt-get update
RUN apt-get upgrade
RUN apt-get install -y ros-humble-desktop
RUN apt-get install -y ros-dev-tools

RUN apt-get -y install gazebo
RUN apt-get install -y ros-humble-gazebo-*
RUN apt-get install -y ros-humble-rqt-*
RUN apt-get install -y python3-colcon-common-extensions

RUN echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
RUN echo "source /usr/share/colcon_cd/function/colcon_cd.sh" >> ~/.bashrc
RUN echo "export _colcon_cd_root=/opt/ros/humble/" >> ~/.bashrc
RUN echo "source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash" >> ~/.bashrc

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