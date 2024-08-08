#!/bin/bash

LOGFILE=/home/ec2-user/myapp/deployment.log
echo "Starting deployment script" > $LOGFILE

# 必要な環境変数をSSM Parameter Storeから取得して.envファイルを作成
PARAMETER_NAMES=(
  "/myapp/MESSAGE"
)

echo "Creating .env file..." >> $LOGFILE

for PARAM in "${PARAMETER_NAMES[@]}"; do
  KEY=$(echo $PARAM | awk -F'/' '{print $NF}')
  VALUE=$(aws ssm get-parameter --name $PARAM --with-decryption --query "Parameter.Value" --output text 2>> $LOGFILE)
  if [ $? -ne 0 ]; then
    echo "Failed to get parameter: $PARAM" >> $LOGFILE
    exit 1
  fi
  echo "$KEY=$VALUE" >> /home/ec2-user/myapp/.env
done

# GitHubリポジトリからソースコードをクローン
echo "Pulling latest code from GitHub..." >> $LOGFILE
cd /home/ec2-user/myapp
git pull origin main >> $LOGFILE 2>&1
if [ $? -ne 0 ]; then
  echo "Failed to pull latest code from GitHub" >> $LOGFILE
  exit 1
fi

# Dockerイメージをビルド
echo "Building Docker image..." >> $LOGFILE
docker build -t myapp-image . >> $LOGFILE 2>&1
if [ $? -ne 0 ]; then
  echo "Failed to build Docker image" >> $LOGFILE
  exit 1
fi

# 古いコンテナを停止して削除
echo "Stopping and removing old container..." >> $LOGFILE
docker ps -q --filter "name=myapp-container" | grep -q . && docker stop myapp-container >> $LOGFILE 2>&1 && docker rm myapp-container >> $LOGFILE 2>&1
if [ $? -ne 0 ]; then
  echo "Failed to stop and remove old container" >> $LOGFILE
  exit 1
fi

# 新しいコンテナを実行
echo "Running new container..." >> $LOGFILE
docker run -d --name myapp-container --env-file /home/ec2-user/myapp/.env -p 3001:3001 myapp-image >> $LOGFILE 2>&1
if [ $? -ne 0 ]; then
  echo "Failed to run new container" >> $LOGFILE
  exit 1
fi

echo "Deployment script completed successfully" >> $LOGFILE
