#!/bin/bash

# ===============================================
# Flink流处理引擎启动脚本
# 作用：根据容器角色启动Flink JobManager或TaskManager服务
# 原理：通过命令行参数识别服务角色，执行对应的启动命令
# 重要性：Flink集群的核心启动脚本，确保任务调度和执行正常
# ===============================================

# 设置严格错误处理模式：任何命令失败立即退出脚本
set -e

# ===============================================
# 角色识别和服务启动分发
# 作用：根据传入的参数决定启动JobManager还是TaskManager
# 原理：使用case语句匹配角色参数，执行对应的启动逻辑
# 参数来源：Docker Compose command字段传递的角色标识
# ===============================================

# 根据角色启动Flink服务
case "$1" in
    # ===============================================
    # JobManager服务启动
    # 作用：启动Flink集群的JobManager服务
    # 原理：JobManager负责任务调度、资源管理和集群协调
    # 启动模式：使用start-foreground在前台运行，便于容器管理
    # ===============================================
    jobmanager)
        echo "Starting Flink JobManager..."
        # 使用exec替换当前进程，确保信号正确传递
        exec $FLINK_HOME/bin/jobmanager.sh start-foreground
        ;;
    
    # ===============================================
    # TaskManager服务启动
    # 作用：启动Flink集群的TaskManager服务
    # 原理：TaskManager负责实际的任务执行和资源分配
    # 启动模式：使用start-foreground在前台运行，便于容器管理
    # ===============================================
    taskmanager)
        echo "Starting Flink TaskManager..."
        # 使用exec替换当前进程，确保信号正确传递
        exec $FLINK_HOME/bin/taskmanager.sh start-foreground
        ;;
    
    # ===============================================
    # 参数错误处理
    # 作用：处理无效的角色参数，提供使用说明
    # 原理：当参数不匹配任何有效角色时，显示帮助信息并退出
    # 错误处理：返回非零退出码，表示启动失败
    # ===============================================
    *)
        echo "Usage: $0 {jobmanager|taskmanager}"
        echo "   jobmanager - 启动Flink JobManager服务"
        echo "   taskmanager - 启动Flink TaskManager服务"
        exit 1
        ;;
esac