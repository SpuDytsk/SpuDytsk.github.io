#!/bin/sh

CONTAINER_DIR=${CONTAINER_DIR:-"/opt/elecard/docs"}
CONTAINER_NAME=${CONTAINER_NAME:-"docs_builder"}
IMAGE_NAME=${IMAGE_NAME:="gitlab.elecard.net.ru:5050/boro/docs/doc-template/zendet-docs_builder:v1.0"}

if docker ps --format '{{.Names}}' | grep -q "$CONTAINER_NAME"; then
  echo "Container '$CONTAINER_NAME' already been started!"
  exit 1
fi

if [ -n "$BUILD_IN_MULTIPLE" ]; then
  DOCS_HOST_DIR=$(realpath $DOCS_HOST_DIR)

  if [ "$OS" = "Windows_NT" ]; then
    DOCS_HOST_DIR=/$DOCS_HOST_DIR
  fi

  docker run \
  -h $(hostname) \
  -di \
  --init \
  --restart always \
  -v $DOCS_HOST_DIR:$CONTAINER_DIR \
  --name $CONTAINER_NAME \
  $IMAGE_NAME

  echo "Container started!"
fi
