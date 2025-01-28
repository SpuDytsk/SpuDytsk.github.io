#!/bin/sh

CONTAINER_DIR=${CONTAINER_DIR:-"/opt/elecard/docs"}
CONTAINER_NAME=${CONTAINER_NAME:-"docs_builder"}
IMAGE_NAME=${IMAGE_NAME:="gitlab.elecard.net.ru:5050/boro/docs/doc-template/zendet-docs_builder:v1.0"}

if [ -n "$BUILD_IN_MULTIPLE" ]; then

  RELATIVE_PATH=$(realpath --relative-to=$DOCS_HOST_DIR $PWD)
  WORKDIR_PATH=$CONTAINER_DIR/$RELATIVE_PATH

  if [ "$OS" = "Windows_NT" ]; then
    WORKDIR_PATH=/$WORKDIR_PATH
  fi

  docker exec -tw $WORKDIR_PATH $CONTAINER_NAME make "$@"
else
  if [ "$OS" = "Windows_NT" ]; then
    PWD=/$PWD
    DOCKER="winpty docker"
  else
    DOCKER="docker"
  fi
  
  $DOCKER run \
    -ti --rm \
    --entrypoint "" \
    -h $(hostname) \
    -v $PWD:$CONTAINER_DIR \
    $IMAGE_NAME \
      make "$@"
fi
