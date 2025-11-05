provider "google" {
  project = "htwg-cloudapp-hw"
  region  = "us-west1"
  zone    = "us-west1-c"
}
resource "google_compute_instance" "free-vm-1141105" {
  boot_disk {
    auto_delete = true
    device_name = "free-vm-1141105"

    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20251023"
      size  = 30
      type  = "pd-standard"
    }

    mode = "READ_WRITE"
  }

  can_ip_forward      = false
  deletion_protection = false
  enable_display      = true

  labels = {
    goog-ec-src           = "vm_add-tf"
    goog-ops-agent-policy = "v2-x86-template-1-4-0"
  }

  machine_type = "e2-micro"

  metadata = {
    enable-osconfig = "TRUE"
  }

  # ✅ 啟動腳本整合（錯字修好）
  metadata_startup_script = <<STARTUP
#!/usr/bin/env bash
set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive

id -u iambjlu >/dev/null 2>&1 || useradd -m -s /bin/bash iambjlu
mkdir -p /home/iambjlu/PhpStormProjects
chown -R iambjlu:iambjlu /home/iambjlu

cat <<'CMDS1' >/home/iambjlu/PhpStormProjects/run_part1.sh
mkdir PhpStormProjects
cd PhpStormProjects
sudo apt update -y
sudo apt-get remove -y nodejs npm
sudo apt-get autoremove -y
sudo apt-get update
sudo apt install -y ca-certificates curl gnupg unzip 
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
NODE_MAJOR=22
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt update -y
sudo apt install -y nodejs
sudo apt install -y npm
sudo apt install -y mysql-server
sudo apt install -y mysql-client-core-8.0
node -v
npm -v
wget -O CloudAppHW5.zip https://github.com/iambjlu/HTWG-Cloud-App-Dev-HW5/releases/download/1141104/CloudAppHW5.zip \
 && unzip -o CloudAppHW5.zip -d CloudAppHW && rm CloudAppHW5.zip
sudo systemctl start mysql
sudo systemctl status mysql
sudo mysql
CMDS1
chmod +x /home/iambjlu/PhpStormProjects/run_part1.sh

cd /home/iambjlu
bash /home/iambjlu/PhpStormProjects/run_part1.sh || true

cat <<'SQL1' >/home/iambjlu/PhpStormProjects/sql1.sql
CREATE DATABASE travel_app_db;
CREATE USER 'cloudapp_user'@'localhost' IDENTIFIED BY 'mypassword';
GRANT ALL PRIVILEGES ON travel_app_db.* TO 'cloudapp_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
SQL1

mysql < /home/iambjlu/PhpStormProjects/sql1.sql || true

cat <<'SQL2' >/home/iambjlu/PhpStormProjects/sql2.sql
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
    short_description VARCHAR(80) NOT NULL,
    detail_description TEXT,
    FOREIGN KEY (traveller_id) REFERENCES travellers(id),
    end_date DATE NOT NULL
);
EXIT;
SQL2

mysql -u cloudapp_user -pmypassword < /home/iambjlu/PhpStormProjects/sql2.sql || true

mkdir -p /home/iambjlu/PhpStormProjects/CloudAppHW/backend-api
cat <<'ENVBACK' >/home/iambjlu/PhpStormProjects/CloudAppHW/backend-api/.env
GEMINI_API_KEY="xxxx"
GCP_BUCKET_NAME="htwg-cloudapp-hw.firebasestorage.app"
db_database_name = "travel_app_db" # 範例：htwg_db
GCP_SERVICE_ACCOUNT_JSON= <<-EOT
{  "type": "service_account",  "project_id": "htwg-cloudapp-hw",  "private_key_id": "xxxx",  "private_key": "-----BEGIN PRIVATE KEY-----\nMII.....1LII\n-----END PRIVATE KEY-----\n",  "client_email": "xxx",  "client_id": "xxx",  "auth_uri": "https://accounts.google.com/o/oauth2/auth",  "token_uri": "https://oauth2.googleapis.com/token",  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/xxxxxx",  "universe_domain": "googleapis.com"}
EOT
# 資料庫連線資訊
DB_HOST=localhost
DB_USER=cloudapp_user
DB_PASSWORD=mypassword
DB_NAME=travel_app_db

# 伺服器設定
PORT=3000
ENVBACK

mkdir -p /home/iambjlu/PhpStormProjects/CloudAppHW/frontend-vue
cat <<'ENVFRONT' >/home/iambjlu/PhpStormProjects/CloudAppHW/frontend-vue/.env
VITE_FIREBASE_API_KEY="xxxx"
VITE_FIREBASE_AUTH_DOMAIN="htwg-cloudapp-hw.firebaseapp.com"
VITE_FIREBASE_PROJECT_ID="htwg-cloudapp-hw"
VITE_FIREBASE_APP_ID="xxxxxx"
VITE_FIREBASE_STORAGE_BUCKET="your-project.appspot.com"
VITE_MEASUREMENTID="xxxxxx"
ENVFRONT

cat <<'MANENV' >/home/iambjlu/PhpStormProjects/env_notes.txt
#環境變數
manual_db_host     = "35.201.177.162"
VITE_API_BASE_URL = "http://localhost:3000" 
MANENV

cd /home/iambjlu/PhpStormProjects/CloudAppHW/backend-api
npm install express mysql2 cors dotenv
npm install undici
npm install multer
npm install @google/generative-ai@latest firebase-admin@latest @google-cloud/storage@latest

cd /home/iambjlu/PhpStormProjects/CloudAppHW/frontend-vue
npm install axios
npm install firebase

echo 'VITE_API_BASE_URL=http://localhost:3000' >> /home/iambjlu/PhpStormProjects/CloudAppHW/frontend-vue/.env || true

sudo su - <<'ROOTCMDS'
nohup bash -c 'cd /home/iambjlu/PhpStormProjects/CloudAppHW/backend-api && node server.js' >/tmp/backend.log 2>&1 &
nohup bash -c 'cd /home/iambjlu/PhpStormProjects/CloudAppHW/frontend-vue && npm run dev -- --host 0.0.0.0' >/tmp/frontend.log 2>&1 &
sudo systemctl start mysql;sudo systemctl status mysql
ROOTCMDS

chown -R iambjlu:iambjlu /home/iambjlu

STARTUP

  name = "free-vm-1141105"

  network_interface {
    access_config {
      network_tier = "STANDARD"
    }

    queue_count = 0
    stack_type  = "IPV4_ONLY"
    subnetwork  = "projects/htwg-cloudapp-hw/regions/us-west1/subnetworks/default"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  service_account {
    email  = "42343490951-compute@developer.gserviceaccount.com"
    scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append"
    ]
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }

  tags = ["http-server", "https-server"]
  zone = "us-west1-c"
}

module "ops_agent_policy" {
  source          = "github.com/terraform-google-modules/terraform-google-cloud-operations/modules/ops-agent-policy"
  project         = "htwg-cloudapp-hw"
  zone            = "us-west1-c"
  assignment_id   = "goog-ops-agent-v2-x86-template-1-4-0-us-west1-c"
  agents_rule = {
    package_state = "installed"
    version = "latest"
  }
  instance_filter = {
    all = false
    inclusion_labels = [{
      labels = {
        goog-ops-agent-policy = "v2-x86-template-1-4-0"
      }
    }]
  }
}

resource "google_compute_firewall" "allow_custom_ports" {
  name    = "allow-frontend-backend"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["3000", "5173"]
  }

  # 限定套用在有這些 tags 的 instance 上
  target_tags = ["http-server", "https-server"]

  # 開放全網訪問
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
}