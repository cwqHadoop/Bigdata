#!/bin/bash

set -e

# 设置环境变量
source /etc/profile

# 设置默认环境变量
export SPARK_HOME=${SPARK_HOME:-/opt/spark}
export HADOOP_CONF_DIR=${HADOOP_CONF_DIR:-/opt/spark/conf}

# 加载环境配置
if [ -f /config/environment.conf ]; then
    source /config/environment.conf
fi

# 设置默认Hadoop环境
export HADOOP_ENVIRONMENT=${HADOOP_ENVIRONMENT:-ha}

# 创建Hadoop配置目录
mkdir -p $HADOOP_CONF_DIR

# 复制Spark配置文件
cp -r /config/spark/* $SPARK_HOME/conf/

# 根据环境配置复制Hadoop配置文件
echo "Using Hadoop environment: $HADOOP_ENVIRONMENT"
if [ "$HADOOP_ENVIRONMENT" = "ha" ]; then
    echo "Copying Hadoop HA configuration..."
    cp -r /config/hadoop-ha/* $HADOOP_CONF_DIR/
    # 设置HA环境的HDFS nameservice
    export HDFS_NAMESERVICE="hdfs://mycluster"
elif [ "$HADOOP_ENVIRONMENT" = "standard" ]; then
    echo "Copying standard Hadoop configuration..."
    cp -r /config/hadoop/* $HADOOP_CONF_DIR/
    # 设置标准环境的HDFS nameservice
    export HDFS_NAMESERVICE="hdfs://namenode:8020"
else
    echo "Warning: Unknown Hadoop environment '$HADOOP_ENVIRONMENT', using HA configuration as default"
    cp -r /config/hadoop-ha/* $HADOOP_CONF_DIR/
    export HDFS_NAMESERVICE="hdfs://mycluster"
fi

# 动态生成Spark配置文件
echo "Generating Spark configuration files..."

# 生成spark-defaults.conf
if [ -f /config/spark/spark-defaults.conf.template ]; then
    # 使用不同的分隔符避免路径中的斜杠冲突
    sed "s|{{HDFS_NAMESERVICE}}|$HDFS_NAMESERVICE|g" /config/spark/spark-defaults.conf.template > $SPARK_HOME/conf/spark-defaults.conf
    echo "Generated spark-defaults.conf with HDFS nameservice: $HDFS_NAMESERVICE"
else
    echo "Warning: spark-defaults.conf.template not found, using static configuration"
    cp -r /config/spark/* $SPARK_HOME/conf/
fi

# 生成spark-env.sh
if [ -f /config/spark/spark-env.sh.template ]; then
    # 使用不同的分隔符避免路径中的斜杠冲突
    sed "s|{{HDFS_NAMESERVICE}}|$HDFS_NAMESERVICE|g" /config/spark/spark-env.sh.template > $SPARK_HOME/conf/spark-env.sh
    echo "Generated spark-env.sh with HDFS nameservice: $HDFS_NAMESERVICE"
else
    echo "Warning: spark-env.sh.template not found, using static configuration"
    cp -r /config/spark/* $SPARK_HOME/conf/
fi

# 确保HADOOP_CONF_DIR在classpath中
export SPARK_DIST_CLASSPATH=$(hadoop classpath 2>/dev/null || echo "$HADOOP_CONF_DIR")

# 等待Hadoop服务就绪（最多等待60秒）
echo "Waiting for Hadoop services to be ready..."
for i in {1..60}; do
    if hdfs dfs -test -d / 2>/dev/null; then
        echo "HDFS is ready!"
        # 创建Spark日志目录
        hdfs dfs -mkdir -p /spark-logs 2>/dev/null && echo "HDFS log directory created successfully"
        break
    else
        echo "Waiting for HDFS... (attempt $i/60)"
        sleep 1
    fi
done

# 如果HDFS不可用，禁用事件日志
export SPARK_EVENTLOG_ENABLED=$(hdfs dfs -test -d / 2>/dev/null && echo "true" || echo "false")
if [ "$SPARK_EVENTLOG_ENABLED" = "false" ]; then
    echo "HDFS not available, disabling event logging"
fi

# 根据角色启动服务
case "$ROLE" in
    "master")
        echo "Starting Spark Master..."
        $SPARK_HOME/sbin/start-master.sh
        echo "Starting Spark History Server..."
        $SPARK_HOME/sbin/start-history-server.sh
        # 保持容器运行
        tail -f $SPARK_HOME/logs/*
        ;;
    "worker")
        echo "Waiting for Spark Master to start..."
        sleep 30
        echo "Starting Spark Worker..."
        $SPARK_HOME/sbin/start-worker.sh spark://spark-master:7077
        # 保持容器运行
        tail -f $SPARK_HOME/logs/*
        ;;
    *)
        echo "Unknown role: $ROLE"
        exit 1
        ;;
esac