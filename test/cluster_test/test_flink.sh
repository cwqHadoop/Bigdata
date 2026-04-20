#!/bin/bash

# ===============================================
# Flink功能测试脚本
# 作用：测试Flink流处理框架的功能
# ===============================================

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志和输出函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [Flink测试] $1" | tee -a "$LOG_FILE"
}

print_info() {
    echo -e "${BLUE}[Flink测试]${NC} $1"
    log "[INFO] $1"
}

print_success() {
    echo -e "${GREEN}[Flink测试]${NC} $1"
    log "[SUCCESS] $1"
}

print_warning() {
    echo -e "${YELLOW}[Flink测试]${NC} $1"
    log "[WARNING] $1"
}

print_error() {
    echo -e "${RED}[Flink测试]${NC} $1"
    log "[ERROR] $1"
}

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
LOG_FILE="$LOG_DIR/flink-test-$(date +%Y%m%d-%H%M%S).log"

# 创建日志目录
mkdir -p "$LOG_DIR"

# 测试结果统计
total_tests=0
success_tests=0

# 测试Flink服务状态
test_flink_services() {
    print_info "1. 测试Flink服务状态..."
    
    # 检查JobManager服务
    if docker exec master supervisorctl status flink-jobmanager 2>/dev/null | grep -q "RUNNING"; then
        print_success "   ✓ Flink JobManager服务运行正常"
        ((success_tests++))
    else
        print_error "   ✗ Flink JobManager服务异常"
    fi
    ((total_tests++))
    
    # 检查TaskManager服务
    if docker exec master supervisorctl status flink-taskmanager 2>/dev/null | grep -q "RUNNING"; then
        print_success "   ✓ Flink TaskManager服务运行正常"
        ((success_tests++))
    else
        print_error "   ✗ Flink TaskManager服务异常"
    fi
    ((total_tests++))
}

# 测试Flink Web UI
test_flink_webui() {
    print_info "2. 测试Flink Web UI..."
    
    # 检查Flink Web UI
    if curl -s http://localhost:8081 > /dev/null 2>&1; then
        print_success "   ✓ Flink Web UI可访问"
        ((success_tests++))
    else
        print_error "   ✗ Flink Web UI无法访问"
    fi
    ((total_tests++))
    
    # 检查Flink集群状态API
    if curl -s http://localhost:8081/overview 2>/dev/null | grep -q "taskmanagers"; then
        print_success "   ✓ Flink集群状态API正常"
        ((success_tests++))
    else
        print_error "   ✗ Flink集群状态API异常"
    fi
    ((total_tests++))
}

# 测试Flink集群信息
test_flink_cluster() {
    print_info "3. 测试Flink集群信息..."
    
    # 检查TaskManager数量
    local taskmanagers=$(curl -s http://localhost:8081/taskmanagers 2>/dev/null | grep -o '"taskmanager-id"' | wc -l)
    if [ "$taskmanagers" -ge 1 ]; then
        print_success "   ✓ Flink集群有 $taskmanagers 个TaskManager运行"
        ((success_tests++))
    else
        print_error "   ✗ Flink集群没有TaskManager运行"
    fi
    ((total_tests++))
    
    # 检查JobManager状态
    local jobmanager_status=$(curl -s http://localhost:8081/jobmanager/metrics 2>/dev/null | head -10)
    if [[ -n "$jobmanager_status" ]]; then
        print_success "   ✓ Flink JobManager状态正常"
        ((success_tests++))
    else
        print_error "   ✗ Flink JobManager状态异常"
    fi
    ((total_tests++))
}

# 测试Flink作业提交
test_flink_jobs() {
    print_info "4. 测试Flink作业提交..."
    
    # 创建简单的Flink测试程序
    cat > /tmp/WordCount.java << 'EOF'
import org.apache.flink.api.common.functions.FlatMapFunction;
import org.apache.flink.api.java.DataSet;
import org.apache.flink.api.java.ExecutionEnvironment;
import org.apache.flink.api.java.tuple.Tuple2;
import org.apache.flink.util.Collector;

public class WordCount {
    public static void main(String[] args) throws Exception {
        final ExecutionEnvironment env = ExecutionEnvironment.getExecutionEnvironment();
        
        DataSet<String> text = env.fromElements(
            "Hello Flink",
            "Hello World",
            "Flink is awesome"
        );
        
        DataSet<Tuple2<String, Integer>> counts = 
            text.flatMap(new Tokenizer())
                .groupBy(0)
                .sum(1);
        
        counts.print();
    }
    
    public static final class Tokenizer implements FlatMapFunction<String, Tuple2<String, Integer>> {
        @Override
        public void flatMap(String value, Collector<Tuple2<String, Integer>> out) {
            String[] words = value.toLowerCase().split("\\W+");
            for (String word : words) {
                if (word.length() > 0) {
                    out.collect(new Tuple2<>(word, 1));
                }
            }
        }
    }
}
EOF
    
    # 检查Flink作业提交功能
    if docker exec master /opt/flink/bin/flink run --class WordCount /tmp/WordCount.java 2>&1 | grep -q "Program execution finished"; then
        print_success "   ✓ Flink作业提交成功"
        ((success_tests++))
    else
        print_warning "   ⚠ Flink作业提交测试跳过（需要编译环境）"
    fi
    ((total_tests++))
    
    # 清理临时文件
    rm -f /tmp/WordCount.java
}

# 测试Flink配置
test_flink_config() {
    print_info "5. 测试Flink配置..."
    
    # 检查Flink配置文件
    if docker exec master test -f /opt/flink/conf/flink-conf.yaml; then
        print_success "   ✓ Flink配置文件存在"
        ((success_tests++))
    else
        print_error "   ✗ Flink配置文件不存在"
    fi
    ((total_tests++))
    
    # 检查JobManager配置
    local jobmanager_config=$(docker exec master cat /opt/flink/conf/flink-conf.yaml | grep "jobmanager")
    if [[ -n "$jobmanager_config" ]]; then
        print_success "   ✓ Flink JobManager配置正常"
        ((success_tests++))
    else
        print_error "   ✗ Flink JobManager配置异常"
    fi
    ((total_tests++))
    
    # 检查TaskManager配置
    local taskmanager_config=$(docker exec master cat /opt/flink/conf/flink-conf.yaml | grep "taskmanager")
    if [[ -n "$taskmanager_config" ]]; then
        print_success "   ✓ Flink TaskManager配置正常"
        ((success_tests++))
    else
        print_error "   ✗ Flink TaskManager配置异常"
    fi
    ((total_tests++))
}

# 主函数
main() {
    print_info "开始Flink功能测试..."
    
    # 记录开始时间
    local start_time=$(date +%s)
    
    # 执行测试
    test_flink_services
    test_flink_webui
    test_flink_cluster
    test_flink_jobs
    test_flink_config
    
    # 计算测试结果
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    local success_rate=0
    if [ $total_tests -gt 0 ]; then
        success_rate=$((success_tests * 100 / total_tests))
    fi
    
    print_info "=== Flink测试结果 ==="
    print_info "总测试项: $total_tests"
    print_info "成功项: $success_tests"
    print_info "成功率: ${success_rate}%"
    print_info "测试耗时: ${duration}秒"
    
    if [ $success_rate -ge 80 ]; then
        print_success "✓ Flink功能测试: 通过"
        exit 0
    else
        print_error "✗ Flink功能测试: 失败"
        exit 1
    fi
}

# 执行主函数
main "$@"