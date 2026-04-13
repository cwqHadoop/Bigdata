# 大数据分布式服务实验平台

本项目旨在 Windows WSL (Ubuntu) 环境下，使用 Docker 和 Docker Compose 从零开始构建一个完整的大数据分布式服务实验平台。

## 核心架构设计

1. **镜像体积最小化**：所有组件镜像均基于一个轻量级的 `bigdata-base` 基础镜像构建，该基础镜像仅包含 OpenJDK 8、SSH 服务及必要的网络工具。
2. **配置文件分离**：所有组件的配置文件（如 `core-site.xml`, `server.properties` 等）均通过外部 volume 挂载，存放在宿主机 `/config` 目录下，实现配置与镜像解耦。
3. **模块化启动**：针对不同集群（Hadoop, Spark, Flink, Kafka 等）提供独立的 `docker-compose-<cluster>.yml` 文件，支持按需启动。
4. **幂等性操作**：所有的运维脚本（启动、初始化、清理）均设计为幂等，多次执行不会导致系统错误。

## 目录结构说明

```text
/
├── config/             # 所有集群的配置文件（按集群子目录划分，如 hadoop/, spark/, kafka/）
├── module/             # 存放安装包（需自行下载 tar.gz 放入）
├── scripts/            # 运维脚本（init.sh, start.sh, stop.sh, destroy.sh）
├── test/               # 各组件健康检查与功能测试脚本
├── dockerfile.base     # 基础镜像构建文件
├── dockerfile.<name>   # 各组件镜像构建文件
├── docker-compose.<name>.yml # 各集群的编排文件
├── manage.sh           # 总控管理脚本
└── README.md           # 项目启动与使用说明
```

## 包含的集群组件

1. **基础镜像 (Base Image)**: 基于 `ubuntu:focal-slim`，包含 JDK 8 和 SSH 免密登录。
2. **标准 Hadoop 集群**: 1个 NameNode, 2个 DataNode。
3. **HA Hadoop 集群**: 2个 NameNode, 2个 DataNode, 3个 JournalNode, 3个 ZooKeeper。
4. **消息与采集**: Flume 节点, Kafka 集群。
5. **计算引擎**: Spark 集群 (Standalone 模式), Flink 集群。
6. **数据仓库**: Hive 集群 (基于 Hadoop 集群，使用 MySQL 作为元数据库)。

## 使用指南

### 1. 准备安装包
请将所需的 Hadoop, Spark, Flink 等安装包下载并放入 `module/` 目录下。

### 2. 构建基础镜像
```bash
docker build -t bigdata-base:latest -f dockerfile.base .
```

### 3. 使用总控脚本管理集群
*(待后续阶段完善 `manage.sh` 后提供详细命令)*
