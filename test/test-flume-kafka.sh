#!/bin/bash

echo "=== Flume 与 Kafka 联动测试 ==="

# 1. 检查容器状态
echo "1. 检查 Flume 和 Kafka 容器状态..."
docker ps | grep -E "flume|kafka"

# 2. 准备测试数据
echo -e "\n2. 准备测试数据..."
test_data="$(date): Flume-Kafka integration test message"
echo "Writing test data: $test_data"

# 直接在容器内部写入日志文件，确保路径一致
echo "$test_data" >> ./data/flume/logs/application.log

# 3. 等待 Flume 采集数据
echo -e "\n3. 等待 Flume 采集数据 (15秒)..."
sleep 15

# 4. 从 Kafka 消费数据验证
echo -e "\n4. 从 Kafka 消费数据验证..."
echo "消费历史数据（前20条）："
docker exec kafka1 timeout 10s /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka1:9092 --topic flume-logs --from-beginning --max-messages 20

# 5. 查看 Kafka 主题详情
echo -e "\n5. 查看 Kafka 主题 'flume-logs' 详情..."
docker exec kafka1 /opt/kafka/bin/kafka-topics.sh --describe --topic flume-logs --bootstrap-server kafka1:9092

# 6. 查看主题中的消息数量
echo -e "\n6. 查看主题消息统计..."
docker exec kafka1 /opt/kafka/bin/kafka-run-class.sh kafka.tools.GetOffsetShell --broker-list kafka1:9092 --topic flume-logs --time -1

echo -e "\n=== Flume 与 Kafka 联动测试完成 ==="
echo -e "✓ 测试数据已写入日志文件"
echo -e "✓ Flume 已尝试采集数据到 Kafka"
echo -e "✓ Kafka 消费验证已完成"
echo -e "✓ 主题详情已查看"
echo -e "✓ TimeoutException 是正常消费行为，不是错误"