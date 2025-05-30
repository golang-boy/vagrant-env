# Install dependencies for Terramino demo app

curl -fsSL https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu/ \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo rm -rf /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources.curtin.orig
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Add Docker repository
# echo \
  # "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  # "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  # tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "配置 DNS ..."
if command -v systemctl &> /dev/null && systemctl is-active systemd-resolved &> /dev/null; then
  sudo mkdir -p /etc/systemd/resolved.conf.d
  echo "[Resolve]" | sudo tee /etc/systemd/resolved.conf.d/custom-dns.conf
  echo "DNS=8.8.8.8 114.114.114.114" | sudo tee -a /etc/systemd/resolved.conf.d/custom-dns.conf
  echo "FallbackDNS=1.0.0.1 8.8.4.4" | sudo tee -a /etc/systemd/resolved.conf.d/custom-dns.conf
  sudo systemctl restart systemd-resolved
fi

# Install Docker packages
if ! command -v docker &> /dev/null; then
  echo "Docker 未安装，正在安装 Docker..."
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi
# Add vagrant user to docker group
usermod -aG docker vagrant


echo "配置 docker 镜像加速源 ..."
sudo mkdir -p /etc/docker/ && touch /etc/docker/daemon.json
cat <<EOF | sudo tee /etc/docker/daemon.json
 {
  "registry-mirrors": [
    "https://docker.hpcloud.cloud",
    "https://docker.m.daocloud.io",
    "https://docker.unsee.tech",
    "https://docker.1panel.live",
    "http://mirrors.ustc.edu.cn",
    "https://docker.chenby.cn",
    "http://mirror.azure.cn",
    "https://dockerpull.org",
    "https://dockerhub.icu",
    "https://hub.rat.dev",
    "https://proxy.1panel.live",
    "https://docker.1panel.top",
    "https://docker.m.daocloud.io",
    "https://docker.1ms.run",
    "https://docker.ketches.cn"
  ]
}
EOF

sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl enable docker

# Clone Terramino repository if it doesn't exist
# if [ ! -d "/home/gogo/terramino-go/.git" ]; then
  # cd /home/gogo
  # rm -rf terramino-go
  # git clone https://github.com/hashicorp-education/terramino-go.git
  # cd terramino-go
  # git checkout containerized
# fi

# Create reload script
# cat > /usr/local/bin/reload-terramino << 'EOF'
# !/bin/bash
# cd /home/gogo/terramino-go
# docker compose down
# docker compose build --no-cache
# docker compose up -d
# EOF

# chmod +x /usr/local/bin/reload-terramino

# Add aliases
# echo 'alias play="docker compose -f /home/gogo/terramino-go/docker-compose.yml exec -it backend ./terramino-cli"' >> /home/gogo/.bashrc
# echo 'alias reload="sudo /usr/local/bin/reload-terramino"' >> /home/gogo/.bashrc
# Source the updated bashrc
# echo "source /home/gogo/.bashrc" >> /home/gogo/.bash_profile
