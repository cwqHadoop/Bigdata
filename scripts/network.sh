#!/bin/bash

# 创建大数据平台共享网络
NETWORK_NAME="bigdata-net"

# 检查网络是否存在
if docker network ls | grep -q "$NETWORK_NAME"; then
    echo "网络 $NETWORK_NAME 已存在"
else
    echo "创建网络 $NETWORK_NAME..."
    docker network create --driver bridge $NETWORK_NAME
    echo "网络 $NETWORK_NAME 创建成功"
fi

# 显示网络信息
echo "网络信息:"
docker network inspect $NETWORK_NAME | grep -E "(Name|Subnet|Gateway)"