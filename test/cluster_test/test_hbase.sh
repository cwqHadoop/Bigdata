#!/bin/bash

# ===============================================
# HBase功能测试脚本
# 作用：测试HBase分布式数据库的功能
# ===============================================

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志和输出函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [HBase测试] $1" | tee -a "$LOG_FILE"
}

print_info() {
    echo -e "${BLUE}[HBase测试]${NC} $1"
    log "[INFO] $1"
}

print_success() {
    echo -e "${GREEN}[HBase测试]${NC} $1"
    log "[SUCCESS] $1"
}

print_warning() {
    echo -e "${YELLOW}[HBase测试]${NC} $1"
    log "[WARNING] $1"
}

print_error() {
    echo -e "${RED}[HBase测试]${NC} $1"
    log "[ERROR] $1"
}

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/hbase-test-$(date +%Y%m%d-%H%M%S).log"

# 创建日志目录
mkdir -p "$LOG_DIR"

# 测试结果统计
total_tests=0
success_tests=0

# 测试HBase服务状态
test_hbase_services() {
    print_info "1. 测试HBase服务状态..."
    
    local services=("hbase-master" "hbase-regionserver")
    local service_names=("HBase Master" "HBase RegionServer")
    
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

# 测试HBase基本功能
test_hbase_basic() {
    print_info "2. 测试HBase基本功能..."
    
    # 创建测试表
    local create_table_cmd="create 'test_table', 'cf'"
    if docker exec master bash -c "echo '$create_table_cmd' | /opt/hbase/bin/hbase shell" > /dev/null 2>&1; then
        print_success "   ✓ HBase表创建成功"
        ((success_tests++))
    else
        print_error "   ✗ HBase表创建失败"
    fi
    ((total_tests++))
    
    # 插入测试数据
    local put_data_cmd="put 'test_table', 'row1', 'cf:col1', 'value1'"
    if docker exec master bash -c "echo '$put_data_cmd' | /opt/hbase/bin/hbase shell" > /dev/null 2>&1; then
        print_success "   ✓ HBase数据插入成功"
        ((success_tests++))
    else
        print_error "   ✗ HBase数据插入失败"
    fi
    ((total_tests++))
    
    # 查询测试数据
    local get_data_cmd="get 'test_table', 'row1'"
    if docker exec master bash -c "echo '$get_data_cmd' | /opt/hbase/bin/hbase shell" 2>/dev/null | grep -q "value1"; then
        print_success "   ✓ HBase数据查询成功"
        ((success_tests++))
    else
        print_error "   ✗ HBase数据查询失败"
    fi
    ((total_tests++))
    
    # 扫描测试数据
    local scan_cmd="scan 'test_table'"
    if docker exec master bash -c "echo '$scan_cmd' | /opt/hbase/bin/hbase shell" > /dev/null 2>&1; then
        print_success "   ✓ HBase数据扫描成功"
        ((success_tests++))
    else
        print_error "   ✗ HBase数据扫描失败"
    fi
    ((total_tests++))
    
    # 删除测试数据
    local delete_cmd="delete 'test_table', 'row1', 'cf:col1'"
    if docker exec master bash -c "echo '$delete_cmd' | /opt/hbase/bin/hbase shell" > /dev/null 2>&1; then
        print_success "   ✓ HBase数据删除成功"
        ((success_tests++))
    else
        print_error "   ✗ HBase数据删除失败"
    fi
    ((total_tests++))
    
    # 删除测试表
    local disable_cmd="disable 'test_table'"
    local drop_cmd="drop 'test_table'"
    if docker exec master bash -c "echo '$disable_cmd; $drop_cmd' | /opt/hbase/bin/hbase shell" > /dev/null 2>&1; then
        print_success "   ✓ HBase表删除成功"
        ((success_tests++))
    else
        print_error "   ✗ HBase表删除失败"
    fi
    ((total_tests++))
}

# 测试HBase Web UI
test_hbase_webui() {
    print_info "3. 测试HBase Web UI..."
    
    # 检查HBase Master Web UI
    if curl -s http://localhost:16010/master-status > /dev/null 2>&1; then
        print_success "   ✓ HBase Master Web UI可访问"
        ((success_tests++))
    else
        print_warning "   ⚠ HBase Master Web UI无法访问（可能是网络配置问题）"
    fi
    ((total_tests++))
}

# 主函数
main() {
    print_info "开始HBase功能测试..."
    
    # 记录开始时间
    local start_time=$(date +%s)
    
    # 执行测试
    test_hbase_services
    test_hbase_basic
    test_hbase_webui
    
    # 计算测试结果
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    local success_rate=0
    if [ $total_tests -gt 0 ]; then
        success_rate=$((success_tests * 100 / total_tests))
    fi
    
    print_info "=== HBase测试结果 ==="
    print_info "总测试项: $total_tests"
    print_info "成功项: $success_tests"
    print_info "成功率: ${success_rate}%"
    print_info "测试耗时: ${duration}秒"
    
    if [ $success_rate -ge 80 ]; then
        print_success "✓ HBase功能测试: 通过"
        exit 0
    else
        print_error "✗ HBase功能测试: 失败"
        exit 1
    fi
}

# 执行主函数
main "$@"