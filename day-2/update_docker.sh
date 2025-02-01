#!/bin/bash

# Configuration - Fill in your values
VOLUME_PATH="<volume_path>"  # e.g., /mnt/HC_Volume
VOLUME_NAME="<volume_name>"  # e.g., HC_Volume

# Create backup name with timestamp
SNAPSHOT_NAME="${VOLUME_NAME}_$(date +%Y-%m-%dT%H%M).tar.gz"

# Docker images to pull (add other images as needed)
docker pull n8nio/n8n

# Build and restart services
docker compose build --no-cache n8n
docker compose stop

# Create compressed backup
echo "Creating backup: $SNAPSHOT_NAME"
tar cf - "$VOLUME_PATH" | pigz -1 > "$SNAPSHOT_NAME"

# Restart services
docker compose up -d
docker system prune -f

# Storage methods (uncomment and configure the one you need):

# 1. Using SSH key authentication (most secure)
# First set up your SSH key: ssh-keygen -t rsa -b 4096
# Then add to storage: ssh-copy-id -p 23 user@storage-host
#scp -P 23 "$SNAPSHOT_NAME" "user@storage-host:./$SNAPSHOT_NAME"

# 2. Hetzner Storage Box using password file
# Create a file '.storage_pass' with just the password in it
# chmod 600 .storage_pass to secure it
#sshpass -f .storage_pass scp -P 23 "$SNAPSHOT_NAME" "u357910@u357910.your-storagebox.de:./$SNAPSHOT_NAME"

# 3. Using environment variables
# Export these variables before running the script:
# export STORAGE_USER="your-username"
# export STORAGE_HOST="your-host"
# export STORAGE_PORT="23"
#scp -P "$STORAGE_PORT" "$SNAPSHOT_NAME" "$STORAGE_USER@$STORAGE_HOST:./$SNAPSHOT_NAME"

# 4. AWS S3 method
# First configure AWS CLI: aws configure
# Or set up ~/.aws/credentials and ~/.aws/config
# Or use environment variables:
# export AWS_ACCESS_KEY_ID="your-access-key"
# export AWS_SECRET_ACCESS_KEY="your-secret-key"
# export AWS_DEFAULT_REGION="your-region"
#S3_BUCKET="your-bucket-name"
#S3_PATH="backups/"  # Optional: path within bucket
#aws s3 cp "$SNAPSHOT_NAME" "s3://$S3_BUCKET/$S3_PATH$SNAPSHOT_NAME"

# Check if upload was successful and cleanup
if [ $? -eq 0 ]; then
    echo "Snapshot $SNAPSHOT_NAME was uploaded successfully, removing local copy"
    rm "$SNAPSHOT_NAME"
else
    echo "Upload failed, keeping local snapshot: $SNAPSHOT_NAME"
    exit 1
fi

echo "Backup process completed"
