#!/bin/bash

# 启动 SSH 服务
/etc/init.d/ssh start

# 替换配置文件（如果挂载了外部配置）
if [ -d "/config/hadoop-ha" ]; then
    cp -f /config/hadoop-ha/* $HADOOP_CONF_DIR/
fi

ROLE=$1

if [ "$ROLE" = "journalnode" ]; then
    echo "Starting JournalNode..."
    $HADOOP_HOME/bin/hdfs --daemon start journalnode

elif [ "$ROLE" = "namenode1" ]; then
    # 等待 JournalNode 启动
    sleep 10
    
    # 格式化 ZKFC (幂等操作)
    if [ ! -f "/opt/hadoop/data/zkfc_formatted" ]; then
        echo "Formatting ZKFC..."
        $HADOOP_HOME/bin/hdfs zkfc -formatZK -force -nonInteractive
        touch /opt/hadoop/data/zkfc_formatted
    fi
    
    # 格式化 NameNode (幂等操作)
    if [ ! -d "/opt/hadoop/data/dfs/name" ]; then
        echo "Formatting NameNode..."
        $HADOOP_HOME/bin/hdfs namenode -format -force -nonInteractive
    fi
    
    echo "Starting NameNode..."
    $HADOOP_HOME/bin/hdfs --daemon start namenode
    
    echo "Starting ZKFC..."
    $HADOOP_HOME/bin/hdfs --daemon start zkfc
    
    echo "Starting ResourceManager..."
    $HADOOP_HOME/bin/yarn --daemon start resourcemanager
    
    echo "Starting JobHistoryServer..."
    $HADOOP_HOME/bin/mapred --daemon start historyserver

elif [ "$ROLE" = "namenode2" ]; then
    # 等待 NameNode1 启动并格式化完成
    sleep 20
    
    # 同步 NameNode1 的元数据 (幂等操作)
    if [ ! -d "/opt/hadoop/data/dfs/name" ]; then
        echo "Syncing NameNode metadata from namenode1..."
        $HADOOP_HOME/bin/hdfs namenode -bootstrapStandby -force -nonInteractive
    fi
    
    echo "Starting NameNode..."
    $HADOOP_HOME/bin/hdfs --daemon start namenode
    
    echo "Starting ZKFC..."
    $HADOOP_HOME/bin/hdfs --daemon start zkfc
    
    echo "Starting ResourceManager..."
    $HADOOP_HOME/bin/yarn --daemon start resourcemanager

elif [ "$ROLE" = "datanode" ]; then
    # 等待 NameNode 启动
    sleep 30
    
    # 设置必要的环境变量以修复 MapReduce AM 启动失败的问题
    # 注意：HADOOP_HOME、HADOOP_CONF_DIR 已在Dockerfile中设置，这里只设置缺失的变量
    echo "export HADOOP_MAPRED_HOME=/opt/hadoop" >> /etc/profile
    echo "export YARN_CONF_DIR=/opt/hadoop/etc/hadoop" >> /etc/profile
    echo "export HADOOP_CLASSPATH=\$($HADOOP_HOME/bin/hadoop classpath)" >> /etc/profile
    source /etc/profile
    
    # 配置Hadoop环境文件
    echo "export HADOOP_MAPRED_HOME=/opt/hadoop" >> $HADOOP_CONF_DIR/hadoop-env.sh
    echo "export YARN_CONF_DIR=/opt/hadoop/etc/hadoop" >> $HADOOP_CONF_DIR/hadoop-env.sh
    echo "export HADOOP_CLASSPATH=\$($HADOOP_HOME/bin/hadoop classpath)" >> $HADOOP_CONF_DIR/hadoop-env.sh
    
    # 配置YARN环境文件
    echo "export HADOOP_MAPRED_HOME=/opt/hadoop" >> $HADOOP_CONF_DIR/yarn-env.sh
    echo "export YARN_CONF_DIR=/opt/hadoop/etc/hadoop" >> $HADOOP_CONF_DIR/yarn-env.sh
    echo "export HADOOP_CLASSPATH=\$($HADOOP_HOME/bin/hadoop classpath)" >> $HADOOP_CONF_DIR/yarn-env.sh
    
    echo "Starting DataNode..."
    $HADOOP_HOME/bin/hdfs --daemon start datanode
    
    echo "Starting NodeManager..."
    $HADOOP_HOME/bin/yarn --daemon start nodemanager
fi

# 保持容器运行
tail -f /dev/null
