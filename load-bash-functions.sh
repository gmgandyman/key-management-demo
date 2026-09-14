#!/usr/bin/bash

# You must have a .env for this to work. See env.example
if [ ! -f ".env" ]; then
    echo "Error: File '.env' not found. Please copy env.example to .env"
    return 1
fi


# Get the env variables into the environment of the terminal
set -a
source .env
set +a

start-toolbox() {
  docker compose run --rm --build $TOOLBOX_SERVICE_NAME bash
}

reset-to-blank() {
  docker compose down --volumes
  docker image rm $TOOLBOX_IMAGE_NAME:$IMAGE_TAG
  docker image rm $BASE_IMAGE_NAME:$IMAGE_TAG
  docker image rm $POSTGRES_IMAGE_NAME:$IMAGE_TAG
}
