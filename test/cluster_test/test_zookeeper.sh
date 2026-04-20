#!/bin/bash

# ===============================================
# ZooKeeper功能测试脚本
# 作用：测试ZooKeeper分布式协调服务的功能
# ===============================================

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志和输出函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ZooKeeper测试] $1" | tee -a "$LOG_FILE"
}

print_info() {
    echo -e "${BLUE}[ZooKeeper测试]${NC} $1"
    log "[INFO] $1"
}

print_success() {
    echo -e "${GREEN}[ZooKeeper测试]${NC} $1"
    log "[SUCCESS] $1"
}

print_warning() {
    echo -e "${YELLOW}[ZooKeeper测试]${NC} $1"
    log "[WARNING] $1"
}

print_error() {
    echo -e "${RED}[ZooKeeper测试]${NC} $1"
    log "[ERROR] $1"
}

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/zookeeper-test-$(date +%Y%m%d-%H%M%S).log"

# 创建日志目录
mkdir -p "$LOG_DIR"

# 测试结果统计
total_tests=0
success_tests=0

# 测试ZooKeeper服务状态
test_zookeeper_services() {
    print_info "1. 测试ZooKeeper服务状态..."
    
    local workers=("worker-1" "worker-2" "worker-3")
    
    for worker in "${workers[@]}"; do
        if docker exec "$worker" supervisorctl status zookeeper 2>/dev/null | grep -q "RUNNING"; then
            print_success "   ✓ $worker 节点ZooKeeper服务运行正常"
            ((success_tests++))
        else
            print_error "   ✗ $worker 节点ZooKeeper服务异常"
        fi
        ((total_tests++))
    done
}

# 测试ZooKeeper集群连接
test_zookeeper_connection() {
    print_info "2. 测试ZooKeeper集群连接..."
    
    local workers=("worker-1" "worker-2" "worker-3")
    
    for worker in "${workers[@]}"; do
        if docker exec "$worker" /opt/zookeeper/bin/zkCli.sh -server "$worker:2181" -timeout 5000 ls / > /dev/null 2>&1; then
            print_success "   ✓ $worker 节点ZooKeeper连接正常"
            ((success_tests++))
        else
            print_error "   ✗ $worker 节点ZooKeeper连接失败"
        fi
        ((total_tests++))
    done
}

# 测试ZooKeeper节点数据
test_zookeeper_data() {
    print_info "3. 测试ZooKeeper节点数据..."
    
    # 检查系统节点
    local zk_nodes=$(docker exec worker-1 /opt/zookeeper/bin/zkCli.sh -server worker-1:2181 ls / 2>/dev/null | grep -oE '[a-z]+' | tr '\n' ' ')
    
    if [[ -n "$zk_nodes" ]]; then
        print_success "   ✓ ZooKeeper系统节点存在: $zk_nodes"
        ((success_tests++))
    else
        print_error "   ✗ ZooKeeper系统节点为空"
    fi
    ((total_tests++))
    
    # 检查关键节点
    local required_nodes=("brokers" "cluster" "hbase" "zookeeper")
    for node in "${required_nodes[@]}"; do
        if echo "$zk_nodes" | grep -q "$node"; then
            print_success "   ✓ 关键节点 $node 存在"
            ((success_tests++))
        else
            print_warning "   ⚠ 关键节点 $node 不存在（可能是正常情况）"
        fi
        ((total_tests++))
    done
}

# 测试ZooKeeper集群一致性
test_zookeeper_consistency() {
    print_info "4. 测试ZooKeeper集群一致性..."
    
    # 创建测试节点
    if docker exec worker-1 /opt/zookeeper/bin/zkCli.sh -server worker-1:2181 -timeout 5000 create /test_consistency "test_data" > /dev/null 2>&1; then
        print_success "   ✓ 测试节点创建成功"
        ((success_tests++))
    else
        print_error "   ✗ 测试节点创建失败"
    fi
    ((total_tests++))
    
    # 检查各节点数据一致性
    local workers=("worker-1" "worker-2" "worker-3")
    local consistent=true
    
    for worker in "${workers[@]}"; do
        local data=$(docker exec "$worker" /opt/zookeeper/bin/zkCli.sh -server "$worker:2181" -timeout 5000 get /test_consistency 2>/dev/null | grep "test_data")
        if [[ -n "$data" ]]; then
            print_success "   ✓ $worker 节点数据一致"
        else
            print_error "   ✗ $worker 节点数据不一致"
            consistent=false
        fi
        ((total_tests++))
    done
    
    if [[ "$consistent" == "true" ]]; then
        print_success "   ✓ 集群数据一致性验证通过"
        ((success_tests++))
    else
        print_error "   ✗ 集群数据一致性验证失败"
    fi
    ((total_tests++))
    
    # 清理测试节点
    docker exec worker-1 /opt/zookeeper/bin/zkCli.sh -server worker-1:2181 -timeout 5000 delete /test_consistency > /dev/null 2>&1
}

# 主函数
main() {
    print_info "开始ZooKeeper功能测试..."
    
    # 记录开始时间
    local start_time=$(date +%s)
    
    # 执行测试
    test_zookeeper_services
    test_zookeeper_connection
    test_zookeeper_data
    test_zookeeper_consistency
    
    # 计算测试结果
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    local success_rate=0
    if [ $total_tests -gt 0 ]; then
        success_rate=$((success_tests * 100 / total_tests))
    fi
    
    print_info "=== ZooKeeper测试结果 ==="
    print_info "总测试项: $total_tests"
    print_info "成功项: $success_tests"
    print_info "成功率: ${success_rate}%"
    print_info "测试耗时: ${duration}秒"
    
    if [ $success_rate -ge 80 ]; then
        print_success "✓ ZooKeeper功能测试: 通过"
        exit 0
    else
        print_error "✗ ZooKeeper功能测试: 失败"
        exit 1
    fi
}

# 执行主函数
main "$@"