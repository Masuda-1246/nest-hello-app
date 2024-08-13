#!/bin/bash

set -e

ROOT_DIR=/home/ec2-user/nest-hello-app
LOGFILE=/home/ec2-user/docker_cleanup.log


# ディレクトリとファイルの権限を設定
sudo chown -R ec2-user:ec2-user $ROOT_DIR
sudo touch $LOGFILE
sudo chown ec2-user:ec2-user $LOGFILE
sudo chmod 644 $LOGFILE

echo "Starting docker_cleanup.sh" >> $LOGFILE

# ルートディレクトリを削除
if [ -d $ROOT_DIR ]; then
  echo "Removing directory $ROOT_DIR" >> $LOGFILE
  echo "Removing directory $ROOT_DIR"
  rm -rf $ROOT_DIR >> $LOGFILE 2>&1 || { echo "Failed to remove directory" >> $LOGFILE;}
else
  echo "No directory $ROOT_DIR found" >> $LOGFILE
  echo "No directory $ROOT_DIR found"
fi

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
