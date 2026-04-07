#!/bin/bash
set -euo pipefail

DATA_DISK="/dev/sdb"
MOUNT_POINT="/srv/gitlab"

# Format data disk if not already formatted
if ! blkid "$DATA_DISK" > /dev/null 2>&1; then
  mkfs.ext4 -F "$DATA_DISK"
fi

# Mount data disk (idempotent)
mkdir -p "$MOUNT_POINT"
if ! mountpoint -q "$MOUNT_POINT"; then
  mount "$DATA_DISK" "$MOUNT_POINT"
fi

# Add to fstab (idempotent)
if ! grep -q "$DATA_DISK" /etc/fstab; then
  echo "$DATA_DISK $MOUNT_POINT ext4 defaults 0 2" >> /etc/fstab
fi

# Create GitLab and Docker subdirectories on data disk
mkdir -p \
  "$MOUNT_POINT/config" \
  "$MOUNT_POINT/logs" \
  "$MOUNT_POINT/data" \
  "$MOUNT_POINT/runner" \
  "$MOUNT_POINT/docker"

# Point Docker data-root to data disk
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << 'DOCKERCFG'
{
  "data-root": "/srv/gitlab/docker"
}
DOCKERCFG

systemctl restart docker

# Write docker-compose.yml
cat > "$MOUNT_POINT/docker-compose.yml" << 'COMPOSE'
services:
  gitlab:
    image: gitlab/gitlab-ce:latest
    restart: always
    hostname: gitlab.${domain_name}
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'https://gitlab.${domain_name}'
        letsencrypt['enable'] = true
        letsencrypt['contact_emails'] = ['${acme_email}']
        gitlab_rails['time_zone'] = 'Europe/Berlin'
        gitlab_rails['gitlab_shell_ssh_port'] = 2222
    ports:
      - "80:80"
      - "443:443"
      - "2222:22"
    volumes:
      - /srv/gitlab/config:/etc/gitlab
      - /srv/gitlab/logs:/var/log/gitlab
      - /srv/gitlab/data:/var/opt/gitlab
    shm_size: '256m'

  gitlab-runner:
    image: gitlab/gitlab-runner:latest
    restart: always
    volumes:
      - /srv/gitlab/runner:/etc/gitlab-runner
      - /var/run/docker.sock:/var/run/docker.sock
COMPOSE

# Start containers
docker compose -f "$MOUNT_POINT/docker-compose.yml" up -d
