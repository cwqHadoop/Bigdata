#!/bin/bash
set -e

# Extract node ID from hostname (e.g., kafka1 -> 1)
NODE_ID=$(hostname | sed 's/kafka//')

# Fallback if hostname parsing fails
if [ -z "$NODE_ID" ] || [[ ! "$NODE_ID" =~ ^[0-9]+$ ]]; then
    NODE_ID=1
fi

# Select configuration file
CONFIG_FILE="/opt/kafka/config/server${NODE_ID}.properties"
if [ "$NODE_ID" = "1" ]; then
    CONFIG_FILE="/opt/kafka/config/server.properties"
fi

echo "Starting Kafka node $NODE_ID with config $CONFIG_FILE..."

# Start Kafka
exec /opt/kafka/bin/kafka-server-start.sh "$CONFIG_FILE"