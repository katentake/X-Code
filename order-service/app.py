import os
import psycopg2 # 确保你的代码或依赖里有连接器
from flask import Flask, jsonify, request

app = Flask(__name__)

# ⚡️ 从环境变量读取配置，并设置默认值（默认值精准对齐 K8s 内网的 Headless Service）
DB_HOST = os.getenv("DB_HOST", "postgres-service")
DB_NAME = os.getenv("DB_NAME", "ecommerce")
DB_USER = os.getenv("DB_USER", "terry")
DB_PASSWORD = os.getenv("DB_PASSWORD", "supersecretpwd")

def get_db_connection():
    conn = psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        port=5432
    )
    return conn

@app.route('/health', methods=["GET"])
def health_check():
    # 升级健康检查：不仅检查自己，顺便连一下 DB 看看通不通（这是大厂标准的 Deep Health Check）
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('SELECT 1;')
        cur.close()
        conn.close()
        return jsonify({"status": "healthy", "database": "connected"}), 200
    except Exception as e:
        return jsonify({"status": "unhealthy", "database_error": str(e)}), 500

@app.route('/', methods=["POST"])
def create_order():
    # 模拟下单，写入一条数据到数据库
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        # 临时建个极简表（实际生产由 migration 负责，这里为了练手直接建）
        cur.execute('''
            CREATE TABLE IF NOT EXISTS orders (
                id SERIAL PRIMARY KEY,
                product_name VARCHAR(50) NOT NULL,
                status VARCHAR(20) NOT NULL
            );
        ''')
        
        # 插入一条测试数据
        cur.execute("INSERT INTO orders (product_name, status) VALUES (%s, %s) RETURNING id;", ("Mountain Bike", "created"))
        order_id = cur.fetchone()[0]
        conn.commit()
        
        cur.close()
        conn.close()
        return jsonify({"status": "order_created", "order_id": order_id}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500
