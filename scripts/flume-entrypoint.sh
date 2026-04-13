#!/bin/bash
set -e

# 创建示例日志文件（用于测试）
echo "$(date): Flume agent started" >> /var/log/application/application.log

# 获取命令行参数（支持Docker Compose的command覆盖）
AGENT_TYPE=${1:-${FLUME_AGENT_TYPE:-kafka}}

# 根据配置文件名启动不同的Flume Agent
case "$AGENT_TYPE" in
    kafka)
        echo "Starting Flume Agent for Kafka..."
        exec $FLUME_HOME/bin/flume-ng agent \
            --conf $FLUME_HOME/conf \
            --conf-file /opt/flume/conf/flume-kafka.conf \
            --name agent1 \
            -Dflume.root.logger=INFO,console
        ;;
    *)
        echo "Usage: $0 {kafka}"
        echo "Available configurations:"
        echo "  kafka - Collect logs to Kafka"
        exit 1
        ;;
esac