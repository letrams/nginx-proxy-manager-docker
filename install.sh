#!/usr/bin/env bash
set -euo pipefail

# === Config (edit if needed) ===
UI_PORT=${UI_PORT:-81}            # Port for Nginx Proxy Manager Web UI
TZ=${TZ:-Europe/Kyiv}             # Timezone
PROJECT_DIR=${PROJECT_DIR:-/opt/nginx-proxy-manager}
NETWORK_NAME=${NETWORK_NAME:-proxy_net}

echo "[INFO] Preparing project directories..."
sudo mkdir -p "${PROJECT_DIR}"/{data,letsencrypt}
sudo chown -R "$USER":"$USER" "${PROJECT_DIR}"

echo "[INFO] Checking for Docker..."
if ! command -v docker >/dev/null 2>&1; then
  echo "[INFO] Docker not found. Would you like to install Docker CE? [y/N]"
  read -r answer
  if [[ "${answer,,}" == "y" ]]; then
    sudo apt-get update -y
    sudo apt-get install -y ca-certificates curl gnupg lsb-release
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
      sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl enable --now docker
    sudo usermod -aG docker "$USER" || true
    echo "[INFO] Docker CE installed. Please log out and log back in for group changes to take effect."
  else
    echo "[WARN] Docker is not installed. Without Docker, containers will not run."
    exit 1
  fi
else
  echo "[INFO] Docker is already installed. Skipping installation."
fi

echo "[INFO] Checking for Docker network '${NETWORK_NAME}'..."
if ! docker network ls --format '{{.Name}}' | grep -qw "${NETWORK_NAME}"; then
  docker network create "${NETWORK_NAME}"
  echo "[INFO] Network '${NETWORK_NAME}' created."
else
  echo "[INFO] Network '${NETWORK_NAME}' already exists."
fi

echo
echo "=== Setup Complete ==="
echo "Next steps:"
echo "1) Copy docker-compose.yml into ${PROJECT_DIR}"
echo "2) Start the stack: cd ${PROJECT_DIR} && docker compose up -d"
echo "3) Access the Web UI: http://<SERVER_IP>:${UI_PORT}"
echo "   Default login: admin@example.com / changeme (you will be asked to change it)."
echo
echo "[Tip] For security, restrict port ${UI_PORT} (Web UI) to your IP:"
echo "      sudo ufw allow 80,443/tcp"
echo "      sudo ufw allow from <YOUR-IP> to any port ${UI_PORT} proto tcp"