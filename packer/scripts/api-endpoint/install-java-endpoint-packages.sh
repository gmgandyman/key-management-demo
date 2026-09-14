#!/usr/bin/bash

# openjdk-21-jre-headless        -> runs the Spring Boot API jar (headless: no AWT/Swing)
# openssh-client                 -> the API shells out to `ssh` for the live key push
# supervisor                     -> runs sshd + the API jar together as the entrypoint
apt-get install -y --no-install-recommends \
  openjdk-21-jre-headless \
  python3 \
  ca-certificates \
  openssh-client \
  supervisor \

