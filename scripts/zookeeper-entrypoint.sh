#!/bin/bash

# ===============================================
# ZooKeeper分布式协调服务启动脚本
# 作用：启动ZooKeeper服务，配置集群参数和节点标识
# 原理：根据环境变量配置ZooKeeper集群，确保节点正确加入集群
# 重要性：ZooKeeper是分布式系统的核心，确保集群协调和一致性
# ===============================================

# ===============================================
# 基础服务启动
# 作用：启动SSH服务，用于容器间通信和远程管理
# 原理：ZooKeeper集群节点间需要通过SSH进行健康检查
# 重要性：确保集群节点间的通信和故障检测正常
# ===============================================

# 启动 SSH 服务
/etc/init.d/ssh start

# ===============================================
# 动态配置加载
# 作用：如果挂载了外部配置文件，则覆盖默认配置
# 原理：支持配置热更新，便于调试和配置管理
# 配置内容：zoo.cfg等ZooKeeper核心配置文件
# ===============================================

# 替换配置文件（如果挂载了外部配置）
if [ -d "/config/zookeeper" ]; then
    echo "加载外部ZooKeeper配置文件..."
    cp -f /config/zookeeper/* $ZOO_HOME/conf/
fi

# ===============================================
# 默认配置创建（容错机制）
# 作用：如果没有配置文件，则使用默认配置创建
# 原理：确保ZooKeeper服务在任何情况下都能启动
# 配置内容：基于zoo_sample.cfg创建基础配置
# ===============================================

# 如果没有 zoo.cfg，则使用默认配置
if [ ! -f "$ZOO_HOME/conf/zoo.cfg" ]; then
    echo "创建默认ZooKeeper配置文件..."
    cp $ZOO_HOME/conf/zoo_sample.cfg $ZOO_HOME/conf/zoo.cfg
    echo "dataDir=/opt/zookeeper/data" >> $ZOO_HOME/conf/zoo.cfg
    echo "dataLogDir=/opt/zookeeper/datalog" >> $ZOO_HOME/conf/zoo.cfg
fi

# ===============================================
# 节点标识配置
# 作用：设置ZooKeeper节点的唯一标识符（myid）
# 原理：每个ZooKeeper节点必须有唯一的ID，用于集群协调
# 重要性：myid文件是ZooKeeper集群成员身份的关键标识
# ===============================================

# 设置 myid
if [ ! -z "$ZOO_MY_ID" ]; then
    echo "设置ZooKeeper节点标识: $ZOO_MY_ID"
    echo "${ZOO_MY_ID}" > /opt/zookeeper/data/myid
fi

# ===============================================
# ZooKeeper服务启动
# 作用：启动ZooKeeper服务进程
# 原理：使用start-foreground模式在前台运行，便于容器管理
# 启动模式：前台运行确保容器能正确监控服务状态
# ===============================================

echo "Starting Zookeeper..."
$ZOO_HOME/bin/zkServer.sh start-foreground
