# ベースイメージの指定
FROM node:16-alpine

# アプリケーションディレクトリを作成
WORKDIR /usr/src/app

# パッケージのインストール
COPY package*.json ./
RUN npm install

# アプリケーションのソースをコピー
COPY . .

# ビルド
RUN npm run build

# ポートのエクスポーズ
EXPOSE 3001

# アプリケーションの起動
CMD ["node", "dist/src/main"]
