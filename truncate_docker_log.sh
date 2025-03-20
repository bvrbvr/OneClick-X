#!/bin/bash


CONTAINER_NAME="OneClick-X"

LOG_PATH=$(docker inspect --format='{{.LogPath}}' "$CONTAINER_NAME" 2>/dev/null)

if [ -z "$LOG_PATH" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error:permission denied '$CONTAINER_NAME'." >> /var/log/truncate_docker_log.log
    exit 1
fi

if [ ! -f "$LOG_PATH" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: file '$LOG_PATH' do not exist." >> /var/log/truncate_docker_log.log
    exit 1
fi

sudo sh -c "truncate -s 0 '$LOG_PATH'"

if [ $? -eq 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Success clear '$CONTAINER_NAME'." >> /var/log/truncate_docker_log.log
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: faield '$CONTAINER_NAME'." >> /var/log/truncate_docker_log.log
    exit 1
fi
