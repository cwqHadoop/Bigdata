# HBase数据库测试说明

## 📋 测试脚本
- **文件**: `test-hbase.sh`
- **测试对象**: HBase数据库集群
- **依赖组件**: HBase Master, HBase RegionServer, ZooKeeper集群

## 🎯 测试目的
验证HBase数据库的基本操作功能和集群协调机制。

## 🔧 测试内容

### 1. 集群状态检查
- 检查HBase Master和RegionServer容器状态
- 验证ZooKeeper连接状态
- 检查HBase集群协调状态

### 2. 数据库操作测试
- 创建测试表
- 执行数据插入、查询、更新操作
- 验证表结构和数据一致性

### 3. 集群功能验证
- 测试Region分布和负载均衡
- 验证数据复制机制
- 检查监控和管理功能

## ✅ 预期结果

### 集群状态
- ✅ HBase Master服务正常运行
- ✅ RegionServer节点正常注册
- ✅ ZooKeeper连接正常

### 数据库操作
- ✅ 表创建成功
- ✅ 数据操作（增删改查）正常
- ✅ 数据一致性保持

### 集群功能
- ✅ Region分布合理
- ✅ 负载均衡机制正常
- ✅ 监控功能可用

## 📊 测试指标

| 测试项目 | 预期结果 | 实际结果 | 状态 |
|----------|----------|----------|------|
| 容器状态检查 | Master和RegionServer正常运行 | - | - |
| 表创建 | 成功创建测试表 | - | - |
| 数据操作 | 增删改查操作成功 | - | - |
| 集群协调 | Region分布和负载均衡正常 | - | - |

## 🔍 故障排查

### 常见问题
1. **RegionServer注册失败**：检查ZooKeeper连接和资源配置
2. **表操作失败**：检查表结构和权限配置
3. **数据不一致**：检查复制机制和日志同步

### 日志位置
- HBase Master日志：容器内 `/opt/hbase/logs/`
- RegionServer日志：容器内 `/opt/hbase/logs/`
- ZooKeeper日志：容器内 `/opt/zookeeper/logs/`

---
*最后更新时间: 2026-04-13*