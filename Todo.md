# 大数据 5 节点全栈集群架构蓝图 (Standalone 极限版)

> **设计目标**: 在 16GB 物理内存环境下，通过物理角色合并与极致内存压榨，实现 Hadoop, Hive, HBase, Zookeeper, Kafka, Flume, Spark (Standalone) 和 Flink (Standalone) 的全栈部署。

***

## 一、 节点角色与服务分配矩阵

此架构将 9 大组件根据功能逻辑合并为 5 个物理节点，模拟真实的 Master-Slave 拓扑。

| 节点名称 (Hostname) | 物理角色           | 运行服务 (JVM Processes)                                                                                                                                | 建议堆内存 (JVM Heap)                      |
| :-------------- | :------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------ |
| **master**      | **管理主节点**      | 1. NameNode (HDFS)2. ResourceManager (YARN)3. HMaster (HBase)4. Hive Metastore5. Hive Server26. Spark Master7. Flink JobManager                     | **4.0 GB**(512M*4 + 1G + 512M*2)      |
| **worker-1**    | **计算/存储从节点 1** | 1. DataNode (HDFS)2. NodeManager (YARN)3. RegionServer (HBase)4. Zookeeper (Quorum 1)5. Kafka Broker (1)6. Spark Worker (1)7. Flink TaskManager (1) | **3.5 GB**(256M+512M+1G+128M+512M\*3) |
| **worker-2**    | **计算/存储从节点 2** | 同上                                                                                                                                                  | **3.5 GB**                            |
| **worker-3**    | **计算/存储从节点 3** | 同上                                                                                                                                                  | **3.5 GB**                            |
| **infra**       | **网关/辅助节点**    | 1. MySQL (MetaDB)2. Flume Agent3. CLI Clients (Shells/Submitters)                                                                                   | **1.0 GB**(MySQL+256M+Buffer)         |

**总计预估堆内存占用**: \~15.5 GB (已接近 16GB 物理上限，需开启 Swap)

***

## 二、 极限内存调优参数 (保命配置)

为了防止进程因 OOM 被内核杀掉，必须在各组件配置文件中强制锁定以下最大内存：

### 1. 存储层 (Hadoop/ZK)

- **NameNode**: `HADOOP_HEAPSIZE=512`
- **DataNode**: `HADOOP_HEAPSIZE=256`
- **Zookeeper**: `SERVER_JVMFLAGS="-Xmx128m"`

### 2. 计算/调度层 (YARN/Spark/Flink)

- **ResourceManager**: `YARN_RESOURCEMANAGER_HEAPSIZE=512`
- **NodeManager**: `YARN_NODEMANAGER_HEAPSIZE=512`
- **Spark Master**: `SPARK_MASTER_MEMORY=512m`
- **Spark Worker**: `SPARK_WORKER_MEMORY=512m` (单个容器内所有 Executor 共享)
- **Flink JobManager**: `jobmanager.memory.process.size: 512m`
- **Flink TaskManager**: `taskmanager.memory.process.size: 512m`

### 3. 数据层 (Hive/HBase/Kafka)

- **HiveServer2**: `HADOOP_HEAPSIZE=1024`
- **HMaster**: `HBASE_MASTER_OPTS="-Xmx512m"`
- **RegionServer**: `HBASE_REGIONSERVER_OPTS="-Xmx1024m"`
- **Kafka Broker**: `KAFKA_HEAP_OPTS="-Xmx512m -Xms512m"`

***

## 三、 教学实战与运维建议

### 1. 启动顺序 (启动链)

由于组件依赖较多，建议引导学生编写分级启动脚本：

1. **基础层**: Zookeeper -> HDFS
2. **调度层**: YARN -> Spark Master -> Flink JobManager
3. **数据层**: Kafka -> HBase -> Hive Metastore -> HiveServer2
4. **接入层**: Flume

### 2. Standalone 模式教学重点

- **资源隔离**: 演示 Spark Worker 和 Flink TaskManager 启动后，在没有任务执行时依然占用的静态内存空间。
- **UI 监控**:
  - Master:8080 (Spark Master)
  - Master:8081 (Flink Dashboard)
  - Master:9870 (HDFS)
- **提交模式**: 强调 `--deploy-mode cluster`（Spark）如何将计算压力分散到 worker，而不是压垮 infra 节点。

### 3. 内存动态管理

如果学生机器内存确实告急，建议采取“场景化启动”：

- **场景 A (离线流)**: HDFS + YARN + Hive + HBase。
- **场景 B (实时流)**: HDFS + Kafka + Flink Standalone。
- **场景 C (批处理)**: HDFS + Spark Standalone。

# 大数据 5 节点全栈集群改造计划 (Todo List)

> **目标**: 将现有的“单组件单容器”架构，重构为“按物理角色合并”的 5 节点高密度教学架构。
> **资源限制**: 宿主机物理内存严格控制在 16GB 以内。

## 阶段一：基础镜像准备 (Base Image)

- [ ] **重写 Dockerfile**: 构建一个包含所有大数据组件安装包的统一“巨石镜像”。
  - [ ] 解压并配置 Hadoop, Zookeeper, Hive, HBase, Kafka, Flume, Spark, Flink。
  - [ ] 配置全局环境变量 (JAVA\_HOME, HADOOP\_HOME等) 到 `/etc/profile`。
- [ ] **引入进程管理工具**: 在镜像中安装并配置 `Supervisor`，以便单个容器守护多个 Java 进程。

## 阶段二：节点分配与 docker-compose.yml 编写

- [ ] **配置** **`master`** **节点**: 设定主机名并映射各组件 WebUI 端口。
- [ ] **配置** **`worker-1/2/3`** **节点**: 挂载 HDFS、ZK 和 Kafka 的持久化数据卷。
- [ ] **配置** **`infra`** **节点**: 准备 MySQL 服务及 Flume Agent。

## 阶段三：极限内存调优 (核心保命配置)

- [ ] **Hadoop**: NN(512m), RM(512m), DN(256m), NM(512m)。
- [ ] **HBase**: HM(512m), RS(1g)。
- [ ] **Zookeeper**: 设置 `SERVER_JVMFLAGS="-Xmx128m"`。
- [ ] **Kafka**: 修改 `KAFKA_HEAP_OPTS` 为 `512m`。
- [ ] **Hive**: HMS(512m), HS2(1g)。
- [ ] **Spark**: Master(512m), Worker(512m)。
- [ ] **Flink**: JM(512m), TM(512m)。

## 阶段四：编写场景化启动脚本

- [ ] **离线数仓模式 (`start-dw.sh`)**: 启动 Hadoop + ZK + Hive + HBase。
- [ ] **实时流计算模式 (`start-streaming.sh`)**: 启动 Hadoop + ZK + Kafka + Flume + Flink Standalone。
- [ ] **内存计算模式 (`start-spark.sh`)**: 启动 Hadoop + Spark Standalone。

## 阶段五：系统级配置与验证

- [ ] **配置 WSL**: 确保 `.wslconfig` 分配了至少 12GB+ 内存。
- [ ] **验证连通性**: 执行 `hdfs dfs -ls` 及简单的 Spark/Flink 任务提交。

***

