#!/bin/bash

set -e

ROOT_DIR=/home/ec2-user/myapp
LOGFILE=$ROOT_DIR/deploy.log


# ディレクトリとファイルの権限を設定
sudo chown -R ec2-user:ec2-user $ROOT_DIR
sudo touch $LOGFILE
sudo chown ec2-user:ec2-user $LOGFILE
sudo chmod 644 $LOGFILE

echo "Starting deployment script" > $LOGFILE
echo "Starting deployment script"

# 必要な環境変数をSSM Parameter Storeから取得して.envファイルを作成
PARAMETER_NAMES=(
  "/myapp/MESSAGE"
)

echo "Creating .env file..." >> $LOGFILE
echo "Creating .env file..."

# .envファイルをバックアップし、後で新しい内容で上書きする
if [ -f $ROOT_DIR/.env ]; then
  cp $ROOT_DIR/.env $ROOT_DIR/.env.bak
fi

# 新しい内容で.envファイルを作成
for PARAM in "${PARAMETER_NAMES[@]}"; do
  KEY=$(echo $PARAM | awk -F'/' '{print $NF}')
  VALUE=$(aws ssm get-parameter --name $PARAM --with-decryption --query "Parameter.Value" --output text 2>> $LOGFILE)
  if [ $? -ne 0 ]; then
    echo "Failed to get parameter: $PARAM" >> $LOGFILE
    echo "Failed to get parameter: $PARAM"
    echo "Restoring from backup..." >> $LOGFILE
    echo "Restoring from backup..."
    if [ -f $ROOT_DIR/.env.bak ]; then
      mv $ROOT_DIR/.env.bak $ROOT_DIR/.env
    fi
    exit 1
  fi
  # 既存の値をチェックして、なければ追加
  if grep -q "^$KEY=" $ROOT_DIR/.env.bak; then
    sed -i "" "s/^$KEY=.*/$KEY=$VALUE/" $ROOT_DIR/.env.bak
  else
    echo "$KEY=$VALUE" >> $ROOT_DIR/.env.bak
  fi
done

# バックアップファイルを新しい.envファイルとして置き換え
mv $ROOT_DIR/.env.bak $ROOT_DIR/.env

# バックアップが不要になった場合、削除
if [ $? -eq 0 ]; then
  echo "Removing backup file..." >> $LOGFILE
  echo "Removing backup file..."
  rm -f $ROOT_DIR/.env.bak
fi

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
