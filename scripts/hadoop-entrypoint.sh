#!/bin/bash

# 启动 SSH 服务
/etc/init.d/ssh start

# 替换配置文件（如果挂载了外部配置）
if [ -d "/config/hadoop" ]; then
    cp -f /config/hadoop/* $HADOOP_CONF_DIR/
fi

# 根据传入的参数决定启动什么服务
if [ "$1" = "namenode" ]; then
    # 格式化 NameNode (幂等操作)
    if [ ! -d "/opt/hadoop/data/dfs/name" ]; then
        echo "Formatting NameNode..."
        $HADOOP_HOME/bin/hdfs namenode -format -force -nonInteractive
    fi
    
    echo "Starting NameNode..."
    $HADOOP_HOME/bin/hdfs --daemon start namenode
    
    echo "Starting ResourceManager..."
    $HADOOP_HOME/bin/yarn --daemon start resourcemanager
    
    echo "Starting JobHistoryServer..."
    $HADOOP_HOME/bin/mapred --daemon start historyserver
    
elif [ "$1" = "datanode" ]; then
    echo "Starting DataNode..."
    $HADOOP_HOME/bin/hdfs --daemon start datanode
    
    echo "Starting NodeManager..."
    $HADOOP_HOME/bin/yarn --daemon start nodemanager
fi

# 保持容器运行
tail -f /dev/null
