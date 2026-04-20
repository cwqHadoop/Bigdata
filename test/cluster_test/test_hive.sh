#!/bin/bash

# ===============================================
# Hive功能测试脚本
# 作用：测试Hive数据仓库的功能
# ===============================================

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志和输出函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [Hive测试] $1" | tee -a "$LOG_FILE"
}

print_info() {
    echo -e "${BLUE}[Hive测试]${NC} $1"
    log "[INFO] $1"
}

print_success() {
    echo -e "${GREEN}[Hive测试]${NC} $1"
    log "[SUCCESS] $1"
}

print_warning() {
    echo -e "${YELLOW}[Hive测试]${NC} $1"
    log "[WARNING] $1"
}

print_error() {
    echo -e "${RED}[Hive测试]${NC} $1"
    log "[ERROR] $1"
}

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/hive-test-$(date +%Y%m%d-%H%M%S).log"

# 创建日志目录
mkdir -p "$LOG_DIR"

# 测试结果统计
total_tests=0
success_tests=0

# 测试Hive服务状态
test_hive_services() {
    print_info "1. 测试Hive服务状态..."
    
    local services=("hive-metastore" "hive-server2")
    local service_names=("Hive Metastore" "Hive Server2")
    
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

# 测试Hive基本功能
test_hive_basic() {
    print_info "2. 测试Hive基本功能..."
    
    # 检查数据库列表
    if docker exec master /opt/hive/bin/hive -e "show databases;" > /dev/null 2>&1; then
        print_success "   ✓ Hive数据库查询成功"
        ((success_tests++))
    else
        print_error "   ✗ Hive数据库查询失败"
    fi
    ((total_tests++))
    
    # 创建测试数据库
    if docker exec master /opt/hive/bin/hive -e "create database if not exists test_db;" > /dev/null 2>&1; then
        print_success "   ✓ Hive数据库创建成功"
        ((success_tests++))
    else
        print_error "   ✗ Hive数据库创建失败"
    fi
    ((total_tests++))
    
    # 使用测试数据库
    if docker exec master /opt/hive/bin/hive -e "use test_db;" > /dev/null 2>&1; then
        print_success "   ✓ Hive数据库切换成功"
        ((success_tests++))
    else
        print_error "   ✗ Hive数据库切换失败"
    fi
    ((total_tests++))
    
    # 创建测试表
    local create_table_sql="create table if not exists test_table (id int, name string) row format delimited fields terminated by ',';"
    if docker exec master /opt/hive/bin/hive -e "$create_table_sql" > /dev/null 2>&1; then
        print_success "   ✓ Hive表创建成功"
        ((success_tests++))
    else
        print_error "   ✗ Hive表创建失败"
    fi
    ((total_tests++))
    
    # 插入测试数据
    local insert_sql="insert into test_table values (1, 'test1'), (2, 'test2');"
    if docker exec master /opt/hive/bin/hive -e "$insert_sql" > /dev/null 2>&1; then
        print_success "   ✓ Hive数据插入成功"
        ((success_tests++))
    else
        print_error "   ✗ Hive数据插入失败"
    fi
    ((total_tests++))
    
    # 查询测试数据
    if docker exec master /opt/hive/bin/hive -e "select * from test_table;" 2>/dev/null | grep -q "test1"; then
        print_success "   ✓ Hive数据查询成功"
        ((success_tests++))
    else
        print_error "   ✗ Hive数据查询失败"
    fi
    ((total_tests++))
    
    # 删除测试表
    if docker exec master /opt/hive/bin/hive -e "drop table test_table;" > /dev/null 2>&1; then
        print_success "   ✓ Hive表删除成功"
        ((success_tests++))
    else
        print_error "   ✗ Hive表删除失败"
    fi
    ((total_tests++))
    
    # 删除测试数据库
    if docker exec master /opt/hive/bin/hive -e "drop database if exists test_db;" > /dev/null 2>&1; then
        print_success "   ✓ Hive数据库删除成功"
        ((success_tests++))
    else
        print_error "   ✗ Hive数据库删除失败"
    fi
    ((total_tests++))
}

# 测试Hive Metastore连接
test_hive_metastore() {
    print_info "3. 测试Hive Metastore连接..."
    
    # 检查Metastore连接
    if docker exec master /opt/hive/bin/hive -e "show databases;" > /dev/null 2>&1; then
        print_success "   ✓ Hive Metastore连接正常"
        ((success_tests++))
    else
        print_error "   ✗ Hive Metastore连接失败"
    fi
    ((total_tests++))
    
    # 检查MySQL连接（如果使用外部MySQL）
    if docker exec master netstat -an | grep -q "3306"; then
        print_success "   ✓ MySQL连接正常"
        ((success_tests++))
    else
        print_warning "   ⚠ MySQL连接检查失败（可能是使用嵌入式数据库）"
    fi
    ((total_tests++))
}

# 主函数
main() {
    print_info "开始Hive功能测试..."
    
    # 记录开始时间
    local start_time=$(date +%s)
    
    # 执行测试
    test_hive_services
    test_hive_basic
    test_hive_metastore
    
    # 计算测试结果
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    local success_rate=0
    if [ $total_tests -gt 0 ]; then
        success_rate=$((success_tests * 100 / total_tests))
    fi
    
    print_info "=== Hive测试结果 ==="
    print_info "总测试项: $total_tests"
    print_info "成功项: $success_tests"
    print_info "成功率: ${success_rate}%"
    print_info "测试耗时: ${duration}秒"
    
    if [ $success_rate -ge 80 ]; then
        print_success "✓ Hive功能测试: 通过"
        exit 0
    else
        print_error "✗ Hive功能测试: 失败"
        exit 1
    fi
}

# 执行主函数
main "$@"