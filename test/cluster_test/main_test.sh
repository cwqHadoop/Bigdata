#!/bin/bash

# ===============================================
# 5节点全栈大数据集群功能测试主脚本
# 作用：协调执行所有组件的功能测试
# 原理：依次调用各组件测试脚本并汇总结果
# ===============================================

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志和输出函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    log "[INFO] $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    log "[SUCCESS] $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    log "[WARNING] $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    log "[ERROR] $1"
}

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/cluster-test-$(date +%Y%m%d-%H%M%S).log"

# 创建日志目录
mkdir -p "$LOG_DIR"

# 测试结果统计
total_tests=0
success_tests=0
failed_tests=0

# 测试函数
run_test() {
    local test_name="$1"
    local test_script="$2"
    
    print_info "执行测试: $test_name"
    
    if [ -f "$test_script" ]; then
        if bash "$test_script" 2>&1 | tee -a "$LOG_FILE"; then
            print_success "$test_name 测试通过"
            ((success_tests++))
            return 0
        else
            print_error "$test_name 测试失败"
            ((failed_tests++))
            return 1
        fi
    else
        print_error "测试脚本不存在: $test_script"
        ((failed_tests++))
        return 1
    fi
    
    ((total_tests++))
}

# 检查集群状态
check_cluster_status() {
    print_info "检查集群容器状态..."
    
    # 检查Docker API是否正常
    if ! docker ps > /dev/null 2>&1; then
        print_error "Docker API不可用，请检查Docker服务状态"
        return 1
    fi
    
    # 检查容器是否运行
    local containers=("master" "worker-1" "worker-2" "worker-3" "infra")
    for container in "${containers[@]}"; do
        if docker ps --format "table {{.Names}}" | grep -q "^$container$"; then
            print_success "容器 $container 运行正常"
        else
            print_error "容器 $container 未运行"
            return 1
        fi
    done
    
    return 0
}

# 等待服务启动
wait_services() {
    print_info "等待集群服务启动..."
    
    local max_wait=180
    local wait_time=0
    
    while [ $wait_time -lt $max_wait ]; do
        if docker exec master supervisorctl status > /dev/null 2>&1; then
            print_success "集群服务已启动"
            return 0
        fi
        
        print_info "等待服务启动... ($((wait_time))秒)"
        sleep 10
        ((wait_time += 10))
    done
    
    print_error "服务启动超时"
    return 1
}

# 主测试流程
main() {
    print_success "=== 开始5节点大数据集群功能测试 ==="
    
    # 记录开始时间
    local start_time=$(date +%s)
    
    # 检查集群状态
    if ! check_cluster_status; then
        print_error "集群状态检查失败，无法继续测试"
        exit 1
    fi
    
    # 等待服务启动
    if ! wait_services; then
        print_error "服务启动等待失败，无法继续测试"
        exit 1
    fi
    
    # 执行各组件测试
    print_info "开始执行各组件功能测试..."
    
    # 1. HDFS测试
    run_test "HDFS分布式文件系统" "$SCRIPT_DIR/test_hdfs.sh"
    
    # 2. ZooKeeper测试
    run_test "ZooKeeper分布式协调" "$SCRIPT_DIR/test_zookeeper.sh"
    
    # 3. HBase测试
    run_test "HBase分布式数据库" "$SCRIPT_DIR/test_hbase.sh"
    
    # 4. Hive测试
    run_test "Hive数据仓库" "$SCRIPT_DIR/test_hive.sh"
    
    # 5. Kafka测试
    run_test "Kafka消息队列" "$SCRIPT_DIR/test_kafka.sh"
    
    # 6. Flink测试
    run_test "Flink流处理" "$SCRIPT_DIR/test_flink.sh"
    
    # 计算测试结果
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    print_info "=== 测试结果汇总 ==="
    print_info "总测试项: $total_tests"
    print_info "成功项: $success_tests"
    print_info "失败项: $failed_tests"
    
    local success_rate=0
    if [ $total_tests -gt 0 ]; then
        success_rate=$((success_tests * 100 / total_tests))
    fi
    
    print_info "成功率: ${success_rate}%"
    print_info "测试耗时: ${duration}秒"
    
    # 输出最终结果
    if [ $success_rate -ge 90 ]; then
        print_success "=== 集群功能测试: 优秀 ==="
    elif [ $success_rate -ge 70 ]; then
        print_warning "=== 集群功能测试: 一般 ==="
    else
        print_error "=== 集群功能测试: 需要改进 ==="
    fi
    
    print_info "详细测试报告请查看: $LOG_FILE"
    
    # 根据成功率返回退出码
    if [ $success_rate -ge 80 ]; then
        exit 0
    else
        exit 1
    fi
}

# 信号处理
trap 'print_error "测试被中断"; exit 1' INT TERM

# 执行主函数
main "$@"