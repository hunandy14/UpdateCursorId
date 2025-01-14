#!/bin/bash

# 配置文件路径
STORAGE_FILE="$HOME/Library/Application Support/Cursor/User/globalStorage/storage.json"

# 生成随机 ID
generate_random_id() {
    openssl rand -hex 32
}

# 生成随机 UUID
generate_random_uuid() {
    uuidgen | tr '[:upper:]' '[:lower:]'
}

# 生成新的 IDs
NEW_MACHINE_ID=${1:-$(generate_random_id)}
NEW_MAC_MACHINE_ID=$(generate_random_id)
NEW_DEV_DEVICE_ID=$(generate_random_uuid)

echo "新ID:"
echo "telemetry.macMachineId: $NEW_MAC_MACHINE_ID"
echo "telemetry.machineId: $NEW_MACHINE_ID"
echo "telemetry.devDeviceId: $NEW_DEV_DEVICE_ID"
