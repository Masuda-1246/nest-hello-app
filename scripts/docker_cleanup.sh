#!/bin/bash

set -e

LOGFILE=/home/ec2-user/docker_cleanup.log

echo "Starting docker_cleanup.sh" > $LOGFILE

# 古いコンテナを停止して削除
if docker ps -q --filter "name=myapp-container" | grep -q .; then
  echo "Stopping and removing container myapp-container" >> $LOGFILE
  docker stop myapp-container >> $LOGFILE 2>&1 || { echo "Failed to stop container" >> $LOGFILE; exit 1; }
  docker rm myapp-container >> $LOGFILE 2>&1 || { echo "Failed to remove container" >> $LOGFILE; exit 1; }
else
  echo "No container named myapp-container running" >> $LOGFILE
fi

# 古いイメージを削除
if docker images -q myapp-image | grep -q .; then
  echo "Removing image myapp-image" >> $LOGFILE
  docker rmi -f $(docker images -q myapp-image) >> $LOGFILE 2>&1 || { echo "Failed to remove image" >> $LOGFILE; exit 1; }
else
  echo "No image named myapp-image found" >> $LOGFILE
fi

echo "docker_cleanup.sh completed" >> $LOGFILE
