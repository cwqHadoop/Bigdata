# 大数据分布式服务实验平台

本项目旨在 Windows WSL (Ubuntu) 环境下，使用 Docker 和 Docker Compose 从零开始构建一个完整的大数据分布式服务实验平台。

## 🎯 项目状态

**✅ 项目已完成并测试通过**

所有组件均已实现并通过功能测试验证，可作为完整的大数据实验平台使用。

## 📊 组件状态概览

| 组件 | 状态 | 测试结果 | 说明 |
|------|------|----------|------|
| **Hadoop集群** | ✅ 正常 | 标准+高可用配置测试通过 | 支持HDFS和YARN |
| **Hive数据仓库** | ✅ 正常 | SQL查询功能测试通过 | 基于MySQL元数据库 |
| **Spark计算引擎** | ✅ 正常 | 批处理任务测试通过 | Standalone模式 |
| **Flink流处理** | ✅ 正常 | 集群状态测试通过 | 支持实时数据处理 |
| **Kafka消息队列** | ✅ 正常 | 消息传输测试通过 | 3节点集群 |
| **Flume数据采集** | ✅ 正常 | Kafka数据传输测试通过 | 仅支持Kafka输出 |
| **ZooKeeper协调** | ✅ 正常 | 集群协调测试通过 | 3节点高可用 |
| **HBase数据库** | ✅ 正常 | 数据库操作测试通过 | NoSQL数据库 |

## 🏗️ 核心架构设计

1. **镜像体积最小化**：所有组件镜像均基于一个轻量级的 `bigdata-base` 基础镜像构建，该基础镜像仅包含 OpenJDK 8、SSH 服务及必要的网络工具。
2. **配置文件分离**：所有组件的配置文件均通过外部 volume 挂载，存放在宿主机 `/config` 目录下，实现配置与镜像解耦。
3. **模块化启动**：针对不同集群提供独立的 `docker-compose-<cluster>.yml` 文件，支持按需启动。
4. **幂等性操作**：所有的运维脚本均设计为幂等，多次执行不会导致系统错误。
5. **完整测试体系**：每个组件都有对应的功能测试脚本，确保系统可靠性。

## 📁 目录结构说明

```text
/
├── config/             # 所有集群的配置文件（按集群子目录划分）
│   ├── environment.conf # 环境配置和版本管理文件
│   ├── module-files.md # module目录文件列表记录
│   └── [cluster]/      # 各集群配置文件
├── module/             # 存放安装包（通过.gitignore排除）
├── scripts/            # 运维脚本和启动脚本
│   ├── update-dockerfile-versions.sh # 版本同步脚本
│   ├── network.sh      # 网络管理脚本
│   └── [component]-entrypoint.sh # 各组件启动脚本
├── test/               # 各组件健康检查与功能测试脚本
│   ├── test-*.sh       # 测试脚本
│   └── test-*.md       # 测试说明文档
├── dockerfile.base     # 基础镜像构建文件
├── dockerfile.<name>   # 各组件镜像构建文件
├── docker-compose.<name>.yml # 各集群的编排文件
└── README.md           # 项目说明文档
```

## 🔧 关键组件说明

### 环境配置文件 (`config/environment.conf`)
这是项目的核心配置文件，用于统一管理所有组件的版本信息和环境设置：

```bash
# 大数据平台环境配置
HADOOP_ENVIRONMENT=standard  # 可选: "ha" 或 "standard"
CLUSTER_NETWORK=bigdata-net  # 集群网络名称

# 组件版本信息（统一管理）
HADOOP_VERSION=3.1.3
SPARK_VERSION=3.1.1
ZOOKEEPER_VERSION=3.6.3
HBASE_VERSION=2.2.3
HIVE_VERSION=3.1.2
FLINK_VERSION=1.14.0
FLUME_VERSION=1.9.0
KAFKA_VERSION=2.4.1
```

**作用：**
- ✅ **版本统一管理** - 所有组件版本集中配置
- ✅ **环境切换** - 支持标准和高可用Hadoop环境切换
- ✅ **网络配置** - 统一管理容器网络
- ✅ **配置一致性** - 确保所有组件使用相同版本

### 版本同步脚本 (`scripts/update-dockerfile-versions.sh`)
自动化版本管理脚本，确保Dockerfile与配置文件版本一致：

**功能：**
- 🔄 **版本同步** - 自动更新所有Dockerfile中的版本号
- 📥 **依赖下载** - 自动下载缺失的组件安装包
- ✅ **一致性检查** - 验证版本配置一致性
- 🌐 **网络检测** - 智能检测网络可用性

**使用方式：**
```bash
# 运行版本同步脚本
bash scripts/update-dockerfile-versions.sh
```

### 网络管理脚本 (`scripts/network.sh`)
Docker网络管理脚本，创建和管理集群共享网络：

**功能：**
- 🌐 **网络创建** - 创建大数据平台专用网络
- 🔍 **网络检查** - 检查网络是否存在
- 📊 **网络信息** - 显示网络配置信息
- 🔧 **幂等操作** - 支持重复执行

**使用方式：**
```bash
# 创建或检查网络
bash scripts/network.sh
```

## 🔧 包含的集群组件

### 基础服务
- **基础镜像**：基于 `ubuntu:focal-slim`，包含 JDK 8 和 SSH 服务
- **MySQL数据库**：Hive元数据存储
- **ZooKeeper集群**：3节点高可用协调服务

### 存储与计算
- **Hadoop集群**：标准配置（1NN+2DN）和高可用配置（2NN+2DN+3JN）
- **HBase数据库**：分布式NoSQL数据库
- **Hive数据仓库**：基于Hadoop的SQL查询引擎

### 计算引擎
- **Spark集群**：Standalone模式，支持批处理和机器学习
- **Flink集群**：流处理引擎，支持实时数据处理

### 数据管道
- **Kafka集群**：3节点消息队列
- **Flume采集**：数据采集工具，输出到Kafka

## 🚀 快速开始

### 1. 准备安装包
确定要使用的Hadoop环境（标准或高可用），各组件的版本号，在 `config/environment.conf` 中配置。
请将所需的安装包下载并放入 `module/` 目录下，具体文件列表请参考 [config/module-files.md](config/module-files.md)。

**注意：** 建议手动下载安装包，因为自动下载会非常耗时。

### 2. 环境准备
```bash
# 创建集群网络
bash scripts/network.sh

# 同步版本配置（可选，如果已手动下载安装包）
bash scripts/update-dockerfile-versions.sh
```

**重要提示：** 如果已经手动下载了所有安装包，运行 `update-dockerfile-versions.sh` 只会进行版本同步，不会重新下载。如果缺少某些安装包，脚本会自动下载，但这会非常耗时。

### 3. 构建基础镜像
```bash
docker build -t bigdata-base:latest -f dockerfile.base .
```

### 4. 构建组件镜像
```bash
# 构建所有组件镜像
for component in hadoop hive spark flink kafka flume hbase zookeeper mysql; do
    docker build -t bigdata-${component}:latest -f dockerfile.${component} .
done
```

### 5. 启动集群

## 🔗 组件依赖关系说明

**重要：** 请按照依赖关系顺序启动集群，避免组件间连接失败。

### 依赖关系图
```
基础服务层
├── MySQL (Hive元数据存储)
├── Flink (流处理)
└── Flume (数据采集)
├── ZooKeeper (协调服务)
│   └── Hadoop HA (高可用集群)
│   └── Kafka (消息队列)
│   └── HBase (NoSQL数据库)
└── Hadoop (标准集群)
    └── Hive (数据仓库)
    └── Spark (计算引擎)
    └── HBase (NoSQL数据库)
```

### 推荐启动顺序

#### 第一步：基础服务（必须）
```bash
# 1. MySQL - Hive元数据存储
docker-compose -f docker-compose.mysql.yml up -d

# 2. ZooKeeper - 协调服务（Kafka、HBase、Hadoop HA依赖）
docker-compose -f docker-compose.zookeeper.yml up -d

# 等待基础服务就绪
sleep 30
```

#### 第二步：存储与计算（核心组件）
```bash
# 3. Hadoop集群（选择一种环境）
# 标准环境：
docker-compose -f docker-compose.hadoop.yml up -d
# 或者高可用环境：
# docker-compose -f docker-compose.hadoop-ha.yml up -d

# 等待Hadoop就绪
sleep 60

# 4. Hive数据仓库（依赖Hadoop和MySQL）
docker-compose -f docker-compose.hive.yml up -d

# 5. HBase数据库（依赖Hadoop和ZooKeeper）
docker-compose -f docker-compose.hbase.yml up -d

# 6. Spark计算引擎（依赖Hadoop）
docker-compose -f docker-compose.spark.yml up -d
```

#### 第三步：消息与流处理（可选）
```bash
# 7. Kafka消息队列（依赖ZooKeeper）
docker-compose -f docker-compose.kafka.yml up -d

# 8. Flink流处理（独立服务）
docker-compose -f docker-compose.flink.yml up -d

# 9. Flume数据采集（依赖Kafka）
docker-compose -f docker-compose.flume.yml up -d
```

### 快速启动（全部组件）
```bash
# 按依赖顺序启动所有组件
bash -c '
  docker-compose -f docker-compose.mysql.yml up -d
  docker-compose -f docker-compose.zookeeper.yml up -d
  sleep 30
  docker-compose -f docker-compose.hadoop.yml up -d
  sleep 60
  docker-compose -f docker-compose.hive.yml up -d
  docker-compose -f docker-compose.hbase.yml up -d
  docker-compose -f docker-compose.spark.yml up -d
  docker-compose -f docker-compose.kafka.yml up -d
  docker-compose -f docker-compose.flink.yml up -d
  docker-compose -f docker-compose.flume.yml up -d
'
```

### 6. 运行功能测试
```bash
# 测试所有组件
for test_script in test/test-*.sh; do
    echo "运行测试: $(basename $test_script)"
    bash $test_script
done
```

## 🌐 组件Web UI与访问信息

### 📊 管理界面链接

**大数据平台所有组件的Web管理界面均可通过本地端口访问：**

#### 存储与计算层
- **Hadoop NameNode** - http://localhost:19870
- **Hadoop ResourceManager** - http://localhost:18088
- **Hadoop DataNode** (示例) - http://localhost:19864
- **Spark Master** - http://localhost:8080
- **Spark History Server** - http://localhost:18080
- **Spark Worker** (示例) - http://localhost:8081

#### 数据仓库与数据库
- **Hive Server2** - JDBC: jdbc:hive2://localhost:10000
- **HBase Master** - http://localhost:16210
- **HBase RegionServer1** - http://localhost:16030
- **HBase RegionServer2** - http://localhost:16031

#### 消息与流处理
- **Flink Dashboard** - http://localhost:18081
- **Kafka Manager** (如果部署) - http://localhost:9000

#### 协调服务
- **ZooKeeper** (无Web UI，使用CLI)

### 🔐 账号密码信息

#### MySQL数据库
- **主机**: localhost:3306
- **数据库**: hive
- **用户名**: hive
- **密码**: hive
- **Root用户**: root
- **Root密码**: root

#### Hive数据仓库
- **连接字符串**: jdbc:hive2://localhost:10000
- **默认数据库**: default
- **认证方式**: 无认证（开发环境）

#### Hadoop集群
- **HDFS Web UI**: 无需认证
- **YARN Web UI**: 无需认证
- **MapReduce History Server**: 无需认证

#### Spark集群
- **Spark Master UI**: 无需认证
- **Spark History Server**: 无需认证

#### Flink集群
- **Flink Dashboard**: 无需认证

#### Kafka集群
- **Broker地址**: localhost:9092
- **ZooKeeper连接**: localhost:2181

#### HBase数据库
- **HBase Master UI**: 无需认证
- **Thrift Server**: localhost:9090

### 🔧 常用访问命令

#### HDFS文件系统操作
```bash
# 查看HDFS文件系统
docker exec namenode hdfs dfs -ls /

# 上传文件到HDFS
docker exec namenode hdfs dfs -put /local/file /hdfs/path/

# 查看HDFS状态
docker exec namenode hdfs dfsadmin -report
```

#### YARN资源管理
```bash
# 查看YARN节点状态
docker exec namenode yarn node -list

# 查看运行的应用
docker exec namenode yarn application -list

# 杀死应用
docker exec namenode yarn application -kill <application_id>
```

#### Hive数据查询
```bash
# 连接Hive Server2
docker exec hive-server2 beeline -u jdbc:hive2://localhost:10000

# 执行Hive SQL
docker exec hive-server2 beeline -u jdbc:hive2://localhost:10000 -e "SHOW DATABASES;"
```

#### Spark作业提交
```bash
# 提交Spark作业到YARN
docker exec spark-master spark-submit --master yarn --class com.example.Main /path/to/job.jar

# 提交Spark作业到Standalone
docker exec spark-master spark-submit --master spark://spark-master:7077 --class com.example.Main /path/to/job.jar
```

#### Flink作业管理
```bash
# 查看Flink作业列表
docker exec flink-jobmanager /opt/flink/bin/flink list

# 提交Flink作业
docker exec flink-jobmanager /opt/flink/bin/flink run /path/to/job.jar

# 取消Flink作业
docker exec flink-jobmanager /opt/flink/bin/flink cancel <job_id>
```

#### Kafka主题管理
```bash
# 查看Kafka主题列表
docker exec kafka1 /opt/kafka/bin/kafka-topics.sh --list --bootstrap-server kafka1:9092

# 创建Kafka主题
docker exec kafka1 /opt/kafka/bin/kafka-topics.sh --create --topic test-topic --partitions 3 --replication-factor 3 --bootstrap-server kafka1:9092

# 生产消息
docker exec kafka1 /opt/kafka/bin/kafka-console-producer.sh --topic test-topic --bootstrap-server kafka1:9092

# 消费消息
docker exec kafka1 /opt/kafka/bin/kafka-console-consumer.sh --topic test-topic --from-beginning --bootstrap-server kafka1:9092
```

#### HBase数据操作
```bash
# 进入HBase Shell
docker exec hbase-master hbase shell

# 在HBase Shell中执行命令
list           # 列出所有表
create 'test', 'cf'  # 创建表
put 'test', 'row1', 'cf:col1', 'value1'  # 插入数据
scan 'test'    # 扫描表数据
```

### ⚠️ 安全注意事项

1. **开发环境配置** - 当前配置为开发环境，生产环境需要加强安全配置
2. **网络访问限制** - 建议在生产环境中限制外部访问
3. **密码管理** - 生产环境应使用强密码和密钥管理
4. **SSL/TLS加密** - 生产环境建议启用传输层加密

## 📋 测试说明

项目包含完整的测试体系，每个组件都有对应的测试脚本和说明文档：

- **测试脚本位置**：`test/test-*.sh`
- **测试说明文档**：`test/test-*.md`
- **测试覆盖范围**：组件状态、功能验证、集成测试

详细测试说明请参考各测试脚本对应的说明文档。

## 🔄 版本控制

项目使用Git进行版本控制，已排除以下目录：
- `module/` - 安装包文件
- `data/` - 运行时数据
- `logs/` - 日志文件

## 📞 技术支持

如有问题或建议，请参考各组件对应的测试说明文档，或检查组件日志文件。
