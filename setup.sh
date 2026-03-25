#!/bin/bash

set -e


echo "=== 1. Обновление системы ==="
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y -o Dpkg::Options::="--force-confnew"
apt-get install -y openssh-server -o Dpkg::Options::="--force-confnew"


echo "=== 4. SSH ==="
sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config

systemctl restart ssh


echo "=== 5. Установка ==="
apt-get install -y curl wget git sudo ufw openssl docker.io docker-compose

systemctl enable docker
systemctl start docker

echo "=== 6. Настройка firewall ==="
ufw allow 22
ufw allow 443
ufw allow 444
ufw allow 445

ufw --force enable

echo "=== 7. Рабочая директория ==="
mkdir -p /opt/mtproxy
cd /opt/mtproxy

echo "=== 8. Генерация config.env ==="

for i in 1 2 3
do
cat <<EOF > config${i}.env
SECRET=$(openssl rand -hex 16)
WORKERS=1
EOF
done

echo "=== 9. docker-compose.yml ==="

cat <<EOF > docker-compose.yml
version: '2'
services:
  proxy1:
    image: telegrammessenger/proxy:latest
    container_name: proxy1
    ports:
      - "444:443"
    volumes:
      - "proxy-config1:/data"
    restart: always
    env_file:
      - ./config1.env

  proxy2:
    image: telegrammessenger/proxy:latest
    container_name: proxy2
    ports:
      - "445:443"
    volumes:
      - "proxy-config2:/data"
    restart: always
    env_file:
      - ./config2.env

  proxy3:
    image: telegrammessenger/proxy:latest
    container_name: proxy3
    ports:
      - "446:443"
    volumes:
      - "proxy-config3:/data"
    restart: always
    env_file:
      - ./config3.env
volumes:
  proxy-config1:
  proxy-config2:
  proxy-config3:
EOF

echo "=== 10. Запуск контейнеров ==="
docker-compose up -d


echo "=== LINKS ==="
IP=$(curl -s ifconfig.me)

for i in 1 2 3
do
  PORT=$((443 + i))
  SECRET=$(grep SECRET config${i}.env | cut -d '=' -f2)

  echo "tg://proxy?server=${IP}&port=${PORT}&secret=${SECRET}"
done