FROM node:22-alpine
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY index.js ./
USER node
CMD ["node", "-e", "console.log(require('./index').add(2, 3))"]
