#!/bin/bash

# 設定環境變數，現在使用 root 路徑
USERNAME=root
PROJECT_DIR=/root/PhpStormProjects/CloudAppHW

# 啟動 MySQL (模擬步驟 2. 最後)
echo "Starting MySQL server..."
# 容器中，systemctl 不可用，我們直接啟動 mysqld
/etc/init.d/mysql start
sleep 5 # 等待 MySQL 啟動

# 執行 MySQL 互動式指令 (模擬步驟 3)
echo "Creating database and user..."
mysql <<EOF
CREATE DATABASE travel_app_db;
CREATE USER 'cloudapp_user'@'localhost' IDENTIFIED BY 'mypassword';
GRANT ALL PRIVILEGES ON travel_app_db.* TO 'cloudapp_user'@'localhost';
FLUSH PRIVILEGES;
EOF

# 登入 MySQL 並建立表格 (模擬步驟 4 & 5)
echo "Creating tables..."
mysql -u cloudapp_user -p"mypassword" travel_app_db <<EOF
USE travel_app_db;
CREATE TABLE travellers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL
);
CREATE TABLE itineraries (
    id INT AUTO_INCREMENT PRIMARY KEY,
    traveller_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    destination VARCHAR(255) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    short_description VARCHAR(80) NOT NULL,
    detail_description TEXT,
    FOREIGN KEY (traveller_id) REFERENCES travellers(id)
);
EOF

# # 編輯 .env 檔案 (模擬步驟 6 & 7)
# **請確認 API_URL 是您的 IP 或 CloudFront URL**
# ENV_FILE="$PROJECT_DIR/frontend-vue/.env"
# API_URL="http://localhost:3000"

# echo "VITE_API_BASE_URL=$API_URL" > $ENV_FILE
# echo "Frontend .env file created:"
# cat $ENV_FILE

# 執行伺服器 (模擬步驟 9 & 10)
echo "Starting backend and frontend servers using nohup..."

# 原始指令：不需要 sudo su 或 sudo -u，直接使用 nohup 執行
nohup bash -c 'cd $PROJECT_DIR/backend-api && node server.js' >/tmp/backend.log 2>&1 &
# nohup bash -c 'cd $PROJECT_DIR/frontend-vue && npm run dev -- --host 0.0.0.0' >/tmp/frontend.log 2>&1 &

echo "Backend log: /tmp/backend.log"
# echo "Frontend log: /tmp/frontend.log"
# echo "Application running. Access at <Server IP>:5173"

# 保持容器運行，可以查看日誌
tail -f /tmp/backend.log
# tail -f /tmp/backend.log /tmp/frontend.log