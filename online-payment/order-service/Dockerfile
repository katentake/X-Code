# 使用官方轻量级 Python 镜像
FROM python:3.11-slim

WORKDIR /app

# ⚡️ 同时安装 flask 和预编译的 postgres 驱动二进制包
RUN pip install --no-cache-dir flask psycopg2-binary

COPY app.py .

EXPOSE 5000

# ⚡️ 通过环境变量指定 Flask 应用文件，并强制它在容器前台长驻
ENV FLASK_APP=app.py
CMD ["flask", "run", "--host=0.0.0.0", "--port=5000"]
