#!/bin/bash

# 启动 SSH 服务
/etc/init.d/ssh start

# 替换配置文件（如果挂载了外部配置）
if [ -d "/config/zookeeper" ]; then
    cp -f /config/zookeeper/* $ZOO_HOME/conf/
fi

# 如果没有 zoo.cfg，则使用默认配置
if [ ! -f "$ZOO_HOME/conf/zoo.cfg" ]; then
    cp $ZOO_HOME/conf/zoo_sample.cfg $ZOO_HOME/conf/zoo.cfg
    echo "dataDir=/opt/zookeeper/data" >> $ZOO_HOME/conf/zoo.cfg
    echo "dataLogDir=/opt/zookeeper/datalog" >> $ZOO_HOME/conf/zoo.cfg
fi

# 设置 myid
if [ ! -z "$ZOO_MY_ID" ]; then
    echo "${ZOO_MY_ID}" > /opt/zookeeper/data/myid
fi

echo "Starting Zookeeper..."
$ZOO_HOME/bin/zkServer.sh start-foreground
