#!/bin/bash

# 日志文件配置
LOG_DIR="test/test-log"
LOG_FILE="$LOG_DIR/test-hadoop-$(date +%Y%m%d-%H%M%S).log"

# 创建日志目录
mkdir -p "$LOG_DIR"

# 日志函数
log() {
    echo "$1" | tee -a "$LOG_FILE"
}

log "=== Hadoop 基础集群测试 ==="
log "测试开始时间: $(date)"
log "日志文件: $LOG_FILE"
log ""

# 读取 Hadoop 版本号
ENV_CONF="../config/environment.conf"
if [ -f "$ENV_CONF" ]; then
    HADOOP_VERSION=$(grep "^HADOOP_VERSION=" "$ENV_CONF" | cut -d'=' -f2)
    log "使用 Hadoop 版本: $HADOOP_VERSION"
else
    log "警告: 环境配置文件不存在，使用默认版本 3.1.3"
    HADOOP_VERSION="3.1.3"
fi
log ""

# 检查 Hadoop 容器状态
log "1. 检查 Hadoop 容器状态..."
docker ps | grep -E "namenode|datanode" | tee -a "$LOG_FILE"
log ""

# 测试 NameNode Web UI
log "2. 测试 NameNode Web UI 可访问性..."
namenode_status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:19870)
if [ "$namenode_status" = "200" ]; then
    log "✓ NameNode Web UI 正常 (http://localhost:19870)"
else
    log "✗ NameNode Web UI 不可访问 (状态码: $namenode_status)"
fi

# 测试 ResourceManager Web UI
log "3. 测试 ResourceManager Web UI 可访问性..."
rm_status=$(curl -s -L -o /dev/null -w "%{http_code}" http://localhost:18088)
if [ "$rm_status" = "200" ]; then
    log "✓ ResourceManager Web UI 正常 (http://localhost:18088)"
else
    log "⚠ ResourceManager Web UI 返回状态码: $rm_status (可能是重定向)"
fi

# 测试 HDFS 文件系统操作
log "4. 测试 HDFS 文件系统操作..."
log "4.1 检查 HDFS 状态..."
hdfs_status=$(docker exec namenode hdfs dfsadmin -report 2>/dev/null | grep "Live datanodes" | awk '{print $3}')
if [ -n "$hdfs_status" ]; then
    log "✓ HDFS 正常运行，活跃 DataNode 数量: $hdfs_status"
else
    log "✗ HDFS 状态检查失败"
fi

log "4.2 创建测试目录..."
docker exec namenode hdfs dfs -mkdir -p /test/hadoop-test 2>/dev/null
if [ $? -eq 0 ]; then
    log "✓ 测试目录创建成功"
else
    log "✗ 测试目录创建失败"
fi

log "4.3 上传本地文件到 HDFS..."
echo "Hello Hadoop Test" > /tmp/hadoop-test.txt
docker cp /tmp/hadoop-test.txt namenode:/tmp/hadoop-test.txt
docker exec namenode hdfs dfs -put /tmp/hadoop-test.txt /test/hadoop-test/ 2>/dev/null
if [ $? -eq 0 ]; then
    log "✓ 文件上传成功"
else
    log "✗ 文件上传失败"
fi

log "4.4 验证文件存在性..."
file_exists=$(docker exec namenode hdfs dfs -test -e /test/hadoop-test/hadoop-test.txt && echo "exists")
if [ "$file_exists" = "exists" ]; then
    log "✓ 文件存在性验证成功"
else
    log "✗ 文件存在性验证失败"
fi

log "4.5 读取文件内容..."
file_content=$(docker exec namenode hdfs dfs -cat /test/hadoop-test/hadoop-test.txt 2>/dev/null)
if [ "$file_content" = "Hello Hadoop Test" ]; then
    log "✓ 文件内容读取正确"
else
    log "✗ 文件内容读取失败"
fi

# 测试 YARN 资源管理
log "5. 测试 YARN 资源管理..."
log "5.1 检查 YARN 节点状态..."
yarn_nodes_output=$(docker exec namenode yarn node -list 2>/dev/null)
if echo "$yarn_nodes_output" | grep -q "Total Nodes"; then
    yarn_nodes=$(echo "$yarn_nodes_output" | grep "Total Nodes" | awk -F: '{print $2}' | awk '{print $1}' | tr -d '[:space:]')
    log "✓ YARN 节点正常，总节点数: $yarn_nodes"
    log "  节点详情:"
    echo "$yarn_nodes_output" | grep "RUNNING" | sed 's/^/   /' | tee -a "$LOG_FILE"
else
    log "✗ YARN 节点状态检查失败"
    log "  输出: $yarn_nodes_output"
    yarn_nodes=""
fi

log "5.2 检查 YARN 应用状态..."
yarn_apps_output=$(docker exec namenode yarn application -list 2>/dev/null)
if echo "$yarn_apps_output" | grep -q "Total number of applications"; then
    yarn_apps=$(echo "$yarn_apps_output" | grep "Total number of applications" | awk '{print $6}')
    log "✓ YARN 应用管理器正常，应用数量: $yarn_apps"
else
    log "⚠ 当前没有运行的应用"
fi

# 测试 MapReduce 作业
log "6. 测试 MapReduce 作业..."
log "6.1 运行 WordCount 示例作业..."
# 准备测试数据
echo "hello world hello hadoop" > /tmp/input.txt
echo "hadoop mapreduce test" >> /tmp/input.txt
docker cp /tmp/input.txt namenode:/tmp/input.txt

# 上传输入数据到 HDFS
docker exec namenode hdfs dfs -mkdir -p /test/wordcount/input 2>/dev/null
docker exec namenode hdfs dfs -put /tmp/input.txt /test/wordcount/input/ 2>/dev/null

# 运行 WordCount 作业
job_output=$(docker exec namenode hadoop jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-${HADOOP_VERSION}.jar wordcount /test/wordcount/input /test/wordcount/output 2>&1)

if echo "$job_output" | grep -q "completed successfully"; then
    log "✓ MapReduce 作业执行成功"
    
    # 检查作业结果
    log "6.2 检查作业结果..."
    result=$(docker exec namenode hdfs dfs -cat /test/wordcount/output/part-r-00000 2>/dev/null)
    if [ -n "$result" ]; then
        log "✓ 作业结果验证成功"
        log "   作业输出:"
        echo "$result" | sed 's/^/   /' | tee -a "$LOG_FILE"
    else
        log "✗ 作业结果验证失败"
    fi
else
    log "✗ MapReduce 作业执行失败"
    log "  错误信息: $job_output"
fi

# 清理测试数据
log "7. 清理测试数据..."
docker exec namenode hdfs dfs -rm -r -f /test 2>/dev/null
rm -f /tmp/hadoop-test.txt /tmp/input.txt

log "✓ 测试数据清理完成"

# 综合测试结果
log ""
log "=== Hadoop 基础集群测试完成 ==="
log "测试总结:"
log "- NameNode Web UI: $([ "$namenode_status" = "200" ] && echo "✓ 正常" || echo "✗ 异常")"
log "- ResourceManager Web UI: $([ "$rm_status" = "200" ] && echo "✓ 正常" || echo "✗ 异常")"
log "- HDFS 文件系统: $([ -n "$hdfs_status" ] && echo "✓ 正常" || echo "✗ 异常")"
log "- YARN 资源管理: $([ -n "$yarn_nodes" ] && echo "✓ 正常" || echo "✗ 异常")"
log "- MapReduce 作业: $([ -n "$result" ] && echo "✓ 正常" || echo "✗ 异常")"

log ""
log "详细测试报告已生成，所有组件功能验证完成！"

# 记录测试结束时间
log "测试结束时间: $(date)"
log "测试结果已保存到: $LOG_FILE"