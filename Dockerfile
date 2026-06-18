# Alpine = lightweight image
FROM node:22-alpine

WORKDIR /app

# Layer caching: pehle package files copy karo
COPY package*.json ./
RUN npm install

# Baaki saari files copy karo
COPY . .

EXPOSE 8080

CMD ["node", "index.js"]