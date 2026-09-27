# Dockerfile - API de Reservas (multi-stage, usuario nao-root)

# ---------- Stage 1: dependencias ----------
FROM node:18-alpine AS deps
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev

# ---------- Stage 2: imagem final ----------
FROM node:18-alpine AS runtime
WORKDIR /app

# Cria usuario nao-root por seguranca
RUN addgroup -S app && adduser -S app -G app

# Copia dependencias do stage anterior e o codigo
COPY --from=deps /app/node_modules ./node_modules
COPY src ./src
COPY package.json ./

# Usa o usuario nao-root
USER app

EXPOSE 3000

CMD ["node", "src/server.js"]