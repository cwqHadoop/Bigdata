#!/bin/bash

# ===============================================
# Kafka功能测试脚本
# 作用：测试Kafka消息队列的功能
# ===============================================

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志和输出函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [Kafka测试] $1" | tee -a "$LOG_FILE"
}

print_info() {
    echo -e "${BLUE}[Kafka测试]${NC} $1"
    log "[INFO] $1"
}

print_success() {
    echo -e "${GREEN}[Kafka测试]${NC} $1"
    log "[SUCCESS] $1"
}

print_warning() {
    echo -e "${YELLOW}[Kafka测试]${NC} $1"
    log "[WARNING] $1"
}

print_error() {
    echo -e "${RED}[Kafka测试]${NC} $1"
    log "[ERROR] $1"
}

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/kafka-test-$(date +%Y%m%d-%H%M%S).log"
TEST_TOPIC="test_topic_$(date +%s)"

# 创建日志目录
mkdir -p "$LOG_DIR"

# 测试结果统计
total_tests=0
success_tests=0

# 测试Kafka服务状态
test_kafka_services() {
    print_info "1. 测试Kafka服务状态..."
    
    local workers=("worker-1" "worker-2" "worker-3")
    
    for worker in "${workers[@]}"; do
        if docker exec "$worker" supervisorctl status kafka 2>/dev/null | grep -q "RUNNING"; then
            print_success "   ✓ $worker 节点Kafka服务运行正常"
            ((success_tests++))
        else
            print_error "   ✗ $worker 节点Kafka服务异常"
        fi
        ((total_tests++))
    done
}

# 测试Kafka集群连接
test_kafka_connection() {
    print_info "2. 测试Kafka集群连接..."
    
    # 检查Kafka broker列表
    if docker exec worker-1 /opt/kafka/bin/kafka-broker-api-versions.sh --bootstrap-server worker-1:9092 > /dev/null 2>&1; then
        print_success "   ✓ Kafka broker连接正常"
        ((success_tests++))
    else
        print_error "   ✗ Kafka broker连接失败"
    fi
    ((total_tests++))
    
    # 检查topic列表
    if docker exec worker-1 /opt/kafka/bin/kafka-topics.sh --list --bootstrap-server worker-1:9092 > /dev/null 2>&1; then
        print_success "   ✓ Kafka topic列表查询成功"
        ((success_tests++))
    else
        print_error "   ✗ Kafka topic列表查询失败"
    fi
    ((total_tests++))
}

# 测试Kafka主题操作
test_kafka_topics() {
    print_info "3. 测试Kafka主题操作..."
    
    # 创建测试主题
    if docker exec worker-1 /opt/kafka/bin/kafka-topics.sh --create --topic "$TEST_TOPIC" --partitions 3 --replication-factor 2 --bootstrap-server worker-1:9092 > /dev/null 2>&1; then
        print_success "   ✓ Kafka主题创建成功"
        ((success_tests++))
    else
        print_error "   ✗ Kafka主题创建失败"
    fi
    ((total_tests++))
    
    # 检查主题详情
    if docker exec worker-1 /opt/kafka/bin/kafka-topics.sh --describe --topic "$TEST_TOPIC" --bootstrap-server worker-1:9092 > /dev/null 2>&1; then
        print_success "   ✓ Kafka主题详情查询成功"
        ((success_tests++))
    else
        print_error "   ✗ Kafka主题详情查询失败"
    fi
    ((total_tests++))
    
    # 检查主题列表包含新主题
    if docker exec worker-1 /opt/kafka/bin/kafka-topics.sh --list --bootstrap-server worker-1:9092 | grep -q "$TEST_TOPIC"; then
        print_success "   ✓ Kafka主题列表包含新主题"
        ((success_tests++))
    else
        print_error "   ✗ Kafka主题列表不包含新主题"
    fi
    ((total_tests++))
}

# 测试Kafka消息生产消费
test_kafka_messages() {
    print_info "4. 测试Kafka消息生产消费..."
    
    # 生产测试消息
    local test_message="Test message $(date)"
    if echo "$test_message" | docker exec -i worker-1 /opt/kafka/bin/kafka-console-producer.sh --topic "$TEST_TOPIC" --bootstrap-server worker-1:9092 > /dev/null 2>&1; then
        print_success "   ✓ Kafka消息生产成功"
        ((success_tests++))
    else
        print_error "   ✗ Kafka消息生产失败"
    fi
    ((total_tests++))
    
    # 消费测试消息
    sleep 2  # 等待消息传播
    if docker exec worker-1 timeout 10s /opt/kafka/bin/kafka-console-consumer.sh --topic "$TEST_TOPIC" --from-beginning --bootstrap-server worker-1:9092 --max-messages 1 2>/dev/null | grep -q "Test message"; then
        print_success "   ✓ Kafka消息消费成功"
        ((success_tests++))
    else
        print_error "   ✗ Kafka消息消费失败"
    fi
    ((total_tests++))
}

# 测试Kafka集群配置
test_kafka_config() {
    print_info "5. 测试Kafka集群配置..."
    
    # 检查ZooKeeper连接
    if docker exec worker-1 /opt/kafka/bin/zookeeper-shell.sh worker-1:2181 ls /brokers/ids 2>/dev/null | grep -q "\["; then
        print_success "   ✓ Kafka ZooKeeper连接正常"
        ((success_tests++))
    else
        print_error "   ✗ Kafka ZooKeeper连接失败"
    fi
    ((total_tests++))
    
    # 检查broker状态
    local broker_count=$(docker exec worker-1 /opt/kafka/bin/zookeeper-shell.sh worker-1:2181 ls /brokers/ids 2>/dev/null | grep -oE '[0-9]+' | wc -l)
    if [ "$broker_count" -ge 1 ]; then
        print_success "   ✓ Kafka集群有 $broker_count 个broker运行"
        ((success_tests++))
    else
        print_error "   ✗ Kafka集群没有broker运行"
    fi
    ((total_tests++))
}

# 清理测试资源
cleanup() {
    print_info "清理测试资源..."
    
    # 删除测试主题
    docker exec worker-1 /opt/kafka/bin/kafka-topics.sh --delete --topic "$TEST_TOPIC" --bootstrap-server worker-1:9092 > /dev/null 2>&1
    
    print_success "测试资源清理完成"
}

# 主函数
main() {
    print_info "开始Kafka功能测试..."
    
    # 记录开始时间
    local start_time=$(date +%s)
    
    # 执行测试
    test_kafka_services
    test_kafka_connection
    test_kafka_topics
    test_kafka_messages
    test_kafka_config
    
    # 清理测试资源
    cleanup
    
    # 计算测试结果
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    local success_rate=0
    if [ $total_tests -gt 0 ]; then
        success_rate=$((success_tests * 100 / total_tests))
    fi
    
    print_info "=== Kafka测试结果 ==="
    print_info "总测试项: $total_tests"
    print_info "成功项: $success_tests"
    print_info "成功率: ${success_rate}%"
    print_info "测试耗时: ${duration}秒"
    
    if [ $success_rate -ge 80 ]; then
        print_success "✓ Kafka功能测试: 通过"
        exit 0
    else
        print_error "✗ Kafka功能测试: 失败"
        exit 1
    fi
}

# 信号处理
trap 'cleanup; print_error "测试被中断"; exit 1' INT TERM

# 执行主函数
main "$@"