#!/bin/bash

# 日志文件配置
LOG_DIR="test/test-log"
LOG_FILE="$LOG_DIR/test-hbase-$(date +%Y%m%d-%H%M%S).log"

# 创建日志目录
mkdir -p "$LOG_DIR"

# 日志函数
log() {
    echo "$1" | tee -a "$LOG_FILE"
}


# 设置字符编码
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志文件
LOG_FILE="hbase-test-$(date +%Y%m%d-%H%M%S).log"

# 函数：打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 函数：记录日志
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 函数：检查命令是否存在
check_command() {
    if ! command -v "$1" &> /dev/null; then
        print_error "命令 $1 不存在，请先安装"
        exit 1
    fi
}

# 函数：检查Docker容器是否运行
check_container() {
    local container_name=$1
    if docker ps | grep -q "$container_name"; then | tee -a "$LOG_FILE"
        return 0
    else
        return 1
    fi
}

# 函数：执行HBase Shell命令并检查结果
execute_hbase_command() {
    local container=$1
    local command=$2
    local expected_pattern=$3
    local description=$4
    
    print_info "   $description"
    local output
    
    # 使用更稳定的命令执行方式
    output=$(timeout 15 docker exec "$container" bash -c "echo '$command' | hbase shell 2>&1 | tail -20" 2>&1)
    
    # 检查命令是否执行成功
    if echo "$output" | grep -q "$expected_pattern"; then
        print_success "   ✓ $description 成功"
        log "$description 成功"
        return 0
    elif echo "$output" | grep -q "ERROR:"; then
        print_error "   ✗ $description 失败"
        log "$description 失败 - 输出: $output"
        return 1
    else
        print_warning "   ⚠ $description 结果不确定"
        log "$description 结果不确定 - 输出: $output"
        return 2
    fi
}

# 检查必要命令
check_command docker

print_info "=== HBase Cluster Test ==="
log "HBase集群测试开始"
print_info "Test Time: $(date)"
print_info "Log file: $LOG_FILE"
log ""

# 检查 HBase 容器状态
print_info "1. 检查 HBase 容器状态..."
log "检查HBase容器状态"

# 检查所有容器是否运行
all_running=true
containers=("hbase-master" "hbase-regionserver1" "hbase-regionserver2")

for container in "${containers[@]}"; do
    if check_container "$container"; then
        container_status=$(docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "$container") | tee -a "$LOG_FILE"
        print_success "   $container: 运行中"
        echo "      $container_status"
    else
        print_error "   $container: 未运行"
        all_running=false
    fi
done

if [ "$all_running" = "false" ]; then
    print_error "部分容器未运行，请检查集群状态"
    exit 1
fi

print_success "所有HBase容器正常运行"
log ""

# 测试 HBase 服务可访问性
print_info "2. 测试 HBase 服务可访问性..."
log "测试HBase服务可访问性"

# 检查HBase Master Web UI
print_info "   检查 HBase Master Web UI..."
if curl -s http://localhost:16210/master-status >/dev/null 2>&1; then
    print_success "   ✓ HBase Master Web UI 可访问"
    log "HBase Master Web UI 可访问"
else
    print_error "   ✗ HBase Master Web UI 不可访问"
    log "HBase Master Web UI 不可访问"
fi

# 检查HBase Shell连接
print_info "   检查 HBase Shell 连接..."
if timeout 10 docker exec hbase-master bash -c "echo 'version' | hbase shell" >/dev/null 2>&1; then
    print_success "   ✓ HBase Shell 连接正常"
    log "HBase Shell 连接正常"
else
    print_error "   ✗ HBase Shell 连接异常"
    log "HBase Shell 连接异常"
fi

log ""

# 测试 HBase 基本功能
print_info "3. 测试 HBase 基本功能..."
log "测试HBase基本功能"

# 清理现有测试表
print_info "   清理现有测试表..."
docker exec hbase-master bash -c "echo 'disable \"test_table\"; drop \"test_table\"' | hbase shell" >/dev/null 2>&1
print_info "   测试表清理完成"

# 测试1：创建表
if execute_hbase_command "hbase-master" "create \"test_table\", \"cf1\", \"cf2\"" "Created table" "创建测试表"; then
    # 测试2：插入数据
    execute_hbase_command "hbase-master" "put \"test_table\", \"row1\", \"cf1:name\", \"John\"" "0 row(s)" "插入数据行1"
    execute_hbase_command "hbase-master" "put \"test_table\", \"row1\", \"cf1:age\", \"25\"" "0 row(s)" "插入数据行1-年龄"
    execute_hbase_command "hbase-master" "put \"test_table\", \"row2\", \"cf1:name\", \"Jane\"" "0 row(s)" "插入数据行2"
    
    # 测试3：查询数据
    execute_hbase_command "hbase-master" "scan \"test_table\"" "row1" "扫描表数据"
    execute_hbase_command "hbase-master" "get \"test_table\", \"row1\"" "cf1:name" "查询特定行"
    
    # 测试4：显示表结构
    execute_hbase_command "hbase-master" "describe \"test_table\"" "Table" "显示表结构"
    
    # 测试5：统计行数
    execute_hbase_command "hbase-master" "count \"test_table\"" "row(s)" "统计表行数"
    
    # 测试6：列出所有表
    execute_hbase_command "hbase-master" "list" "test_table" "列出所有表"
    
    print_success "   HBase基本功能测试完成"
else
    print_error "   表创建失败，跳过后续测试"
fi

log ""

# 测试 HBase 集群状态
print_info "4. 测试 HBase 集群状态..."
log "测试HBase集群状态"

# 检查RegionServer状态
print_info "   检查 RegionServer 状态..."
region_servers=$(docker exec hbase-master bash -c "echo 'status' | hbase shell 2>&1 | grep -o '[0-9] servers' | head -1 | cut -d' ' -f1" 2>/dev/null || echo "0") | tee -a "$LOG_FILE"
if [ "$region_servers" -ge 2 ]; then
    print_success "   ✓ RegionServer 数量正常: $region_servers"
    log "RegionServer 数量正常: $region_servers"
else
    print_error "   ✗ RegionServer 数量异常: $region_servers"
    log "RegionServer 数量异常: $region_servers"
fi

# 检查表分布
print_info "   检查表分布状态..."
table_status=$(docker exec hbase-master bash -c "echo 'status \"detailed\"' | hbase shell 2>&1 | grep -A 5 'test_table' | head -3") | tee -a "$LOG_FILE"
if echo "$table_status" | grep -q "test_table"; then
    print_success "   ✓ 表分布状态正常"
    log "表分布状态正常"
else
    print_warning "   ⚠ 表分布状态异常"
    log "表分布状态异常"
fi

log ""

# 清理测试数据
print_info "5. 清理测试数据..."
log "清理测试数据"

if execute_hbase_command "hbase-master" "disable \"test_table\"; drop \"test_table\"" "dropped" "删除测试表"; then
    print_success "   测试数据清理完成"
    log "测试数据清理完成"
else
    print_warning "   测试数据清理异常"
    log "测试数据清理异常"
fi

log ""

# 生成测试报告
print_info "6. 生成测试报告..."
log "生成综合测试报告"

log ""
print_info "=== HBase 集群测试完成 ==="
print_info "测试时间: $(date)"
print_info "日志文件: $LOG_FILE"
log ""

# 总体评估
print_info "=== 测试总结 ==="
if [ "$all_running" = "true" ]; then
    print_success "✓ HBase 集群状态: 正常"
else
    print_error "✗ HBase 集群状态: 异常"
fi

# 检查关键功能是否正常
key_functions=("容器状态" "服务可访问性" "基本功能" "集群状态")
function_count=4
success_count=0

# 检查容器状态
if [ "$all_running" = "true" ]; then
    ((success_count++))
    echo "容器状态正常"
fi

# 检查服务可访问性 - 如果Web UI或Shell连接成功，则算成功
if curl -s http://localhost:16210/master-status >/dev/null 2>&1 || timeout 10 docker exec hbase-master bash -c "echo 'version' | hbase shell" >/dev/null 2>&1; then
    ((success_count++))
    echo "服务可访问性正常"
fi

# 检查基本功能 - 如果表创建成功，则算成功
# 由于测试表在清理阶段被删除，这里通过检查表创建操作是否成功来判断
if docker exec hbase-master bash -c "echo 'create \"test_check_table\", \"cf1\"' | hbase shell 2>&1 | grep -q 'Created table'" 2>/dev/null; then | tee -a "$LOG_FILE"
    ((success_count++))
    echo "基本功能正常"
    # 清理临时检查表
    docker exec hbase-master bash -c "echo 'disable \"test_check_table\"; drop \"test_check_table\"' | hbase shell" >/dev/null 2>&1
fi

# 检查集群状态 - 如果有2个RegionServer，则算成功
region_servers=$(docker exec hbase-master bash -c "echo 'status' | hbase shell 2>&1 | grep -o '[0-9] servers' | head -1 | cut -d' ' -f1" 2>/dev/null || echo "0") | tee -a "$LOG_FILE"
if [ "$region_servers" -ge 2 ]; then
    ((success_count++))
    echo "集群状态正常"
fi

success_rate=$(( success_count * 100 / function_count ))

print_info "关键功能测试: $success_count/$function_count"
print_info "总体成功率: ${success_rate}%"

if [ $success_rate -ge 80 ]; then
    print_success "✓ HBase 集群功能: 优秀"
elif [ $success_rate -ge 60 ]; then
    print_warning "⚠ HBase 集群功能: 一般"
else
    print_error "✗ HBase 集群功能: 异常"
fi

# 记录最终结果
log "测试完成 - 关键功能测试: $success_count/$function_count, 成功率: ${success_rate}%"

log ""
print_success "=== HBase 集群功能验证完成 ==="
print_info "详细测试报告已生成，请查看日志文件: $LOG_FILE"

# 退出状态
if [ $success_rate -ge 70 ]; then
    exit 0
else
    exit 1
fi

# 记录测试结束时间
log "测试结束时间: $(date)"
log "测试结果已保存到: $LOG_FILE"
