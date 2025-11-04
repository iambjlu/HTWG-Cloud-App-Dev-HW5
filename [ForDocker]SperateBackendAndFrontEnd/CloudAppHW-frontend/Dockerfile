# 使用 Ubuntu 作為基礎映像
FROM ubuntu:22.04

# 設定環境變數
# 注意：這裡的 HOME 和 PROJECT_DIR 現在是在 root 下
ENV USERNAME root
ENV HOME /root
ENV PROJECT_DIR $HOME/PhpStormProjects/CloudAppHW

# 由於使用 root，不需要建立使用者或設定 sudoers

# 建立專案目錄
RUN mkdir -p $HOME/PhpStormProjects && \
    cd $HOME/PhpStormProjects

# --------------------------------------------------------------------------
# 步驟 1: 清理系統預設的 Nodejs (確保系統乾淨)
# --------------------------------------------------------------------------
RUN apt update -y
RUN apt-get remove -y nodejs npm
RUN apt-get autoremove -y
RUN apt-get update

# --------------------------------------------------------------------------
# 步驟 2: 安裝必要工具並設定 NodeSource 軟體庫 (分開執行，避免 APT 混亂)
# --------------------------------------------------------------------------
RUN apt install -y ca-certificates curl gnupg unzip && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    NODE_MAJOR=22 && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list

# --------------------------------------------------------------------------
# 步驟 3A: 安裝 Node.js 和 NPM (修正版)
# --------------------------------------------------------------------------
# 確保在 NodeSource 軟體庫設定完成後，APT 能從那裡獲取 nodejs 和 npm
# 注意：NodeSource 的 nodejs 套件會同時安裝正確版本的 npm。
# 我們將它們寫在同一行，確保依賴關係能被解決。
RUN apt update -y 
RUN apt install -y nodejs
RUN apt install -y mysql-server
RUN apt install -y mysql-client-core-8.0
RUN apt install -y wget
RUN node -v
RUN npm -v


# 下載並解壓縮應用程式程式碼
WORKDIR /tmp
RUN wget -O CloudAppHW5.zip https://github.com/iambjlu/HTWG-Cloud-App-Dev-HW5/releases/download/1141104/CloudAppHW5.zip && \
    unzip -o CloudAppHW5.zip -d CloudAppHW && \
    rm CloudAppHW5.zip && \
    mv CloudAppHW $PROJECT_DIR

# 專案依賴安裝 (步驟 8)
# WORKDIR $PROJECT_DIR/backend-api
# RUN npm install express mysql2 cors dotenv

WORKDIR $PROJECT_DIR/frontend-vue
RUN npm install axios
RUN npm install firebase
RUN npm install

# 將啟動腳本複製到容器內
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# 開放 API 和 Frontend 的埠 (3000 和 5173)
# EXPOSE 3000
EXPOSE 5173

# 設定容器啟動時執行的指令
# 由於現在是 root，entrypoint.sh 中的 sudo su 和 sudo -u 都可以移除
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["$PROJECT_DIR"]