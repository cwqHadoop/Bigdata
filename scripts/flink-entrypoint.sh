#!/bin/bash
set -e

# 根据角色启动Flink服务
case "$1" in
    jobmanager)
        echo "Starting Flink JobManager..."
        exec $FLINK_HOME/bin/jobmanager.sh start-foreground
        ;;
    taskmanager)
        echo "Starting Flink TaskManager..."
        exec $FLINK_HOME/bin/taskmanager.sh start-foreground
        ;;
    *)
        echo "Usage: $0 {jobmanager|taskmanager}"
        exit 1
        ;;
esac