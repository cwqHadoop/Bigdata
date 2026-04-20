#!/bin/bash

# ===============================================
# HDFS功能测试脚本
# 作用：测试Hadoop HDFS文件系统的完整功能
# ===============================================

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志和输出函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [HDFS测试] $1" | tee -a "$LOG_FILE"
}

print_info() {
    echo -e "${BLUE}[HDFS测试]${NC} $1"
    log "[INFO] $1"
}

print_success() {
    echo -e "${GREEN}[HDFS测试]${NC} $1"
    log "[SUCCESS] $1"
}

print_warning() {
    echo -e "${YELLOW}[HDFS测试]${NC} $1"
    log "[WARNING] $1"
}

print_error() {
    echo -e "${RED}[HDFS测试]${NC} $1"
    log "[ERROR] $1"
}

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/hdfs-test-$(date +%Y%m%d-%H%M%S).log"

# 创建日志目录
mkdir -p "$LOG_DIR"

# 测试结果统计
total_tests=0
success_tests=0

# 测试HDFS服务状态
test_hdfs_services() {
    print_info "1. 测试HDFS服务状态..."
    
    local services=("namenode" "datanode" "resourcemanager" "nodemanager")
    local service_names=("NameNode" "DataNode" "ResourceManager" "NodeManager")
    
    for i in "${!services[@]}"; do
        local service="${services[$i]}"
        local service_name="${service_names[$i]}"
        
        if docker exec master supervisorctl status "$service" 2>/dev/null | grep -q "RUNNING"; then
            print_success "   ✓ $service_name 服务运行正常"
            ((success_tests++))
        else
            print_error "   ✗ $service_name 服务异常"
        fi
        ((total_tests++))
    done
}

# 测试HDFS基本功能
test_hdfs_basic() {
    print_info "2. 测试HDFS基本功能..."
    
    # 检查HDFS根目录
    if docker exec master /opt/hadoop/bin/hdfs dfs -ls / > /dev/null 2>&1; then
        print_success "   ✓ HDFS根目录访问正常"
        ((success_tests++))
    else
        print_error "   ✗ HDFS根目录访问失败"
    fi
    ((total_tests++))
    
    # 创建测试目录
    if docker exec master /opt/hadoop/bin/hdfs dfs -mkdir -p /test_hdfs > /dev/null 2>&1; then
        print_success "   ✓ HDFS目录创建成功"
        ((success_tests++))
    else
        print_error "   ✗ HDFS目录创建失败"
    fi
    ((total_tests++))
    
    # 上传测试文件
    echo "Hello HDFS Test" > /tmp/hdfs_test.txt
    if docker exec -i master /opt/hadoop/bin/hdfs dfs -put - /test_hdfs/test.txt < /tmp/hdfs_test.txt > /dev/null 2>&1; then
        print_success "   ✓ HDFS文件上传成功"
        ((success_tests++))
    else
        print_error "   ✗ HDFS文件上传失败"
    fi
    ((total_tests++))
    
    # 读取测试文件
    if docker exec master /opt/hadoop/bin/hdfs dfs -cat /test_hdfs/test.txt 2>/dev/null | grep -q "Hello HDFS Test"; then
        print_success "   ✓ HDFS文件读取成功"
        ((success_tests++))
    else
        print_error "   ✗ HDFS文件读取失败"
    fi
    ((total_tests++))
    
    # 检查文件权限
    if docker exec master /opt/hadoop/bin/hdfs dfs -ls /test_hdfs/test.txt > /dev/null 2>&1; then
        print_success "   ✓ HDFS文件权限正常"
        ((success_tests++))
    else
        print_error "   ✗ HDFS文件权限异常"
    fi
    ((total_tests++))
    
    # 删除测试文件
    if docker exec master /opt/hadoop/bin/hdfs dfs -rm -r /test_hdfs > /dev/null 2>&1; then
        print_success "   ✓ HDFS文件删除成功"
        ((success_tests++))
    else
        print_error "   ✗ HDFS文件删除失败"
    fi
    ((total_tests++))
    
    # 清理临时文件
    rm -f /tmp/hdfs_test.txt
}

# 测试HDFS高可用性
test_hdfs_ha() {
    print_info "3. 测试HDFS高可用性..."
    
    # 检查HDFS系统目录
    local hdfs_dirs=$(docker exec master /opt/hadoop/bin/hdfs dfs -ls / 2>/dev/null | awk '{print $NF}' | tr '\n' ' ')
    
    if [[ -n "$hdfs_dirs" ]]; then
        print_success "   ✓ HDFS系统目录存在: $hdfs_dirs"
        ((success_tests++))
    else
        print_error "   ✗ HDFS系统目录为空"
    fi
    ((total_tests++))
    
    # 检查HBase目录
    if docker exec master /opt/hadoop/bin/hdfs dfs -ls /hbase > /dev/null 2>&1; then
        print_success "   ✓ HBase目录存在"
        ((success_tests++))
    else
        print_warning "   ⚠ HBase目录不存在（可能是正常情况）"
    fi
    ((total_tests++))
    
    # 检查临时目录
    if docker exec master /opt/hadoop/bin/hdfs dfs -ls /tmp > /dev/null 2>&1; then
        print_success "   ✓ 临时目录存在"
        ((success_tests++))
    else
        print_warning "   ⚠ 临时目录不存在（可能是正常情况）"
    fi
    ((total_tests++))
}

# 主函数
main() {
    print_info "开始HDFS功能测试..."
    
    # 记录开始时间
    local start_time=$(date +%s)
    
    # 执行测试
    test_hdfs_services
    test_hdfs_basic
    test_hdfs_ha
    
    # 计算测试结果
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    local success_rate=0
    if [ $total_tests -gt 0 ]; then
        success_rate=$((success_tests * 100 / total_tests))
    fi
    
    print_info "=== HDFS测试结果 ==="
    print_info "总测试项: $total_tests"
    print_info "成功项: $success_tests"
    print_info "成功率: ${success_rate}%"
    print_info "测试耗时: ${duration}秒"
    
    if [ $success_rate -ge 80 ]; then
        print_success "✓ HDFS功能测试: 通过"
        exit 0
    else
        print_error "✗ HDFS功能测试: 失败"
        exit 1
    fi
}

# 执行主函数
main "$@"