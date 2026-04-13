# Module目录文件列表

本文件记录了`module`目录中所有安装文件的信息。这些文件由于体积较大，已通过`.gitignore`排除在Git版本控制之外。

## 📁 Module目录文件清单

| 序号 | 文件名 | 文件大小 | 用途说明 |
|------|--------|----------|----------|
| 1 | `apache-flume-1.9.0-bin.tar.gz` | 67.9 MB | Flume数据采集工具安装包 |
| 2 | `apache-hive-3.1.2-bin.tar.gz` | 278.8 MB | Hive数据仓库安装包 |
| 3 | `apache-kylin-4.0.0-bin-spark3.tar.gz` | 197.9 MB | Kylin OLAP分析引擎 |
| 4 | `apache-maven-3.6.3-bin.tar.gz` | 9.5 MB | Maven构建工具 |
| 5 | `apache-zookeeper-3.6.3-bin.tar.gz` | 12.5 MB | ZooKeeper协调服务 |
| 6 | `clickhouse-client-21.9.4.35.tgz` | 82.7 KB | ClickHouse客户端工具 |
| 7 | `clickhouse-common-static-21.9.4.35.tgz` | 188.7 MB | ClickHouse通用组件 |
| 8 | `clickhouse-common-static-dbg-21.9.4.35.tgz` | 856.5 MB | ClickHouse调试版本 |
| 9 | `clickhouse-server-21.9.4.35.tgz` | 103.5 KB | ClickHouse服务器 |
| 10 | `flink-1.14.0-bin-scala_2.12.tar` | 374.6 MB | Flink流处理引擎 |
| 11 | `guava-27.0-jre.jar` | 2.7 MB | Google Guava工具库 |
| 12 | `hadoop-3.1.3.tar.gz` | 338.1 MB | Hadoop分布式计算框架 |
| 13 | `hbase-2.2.3-bin.tar.gz` | 223.5 MB | HBase NoSQL数据库 |
| 14 | `hudi-0.11.0.src.tgz` | 2.9 MB | Hudi数据湖框架 |
| 15 | `jdk-8u212-linux-x64.tar.gz` | 195.0 MB | Java开发工具包 |
| 16 | `kafka_2.12-2.4.1.tgz` | 62.4 MB | Kafka消息队列 |
| 17 | `mysql-connector-java-5.1.49.jar` | 1.0 MB | MySQL JDBC驱动 |
| 18 | `redis-6.2.6.tar.gz` | 2.5 MB | Redis内存数据库 |
| 19 | `spark-3.1.1-bin-hadoop3.2.tgz` | 228.7 MB | Spark计算引擎 |
| 20 | `sqoop-1.4.7.bin__hadoop-2.6.0.tar.gz` | 17.9 MB | Sqoop数据迁移工具 |

## 📊 文件分类统计

### 🔧 大数据计算框架
- **Hadoop**: 1个文件 (338.1 MB)
- **Spark**: 1个文件 (228.7 MB)
- **Flink**: 1个文件 (374.6 MB)

### 💾 数据存储组件
- **HBase**: 1个文件 (223.5 MB)
- **ClickHouse**: 4个文件 (1.0 GB)
- **Redis**: 1个文件 (2.5 MB)

### 📡 数据采集与消息
- **Flume**: 1个文件 (67.9 MB)
- **Kafka**: 1个文件 (62.4 MB)

### 📊 数据仓库与分析
- **Hive**: 1个文件 (278.8 MB)
- **Kylin**: 1个文件 (197.9 MB)
- **Hudi**: 1个文件 (2.9 MB)
- **Sqoop**: 1个文件 (17.9 MB)

### 🔗 基础服务与工具
- **ZooKeeper**: 1个文件 (12.5 MB)
- **JDK**: 1个文件 (195.0 MB)
- **Maven**: 1个文件 (9.5 MB)
- **MySQL驱动**: 1个文件 (1.0 MB)
- **Guava库**: 1个文件 (2.7 MB)

## 📈 总体统计

- **文件总数**: 20个文件
- **总大小**: 约 3.1 GB
- **最大文件**: `clickhouse-common-static-dbg-21.9.4.35.tgz` (856.5 MB)
- **最小文件**: `clickhouse-client-21.9.4.35.tgz` (82.7 KB)

## 🔄 文件获取说明

这些文件可以通过以下方式获取：

1. **官方下载**: 从各项目的官方网站下载
2. **镜像站点**: 使用国内镜像站点加速下载
3. **版本管理**: 确保版本与Dockerfile中指定的版本一致

## ⚠️ 注意事项

1. 这些文件不包含在Git版本控制中
2. 需要手动下载并放置到`module`目录
3. 下载时请确保文件完整性（校验MD5/SHA256）
4. 版本更新时需要同步更新Dockerfile中的版本号

---
*最后更新时间: 2026-04-13*