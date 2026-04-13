#!/bin/bash

# 设置环境变量
export HBASE_HOME=/opt/hbase
export PATH=$HBASE_HOME/bin:$PATH

echo "Starting HBase services..."

# 配置DNS解析 - 使用Docker内置DNS
echo "Configuring DNS resolution..."
# Docker会自动处理容器间的DNS解析，无需手动配置/etc/hosts
# 使用容器名称进行服务发现，确保可扩展性

# 复制配置文件
cp -r /config/hbase/* $HBASE_HOME/conf/

# 设置Hadoop配置路径
export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop

# 复制正确的Hadoop配置文件到容器中
if [ -f /config/environment.conf ]; then
    source /config/environment.conf
fi

export HADOOP_ENVIRONMENT=${HADOOP_ENVIRONMENT:-standard}

echo "Using Hadoop environment: $HADOOP_ENVIRONMENT"
if [ "$HADOOP_ENVIRONMENT" = "ha" ]; then
    echo "Copying Hadoop HA configuration..."
    cp -r /config/hadoop-ha/* $HADOOP_CONF_DIR/
    # 动态配置 HBase rootdir 为 HA 模式
    sed -i 's|HBASE_ROOTDIR_PLACEHOLDER|hdfs://mycluster/hbase|g' $HBASE_HOME/conf/hbase-site.xml
elif [ "$HADOOP_ENVIRONMENT" = "standard" ]; then
    echo "Copying standard Hadoop configuration..."
    cp -r /config/hadoop/* $HADOOP_CONF_DIR/
    # 动态配置 HBase rootdir 为 Standard 模式
    sed -i 's|HBASE_ROOTDIR_PLACEHOLDER|hdfs://namenode:8020/hbase|g' $HBASE_HOME/conf/hbase-site.xml
else
    echo "Warning: Unknown Hadoop environment '$HADOOP_ENVIRONMENT', using HA configuration as default"
    cp -r /config/hadoop-ha/* $HADOOP_CONF_DIR/
    sed -i 's|HBASE_ROOTDIR_PLACEHOLDER|hdfs://mycluster/hbase|g' $HBASE_HOME/conf/hbase-site.xml
fi

# 等待Hadoop服务就绪
echo "Waiting for Hadoop services to be ready..."
for i in {1..60}; do
    if /opt/hadoop/bin/hdfs dfs -test -d / > /dev/null 2>&1; then
        echo "HDFS is ready!"
        break
    fi
    echo "Waiting for HDFS... (attempt $i/60)"
    sleep 2
    if [ $i -eq 60 ]; then
        echo "Error: HDFS not ready after 120 seconds"
        exit 1
    fi
done

# 创建HBase在HDFS上的目录
echo "Creating HBase directories in HDFS..."
hdfs dfs -mkdir -p /hbase
hdfs dfs -chmod 755 /hbase

# 启动HBase Master服务
echo "Starting HBase Master..."
$HBASE_HOME/bin/hbase-daemon.sh start master

# 如果是RegionServer节点，启动RegionServer
if [[ "$HOSTNAME" == *"regionserver"* ]]; then
    echo "Starting HBase RegionServer..."
    $HBASE_HOME/bin/hbase-daemon.sh start regionserver
fi

# 等待HBase服务完全启动
echo "Waiting for HBase services to be fully ready..."
for i in {1..30}; do
    if $HBASE_HOME/bin/hbase shell -e "status" 2>/dev/null | grep -q "active master"; then
        echo "HBase is ready!"
        break
    fi
    echo "Waiting for HBase... (attempt $i/30)"
    sleep 5
    if [ $i -eq 30 ]; then
        echo "Warning: HBase not fully ready after 150 seconds, but continuing..."
    fi
done

# 检查HBase状态
echo "Checking HBase status..."
$HBASE_HOME/bin/hbase shell -e "status"

echo "HBase services started successfully!"

# 保持容器运行
tail -f /dev/null