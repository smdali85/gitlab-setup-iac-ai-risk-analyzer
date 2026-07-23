#!/bin/bash
#yum update -y
#amazon-linux-extras install docker -y
#systemctl enable docker
#systemctl start docker

#mkdir -p /srv/gitlab/{config,logs,data}
#chmod -R 755 /srv/gitlab

#docker run -d \
#  --name gitlab \
#  --restart always \
#  --hostname gitlab.internal.company \
#  -p 80:80 \
#  -p 22:22 \
#  -v /srv/gitlab/config:/etc/gitlab \
#  -v /srv/gitlab/logs:/var/log/gitlab \
#  -v /srv/gitlab/data:/var/opt/gitlab \
#  gitlab/gitlab-ee:latest

#!/bin/bash
set -e

echo "========== GitLab Setup Started =========="

# ------------------------------
# Variables (edit if needed)
# ------------------------------
GITLAB_HOSTNAME="gitlab.internal.company"
GITLAB_EXTERNAL_URL="http://${GITLAB_HOSTNAME}"
GITLAB_ROOT_DIR="/srv/gitlab"

# ------------------------------
# System Update
# ------------------------------
yum update -y

# Install Docker
amazon-linux-extras install docker -y
systemctl enable docker
systemctl start docker

# ------------------------------
# Create GitLab directories
# ------------------------------
mkdir -p ${GITLAB_ROOT_DIR}/{config,logs,data}
chmod -R 755 ${GITLAB_ROOT_DIR}

# ------------------------------
# Create Swap (important for m6i.large)
# ------------------------------
fallocate -l 4G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=4096
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

# ------------------------------
# Pull GitLab image
# ------------------------------
docker pull gitlab/gitlab-ee:latest

# ------------------------------
# Run GitLab Container
# ------------------------------
docker run -d \
  --name gitlab \
  --restart always \
  --hostname ${GITLAB_HOSTNAME} \
  -p 80:80 \
  -p 22:22 \
  -v ${GITLAB_ROOT_DIR}/config:/etc/gitlab \
  -v ${GITLAB_ROOT_DIR}/logs:/var/log/gitlab \
  -v ${GITLAB_ROOT_DIR}/data:/var/opt/gitlab \
  --shm-size 256m \
  gitlab/gitlab-ee:latest

# ------------------------------
# Configure GitLab (after boot)
# ------------------------------
sleep 60

docker exec gitlab gitlab-ctl reconfigure

# Set external URL & security settings
docker exec gitlab gitlab-rails runner "
ApplicationSetting.current.update!(
  signup_enabled: false
)
"

# ------------------------------
# Enable automatic restart on reboot
# ------------------------------
systemctl enable docker

# ------------------------------
# Health check
# ------------------------------
sleep 30
docker ps | grep gitlab && echo "GitLab container is running"

echo "========== GitLab Setup Completed =========="
echo "Access GitLab at: ${GITLAB_EXTERNAL_URL}"

