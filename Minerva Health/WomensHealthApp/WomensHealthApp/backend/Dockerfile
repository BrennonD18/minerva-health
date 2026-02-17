# Minerva Health backend – Railway
FROM node:20-slim

WORKDIR /app

COPY package.json ./
RUN npm install

COPY . .
RUN npx prisma generate && npm run build

# Push schema to DB and start (Railway sets PORT)
CMD ["sh", "-c", "npx prisma db push && node dist/index.js"]
