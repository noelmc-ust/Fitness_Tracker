FROM node:18-alpine
WORKDIR /app
COPY server/package*.json ./
RUN npm install --omit=dev
COPY server/ .
COPY public/ ./public/
EXPOSE 5000
CMD ["node", "app.js"]