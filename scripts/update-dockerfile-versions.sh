#!/bin/bash

set -e

echo "=== 更新 Dockerfile 版本配置 ==="

# 读取环境配置文件
ENV_CONF="config/environment.conf"
if [ ! -f "$ENV_CONF" ]; then
    echo "错误: 环境配置文件 $ENV_CONF 不存在"
    exit 1
fi

echo "1. 读取环境配置文件..."
# 读取版本信息
eval $(grep -E '^[A-Z_]+_VERSION=' "$ENV_CONF")

# 显示读取的版本信息
echo "读取到的版本信息:"
grep -E '^[A-Z_]+_VERSION=' "$ENV_CONF"
echo

# Dockerfile 列表
DOCKERFILES=(
    "dockerfile.hadoop"
    "dockerfile.hive"
    "dockerfile.spark"
    "dockerfile.hbase"
    "dockerfile.zookeeper"
    "dockerfile.kafka"
    "dockerfile.flink"
    "dockerfile.flume"
)

# 组件下载URL映射
declare -A DOWNLOAD_URLS=(
    ["hadoop"]="https://archive.apache.org/dist/hadoop/core/hadoop-{VERSION}/hadoop-{VERSION}.tar.gz"
    ["hive"]="https://archive.apache.org/dist/hive/hive-{VERSION}/apache-hive-{VERSION}-bin.tar.gz"
    ["spark"]="https://archive.apache.org/dist/spark/spark-{VERSION}/spark-{VERSION}-bin-hadoop3.2.tgz"
    ["hbase"]="https://archive.apache.org/dist/hbase/{VERSION}/hbase-{VERSION}-bin.tar.gz"
    ["zookeeper"]="https://archive.apache.org/dist/zookeeper/zookeeper-{VERSION}/apache-zookeeper-{VERSION}-bin.tar.gz"
    ["kafka"]="https://archive.apache.org/dist/kafka/{VERSION}/kafka_2.12-{VERSION}.tgz"
    ["flink"]="https://archive.apache.org/dist/flink/flink-{VERSION}/flink-{VERSION}-bin-scala_2.12.tgz"
    ["flume"]="https://archive.apache.org/dist/flume/{VERSION}/apache-flume-{VERSION}-bin.tar.gz"
)

# 检查并下载缺失的组件安装包
echo "2. 检查并下载缺失的组件安装包..."
for component in hadoop hive spark hbase zookeeper kafka flink flume; do
    version_var="${component^^}_VERSION"
    version="${!version_var}"
    
    if [ -n "$version" ]; then
        # 根据组件类型确定文件名
        case "$component" in
            "hadoop")
                filename="hadoop-${version}.tar.gz"
                ;;
            "hive")
                filename="apache-hive-${version}-bin.tar.gz"
                ;;
            "spark")
                filename="spark-${version}-bin-hadoop3.2.tgz"
                ;;
            "hbase")
                filename="hbase-${version}-bin.tar.gz"
                ;;
            "zookeeper")
                filename="apache-zookeeper-${version}-bin.tar.gz"
                ;;
            "kafka")
                filename="kafka_2.12-${version}.tgz"
                ;;
            "flink")
                filename="flink-${version}-bin-scala_2.12.tgz"
                ;;
            "flume")
                filename="apache-flume-${version}-bin.tar.gz"
                ;;
        esac
        
        filepath="module/$filename"
        
        if [ ! -f "$filepath" ]; then
            echo "  - $component $version: 文件不存在，开始下载..."
            
            # 获取下载URL
            url_template="${DOWNLOAD_URLS[$component]}"
            url="${url_template//\{VERSION\}/$version}"
            
            # 检查网络连接
            if ! ping -c 1 -W 3 archive.apache.org >/dev/null 2>&1; then
                echo "    警告: 网络不可用，跳过下载"
                continue
            fi
            
            # 下载文件
            if command -v wget >/dev/null 2>&1; then
                if wget -O "$filepath" "$url" 2>/dev/null; then
                    if [ -f "$filepath" ]; then
                        echo "    ✓ 下载成功: $filename"
                    else
                        echo "    ✗ 下载失败: 文件未创建"
                    fi
                else
                    echo "    ✗ 下载失败: 网络错误"
                    rm -f "$filepath" 2>/dev/null
                fi
            elif command -v curl >/dev/null 2>&1; then
                if curl -L -o "$filepath" "$url" 2>/dev/null; then
                    if [ -f "$filepath" ]; then
                        echo "    ✓ 下载成功: $filename"
                    else
                        echo "    ✗ 下载失败: 文件未创建"
                    fi
                else
                    echo "    ✗ 下载失败: 网络错误"
                    rm -f "$filepath" 2>/dev/null
                fi
            else
                echo "    错误: 未找到 wget 或 curl 命令，无法下载"
                continue
            fi
        else
            echo "  - $component $version: 文件已存在"
        fi
    fi
done

echo

# 更新每个 Dockerfile
echo "3. 开始更新 Dockerfile..."
for dockerfile in "${DOCKERFILES[@]}"; do
    if [ ! -f "$dockerfile" ]; then
        echo "警告: $dockerfile 不存在，跳过"
        continue
    fi
    
    echo "处理: $dockerfile"
    
    # 创建临时文件
    temp_file="${dockerfile}.tmp"
    
    # 根据不同的 Dockerfile 进行不同的处理
    case "$dockerfile" in
        "dockerfile.hadoop")
            if [ -n "$HADOOP_VERSION" ]; then
                sed -E "s/^(ENV HADOOP_VERSION=).*/ENV HADOOP_VERSION=${HADOOP_VERSION}/" "$dockerfile" > "$temp_file"
                mv "$temp_file" "$dockerfile"
                echo "  - 更新 HADOOP_VERSION: $HADOOP_VERSION"
            fi
            ;;
        "dockerfile.hive")
            if [ -n "$HIVE_VERSION" ]; then
                sed -E "s/^(ENV HIVE_VERSION=).*/ENV HIVE_VERSION=${HIVE_VERSION}/" "$dockerfile" > "$temp_file"
                mv "$temp_file" "$dockerfile"
                echo "  - 更新 HIVE_VERSION: $HIVE_VERSION"
            fi
            ;;
        "dockerfile.spark")
            if [ -n "$SPARK_VERSION" ]; then
                sed -E "s/^(ENV SPARK_VERSION=).*/ENV SPARK_VERSION=${SPARK_VERSION}/" "$dockerfile" > "$temp_file"
                mv "$temp_file" "$dockerfile"
                echo "  - 更新 SPARK_VERSION: $SPARK_VERSION"
            fi
            ;;
        "dockerfile.hbase")
            if [ -n "$HBASE_VERSION" ]; then
                sed -E "s/^(ENV HBASE_VERSION=).*/ENV HBASE_VERSION=${HBASE_VERSION}/" "$dockerfile" > "$temp_file"
                mv "$temp_file" "$dockerfile"
                echo "  - 更新 HBASE_VERSION: $HBASE_VERSION"
            fi
            ;;
        "dockerfile.zookeeper")
            if [ -n "$ZOOKEEPER_VERSION" ]; then
                sed -E "s/^(ENV ZOOKEEPER_VERSION=).*/ENV ZOOKEEPER_VERSION=${ZOOKEEPER_VERSION}/" "$dockerfile" > "$temp_file"
                mv "$temp_file" "$dockerfile"
                echo "  - 更新 ZOOKEEPER_VERSION: $ZOOKEEPER_VERSION"
            fi
            ;;
        "dockerfile.kafka")
            if [ -n "$KAFKA_VERSION" ]; then
                sed -E "s/^(ENV KAFKA_VERSION=).*/ENV KAFKA_VERSION=${KAFKA_VERSION}/" "$dockerfile" > "$temp_file"
                mv "$temp_file" "$dockerfile"
                echo "  - 更新 KAFKA_VERSION: $KAFKA_VERSION"
            fi
            ;;
        "dockerfile.flink")
            # Flink 版本处理
            if [ -n "$FLINK_VERSION" ]; then
                sed -E "s/^(ENV FLINK_VERSION=).*/ENV FLINK_VERSION=${FLINK_VERSION}/" "$dockerfile" > "$temp_file"
                mv "$temp_file" "$dockerfile"
                echo "  - 更新 FLINK_VERSION: $FLINK_VERSION"
            fi
            ;;
        "dockerfile.flume")
            # Flume 版本处理
            if [ -n "$FLUME_VERSION" ]; then
                sed -E "s/^(ENV FLUME_VERSION=).*/ENV FLUME_VERSION=${FLUME_VERSION}/" "$dockerfile" > "$temp_file"
                mv "$temp_file" "$dockerfile"
                echo "  - 更新 FLUME_VERSION: $FLUME_VERSION"
            fi
            ;;
    esac
    
    # 清理临时文件
    rm -f "$temp_file"
done

echo "4. 版本更新完成！"
echo

echo "=== 验证版本一致性 ==="
echo "环境配置文件中的版本:"
grep -E '^[A-Z_]+_VERSION=' "$ENV_CONF"
echo
echo "各 Dockerfile 中的版本:"
for dockerfile in "${DOCKERFILES[@]}"; do
    if [ -f "$dockerfile" ]; then
        echo "$dockerfile:"
        grep -E '^ENV [A-Z_]+_VERSION=' "$dockerfile" 2>/dev/null || echo "  (未找到版本配置)"
    fi
done

echo
echo "=== 组件安装包检查 ==="
echo "module 目录中的安装包文件:"
ls -la module/ 2>/dev/null || echo "  module 目录不存在或为空"