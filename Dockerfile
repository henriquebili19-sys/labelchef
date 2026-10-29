# Imagem única para hospedagem em serviço único (ex: Railway): o backend serve a API, o WebSocket do
# Agente de Impressão e também o site (build do Vite). Build a partir da RAIZ do projeto:
#   docker build -t labelchef .

# --- 1) build do frontend
FROM node:22-slim AS frontend-build
WORKDIR /app
COPY frontend/package*.json ./
RUN npm install
COPY frontend/ .
RUN npm run build

# --- 2) build do backend
FROM node:22-slim AS backend-build
# O Prisma precisa do OpenSSL, que a imagem "slim" não traz.
RUN apt-get update -y && apt-get install -y --no-install-recommends openssl ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY backend/package*.json ./
COPY backend/prisma ./prisma
RUN npm install
COPY backend/ .
RUN npx prisma generate && npm run build

# --- 3) imagem final
FROM node:22-slim AS runtime
RUN apt-get update -y && apt-get install -y --no-install-recommends openssl ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /app
ENV NODE_ENV=production \
    FRONTEND_DIST=/app/public \
    UPLOADS_DIR=/data/uploads
COPY backend/package*.json ./
COPY backend/prisma ./prisma
RUN npm install --omit=dev && npx prisma generate
COPY --from=backend-build /app/dist ./dist
COPY --from=frontend-build /app/dist ./public

EXPOSE 3333
# Aplica as migrações do banco e sobe o servidor. A porta vem da variável PORT (a Railway define).
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/server.js"]