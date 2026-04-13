# Flink流处理测试说明

## 📋 测试脚本
- **文件**: `test-flink.sh`
- **测试对象**: Flink集群
- **依赖组件**: Flink JobManager, Flink TaskManager

## 🎯 测试目的
验证Flink集群的流处理能力和集群管理功能。

## 🔧 测试内容

### 1. 集群状态检查
- 检查JobManager和TaskManager容器状态
- 验证TaskManager注册状态
- 检查集群资源分配

### 2. 集群管理功能
- 使用Flink CLI检查集群状态
- 验证Web UI可访问性
- 检查任务槽位分配

### 3. 基本功能验证
- 检查Flink版本信息
- 验证集群连接状态
- 测试YARN集成（如果配置）

## ✅ 预期结果

### 集群状态
- ✅ JobManager服务正常运行
- ✅ TaskManager节点正常注册
- ✅ 集群资源分配正确

### 管理功能
- ✅ Flink CLI命令执行成功
- ✅ Web UI可通过 http://localhost:18081 访问
- ✅ 任务槽位分配正常

### 基本功能
- ✅ Flink版本信息正确
- ✅ 集群连接状态正常
- ✅ 基础功能验证通过

## 📊 测试指标

| 测试项目 | 预期结果 | 实际结果 | 状态 |
|----------|----------|----------|------|
| 容器状态检查 | JobManager和TaskManager正常运行 | - | - |
| Web UI访问 | 可通过18081端口访问 | - | - |
| CLI命令执行 | flink list命令成功 | - | - |
| 集群状态 | 集群状态正常 | - | - |

## 🔍 故障排查

### 常见问题
1. **TaskManager注册失败**：检查网络连接和资源配置
2. **Web UI无法访问**：检查端口映射和防火墙
3. **CLI命令失败**：检查集群连接状态

### 日志位置
- JobManager日志：容器内 `/opt/flink/log/`
- TaskManager日志：容器内 `/opt/flink/log/`
- Web UI：http://localhost:18081

---
*最后更新时间: 2026-04-13*