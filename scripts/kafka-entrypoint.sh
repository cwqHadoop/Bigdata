#!/bin/bash

# ===============================================
# Kafka消息队列服务启动脚本
# 作用：根据容器主机名自动识别节点ID，加载对应的配置文件
# 原理：通过主机名解析节点标识，支持多Broker集群部署
# 重要性：Kafka集群的核心启动脚本，确保每个Broker使用正确的配置
# ===============================================

# 设置严格错误处理模式：任何命令失败立即退出脚本
set -e

# ===============================================
# 节点标识自动识别
# 作用：从容器主机名中提取Kafka节点ID
# 原理：主机名格式为kafka1、kafka2等，提取数字部分作为节点ID
# 正则表达式：sed 's/kafka//' 移除主机名中的"kafka"前缀
# ===============================================

# Extract node ID from hostname (e.g., kafka1 -> 1)
NODE_ID=$(hostname | sed 's/kafka//')

# ===============================================
# 节点标识验证和容错处理
# 作用：验证提取的节点ID是否有效，提供默认值作为容错机制
# 原理：如果节点ID为空或不是数字，则使用默认值1
# 正则表达式：^[0-9]+$ 确保节点ID是纯数字
# ===============================================

# Fallback if hostname parsing fails
if [ -z "$NODE_ID" ] || [[ ! "$NODE_ID" =~ ^[0-9]+$ ]]; then
    echo "警告：无法从主机名解析节点ID，使用默认值1"
    NODE_ID=1
fi

# ===============================================
# 配置文件选择逻辑
# 作用：根据节点ID选择对应的Kafka配置文件
# 原理：每个Kafka Broker使用独立的配置文件，避免配置冲突
# 文件命名规则：
#   - 节点1: server.properties
#   - 节点2: server2.properties
#   - 节点3: server3.properties
# ===============================================

# Select configuration file
CONFIG_FILE="/opt/kafka/config/server${NODE_ID}.properties"
if [ "$NODE_ID" = "1" ]; then
    CONFIG_FILE="/opt/kafka/config/server.properties"
fi

# ===============================================
# 启动信息输出
# 作用：输出启动信息，便于调试和监控
# 原理：显示节点ID和使用的配置文件路径
# 重要性：在容器日志中提供清晰的启动信息
# ===============================================

echo "Starting Kafka node $NODE_ID with config $CONFIG_FILE..."

# ===============================================
# Kafka服务启动
# 作用：启动Kafka Broker服务进程
# 原理：使用kafka-server-start.sh脚本启动Kafka服务
# 启动模式：使用exec替换当前进程，确保信号正确传递
# ===============================================

# Start Kafka
exec /opt/kafka/bin/kafka-server-start.sh "$CONFIG_FILE"