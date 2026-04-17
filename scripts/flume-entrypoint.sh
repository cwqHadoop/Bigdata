#!/bin/bash

# ===============================================
# Flume数据采集服务启动脚本
# 作用：启动Flume数据采集Agent，支持Kafka输出模式
# 原理：根据参数选择不同的Agent配置，启动对应的数据采集任务
# 重要性：实现日志数据的实时采集和传输到消息队列
# ===============================================

# 设置严格错误处理模式：任何命令失败立即退出脚本
set -e

# ===============================================
# 测试数据准备
# 作用：创建示例日志文件，用于Flume Agent的测试和验证
# 原理：Flume Agent需要监控的日志文件必须存在才能正常工作
# 文件路径：/var/log/application/application.log
# ===============================================

# 创建示例日志文件（用于测试）
echo "$(date): Flume agent started" >> /var/log/application/application.log

# ===============================================
# Agent类型参数解析
# 作用：解析命令行参数，确定要启动的Flume Agent类型
# 原理：支持命令行参数和环境变量两种方式指定Agent类型
# 优先级：命令行参数 > 环境变量 > 默认值（kafka）
# ===============================================

# 获取命令行参数（支持Docker Compose的command覆盖）
AGENT_TYPE=${1:-${FLUME_AGENT_TYPE:-kafka}}

# ===============================================
# Agent启动分发逻辑
# 作用：根据Agent类型选择对应的配置文件和启动参数
# 原理：使用case语句匹配Agent类型，执行对应的启动逻辑
# 启动模式：支持多种数据采集和输出模式
# ===============================================

# 根据配置文件名启动不同的Flume Agent
case "$AGENT_TYPE" in
    # ===============================================
    # Kafka输出模式
    # 作用：启动将日志数据采集到Kafka的Flume Agent
    # 原理：使用flume-kafka.conf配置文件，实现日志到Kafka的传输
    # 启动参数：
    #   --conf: Flume配置目录
    #   --conf-file: 具体的Agent配置文件
    #   --name: Agent名称标识
    #   -Dflume.root.logger: 日志级别和输出目标
    # ===============================================
    kafka)
        echo "Starting Flume Agent for Kafka..."
        # 使用exec替换当前进程，确保信号正确传递
        exec $FLUME_HOME/bin/flume-ng agent \
            --conf $FLUME_HOME/conf \
            --conf-file /opt/flume/conf/flume-kafka.conf \
            --name agent1 \
            -Dflume.root.logger=INFO,console
        ;;
    
    # ===============================================
    # 参数错误处理
    # 作用：处理无效的Agent类型参数，提供使用说明
    # 原理：当参数不匹配任何有效Agent类型时，显示帮助信息并退出
    # 错误处理：返回非零退出码，表示启动失败
    # ===============================================
    *)
        echo "Usage: $0 {kafka}"
        echo "Available configurations:"
        echo "  kafka - Collect logs to Kafka"
        exit 1
        ;;
esac