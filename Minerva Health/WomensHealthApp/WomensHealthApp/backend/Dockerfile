# Minerva Health backend – Railway
FROM node:20-slim

WORKDIR /app

# Prisma needs OpenSSL (avoid "failed to detect libssl" warning)
RUN apt-get update -y && apt-get install -y openssl && rm -rf /var/lib/apt/lists/*

# Copy package and Prisma schema first so postinstall (prisma generate) can run
COPY package.json ./
COPY prisma ./prisma/
RUN npm install

COPY . .
RUN npx prisma generate && npm run build

# Push schema to DB and start (Railway sets PORT)
CMD ["sh", "-c", "npx prisma db push && node dist/index.js"]
