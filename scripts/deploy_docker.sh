#!/bin/bash

PARAMETER_NAMES=(
  "/myapp/MESSAGE"
)

echo "Creating .env file..."

for PARAM in "${PARAMETER_NAMES[@]}"; do
  KEY=$(echo $PARAM | awk -F'/' '{print $NF}')
  VALUE=$(aws ssm get-parameter --name $PARAM --with-decryption --query "Parameter.Value" --output text)
  echo "$KEY=$VALUE" >> /home/ec2-user/myapp/.env
done

# GitHubリポジトリからソースコードをクローン
cd /home/ec2-user/myapp
git pull origin main

# Dockerイメージをビルド
docker build -t myapp-image .

# 新しいコンテナを実行
docker run -d --name myapp-container -p 3001:3001 myapp-image
