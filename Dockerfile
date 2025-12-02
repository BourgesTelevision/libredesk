# Stage 1: Build Frontend
FROM node:20-alpine AS frontend-builder
WORKDIR /app/frontend
RUN corepack enable && corepack prepare pnpm@latest --activate
COPY frontend/package.json frontend/pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
COPY frontend/ .
RUN pnpm build

# Stage 2: Build Backend
FROM golang:alpine AS backend-builder
WORKDIR /app
RUN apk add --no-cache git make
RUN go install github.com/knadh/stuffbin/stuffbin@latest
COPY go.mod go.sum ./
RUN go mod download
COPY . .
COPY --from=frontend-builder /app/frontend/dist ./frontend/dist
RUN make build-backend
RUN make stuff

# Stage 3: Final Image
FROM alpine:latest
WORKDIR /libredesk
RUN apk --no-cache add ca-certificates tzdata
COPY --from=backend-builder /app/libredesk .
EXPOSE 9000
CMD ["sh", "-c", "./libredesk --install --idempotent-install --yes && ./libredesk --upgrade --yes && ./libredesk"]
