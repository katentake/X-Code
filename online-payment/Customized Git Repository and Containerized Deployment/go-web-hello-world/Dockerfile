# base image
FROM golang:1.22-alpine

# working directory
WORKDIR /app

# copy files and download
COPY go.mod ./
RUN go mod download

# copy source code and build
COPY main.go ./
RUN go build -o /go-app

# port
EXPOSE 8088

# start application
CMD ["/go-app"]