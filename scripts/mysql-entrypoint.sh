#!/bin/bash
set -e

# 初始化 MySQL 数据目录
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MySQL data directory..."
    
    # 使用 mysqld --initialize 初始化数据库
    mysqld --initialize-insecure --user=mysql --datadir=/var/lib/mysql
    
    # 启动临时 MySQL 服务器
    mysqld --user=mysql --datadir=/var/lib/mysql --skip-networking &
    sleep 5
    
    # 设置 root 密码和创建必要的数据库
    mysql -u root --socket=/var/run/mysqld/mysqld.sock << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY 'root';
CREATE USER 'root'@'%' IDENTIFIED BY 'root';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;

-- 创建 hive 元数据库
CREATE DATABASE IF NOT EXISTS hive;
CREATE USER 'hive'@'%' IDENTIFIED BY 'hive';
GRANT ALL PRIVILEGES ON hive.* TO 'hive'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
    
    # 停止临时 MySQL 服务器
    mysqladmin -u root -proot --socket=/var/run/mysqld/mysqld.sock shutdown
fi

# 启动 MySQL 服务器
echo "Starting MySQL server..."
exec "$@"
