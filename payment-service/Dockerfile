# --- 阶段一：编译阶段 ---
FROM golang:1.21-alpine AS builder

WORKDIR /build

COPY main.go .

# CGO_ENABLED=0 确保交叉编译出不依赖系统动态链接库的纯二进制文件
RUN CGO_ENABLED=0 GOOS=linux go build -o payment-app main.go

# --- 阶段二：运行阶段 ---
# 使用极其微小的 alpine 镜像（甚至可以用 scratch，但 alpine 方便你在 Pod 里 exec 进去 debug）
FROM alpine:3.18

WORKDIR /app

# 从编译器阶段把二进制文件捞过来
COPY --from=builder /build/payment-app .

EXPOSE 8080

CMD ["./payment-app"]
