#!/bin/bash

ROOT_DIR=/home/ec2-user/myapp
LOGFILE=/home/ec2-user/deploy.log

# ディレクトリとファイルの権限を設定

sudo touch $LOGFILE
sudo chown ec2-user:ec2-user $LOGFILE
sudo chmod 644 $LOGFILE

echo "Starting deployment script" >> $LOGFILE
echo "Starting deployment script"

# 必要な環境変数をSSM Parameter Storeから取得して.envファイルを作成
PARAMETER_NAMES=(
  "/myapp/MESSAGE"
)

sudo chown -R ec2-user:ec2-user $ROOT_DIR

echo "Creating .env file..." >> $LOGFILE
echo "Creating .env file..."

# .envファイルをバックアップし、後で新しい内容で上書きする
if [ -f $ROOT_DIR/.env ]; then
  cp $ROOT_DIR/.env $ROOT_DIR/.env.bak
fi
echo "Backup file created" >> $LOGFILE
echo "Backup file created"

# 新しい内容で.envファイルを作成
for PARAM in "${PARAMETER_NAMES[@]}"; do
  KEY=$(echo $PARAM | awk -F'/' '{print $NF}')
  echo "Getting parameter: $PARAM"
  VALUE=$(aws ssm get-parameter --name $PARAM --with-decryption --query "Parameter.Value" --output text --region ap-northeast-1)
  if [ $? -ne 0 ]; then
    echo "Failed to get parameter: $PARAM" >> $LOGFILE
    echo "AWS CLI output:" >> $LOGFILE
    aws ssm get-parameter --name $PARAM --with-decryption --query "Parameter.Value" --output text
    echo "Restoring from backup..." >> $LOGFILE
    echo "Restoring from backup..."
    if [ -f $ROOT_DIR/.env.bak ]; then
      mv $ROOT_DIR/.env.bak $ROOT_DIR/.env
    fi
    exit 1
  fi
  # 既存の値をチェックして、なければ追加
  if grep -q "^$KEY=" $ROOT_DIR/.env.bak; then
    sed -i "s/^$KEY=.*/$KEY=$VALUE/" $ROOT_DIR/.env.bak
  else
    echo "$KEY=$VALUE" >> $ROOT_DIR/.env.bak
  fi
done

echo "New .env file created" >> $LOGFILE
echo "New .env file created"

# バックアップファイルを新しい.envファイルとして置き換え
mv $ROOT_DIR/.env.bak $ROOT_DIR/.env

# バックアップが不要になった場合、削除
if [ $? -eq 0 ]; then
  echo "Removing backup file..." >> $LOGFILE
  echo "Removing backup file..."
  rm -f $ROOT_DIR/.env.bak
fi

# Dockerイメージをビルド
echo "Building Docker image..." >> $LOGFILE
echo "Building Docker image..."
docker build -t myapp-image . >> $LOGFILE 2>&1
if [ $? -ne 0 ]; then
  echo "Failed to build Docker image" >> $LOGFILE
  echo "Failed to build Docker image"
  exit 1
fi

# 古いコンテナを停止して削除
echo "Stopping and removing old container..." >> $LOGFILE
echo "Stopping and removing old container..."
docker ps -q --filter "name=myapp-container" | grep -q . && docker stop myapp-container >> $LOGFILE 2>&1 && docker rm myapp-container >> $LOGFILE 2>&1
if [ $? -ne 0 ]; then
  echo "Failed to stop and remove old container" >> $LOGFILE
  echo "Failed to stop and remove old container"
fi

# 新しいコンテナを実行
echo "Running new container..." >> $LOGFILE
echo "Running new container..."
docker run -d --env-file $ROOT_DIR/.env -p 80:3000 myapp-image >> $LOGFILE 2>&1
if [ $? -ne 0 ]; then
  echo "Failed to run new container" >> $LOGFILE
  echo "Failed to run new container"
  exit 1
fi

echo "Deployment script completed successfully" >> $LOGFILE
echo "Deployment script completed successfully"
