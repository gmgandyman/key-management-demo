#!/usr/bin/bash

# ansible + galaxy collections   -> this box is the control node for the fleet
# openjdk-21-jre-headless        -> runs the Spring Boot API jar (headless: no AWT/Swing)
# openssh-client                 -> the API shells out to `ssh` for the live key push
# supervisor                     -> runs sshd + the API jar together as the entrypoint
apt-get install -y --no-install-recommends ansible \
  openssh-client \
  python3 \
  python3-pip \
  ca-certificates \
  supervisor \
  && ansible-galaxy collection install -p /usr/share/ansible/collections \
  community.general \
  community.postgresql \
  ansible.posix
