# Hadoop集群测试说明

## 📋 测试脚本
- **文件**: `test-hadoop.sh`
- **测试对象**: 标准Hadoop集群
- **依赖组件**: NameNode, DataNode

## 🎯 测试目的
验证标准Hadoop集群的基本功能，包括HDFS文件系统操作和YARN资源管理。

## 🔧 测试内容

### 1. 容器状态检查
- 检查NameNode和DataNode容器是否正常运行
- 验证容器网络连接状态

### 2. HDFS功能测试
- 创建测试目录和文件
- 执行文件上传、下载、删除操作
- 验证HDFS权限和副本机制

### 3. YARN功能测试
- 检查ResourceManager和NodeManager状态
- 提交简单的MapReduce作业
- 验证作业执行和资源分配

## ✅ 预期结果

### 容器状态
- ✅ NameNode容器正常运行
- ✅ DataNode容器正常运行
- ✅ 容器间网络通信正常

### HDFS操作
- ✅ 文件系统操作成功（创建、上传、下载、删除）
- ✅ 文件副本机制正常工作
- ✅ 权限控制正常

### YARN功能
- ✅ ResourceManager服务正常
- ✅ NodeManager服务正常
- ✅ MapReduce作业成功执行

## 📊 测试指标

| 测试项目 | 预期结果 | 实际结果 | 状态 |
|----------|----------|----------|------|
| 容器状态检查 | 所有容器正常运行 | - | - |
| HDFS目录创建 | 成功创建测试目录 | - | - |
| 文件上传下载 | 文件操作成功 | - | - |
| YARN作业提交 | 作业成功执行 | - | - |

## 🔍 故障排查

### 常见问题
1. **容器启动失败**：检查Docker日志和资源限制
2. **HDFS操作失败**：检查NameNode日志和磁盘空间
3. **YARN作业失败**：检查ResourceManager日志和资源分配

### 日志位置
- NameNode日志：容器内 `/opt/hadoop/logs/`
- DataNode日志：容器内 `/opt/hadoop/logs/`
- YARN日志：容器内 `/opt/hadoop/logs/`

## 📝 测试记录

### 测试时间
- 首次测试：2026-04-13
- 最近测试：2026-04-13

### 测试环境
- 操作系统：Windows WSL (Ubuntu)
- Docker版本：最新稳定版
- Hadoop版本：3.1.3

---
*最后更新时间: 2026-04-13*