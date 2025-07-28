# Build stage
FROM golang:1.24-alpine as builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /stats ./cmd/stats.go

# Final stage
FROM alpine:latest
WORKDIR /
COPY --from=builder /stats /stats
EXPOSE 8080
USER nobody:nogroup
ENTRYPOINT ["/stats"]
