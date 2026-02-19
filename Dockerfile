# Build Step 1 - Create the base
FROM node:22-alpine AS base
RUN apk add git --no-cache
COPY ./ /usr/src/app
WORKDIR /usr/src/app
RUN sh cdn-patch.sh
RUN npm pkg delete scripts.postinstall && npm install

# Build Step 2 - Build the application
FROM base AS builder
WORKDIR /usr/src/app
RUN npm run build
RUN rm -rf app/public/dist/client/pokechess

# Build Step 3 - Build a minimal production-ready image
FROM node:22-alpine
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install --only=production --ignore-scripts
COPY --from=builder /usr/src/app/app/public/dist ./app/public/dist
EXPOSE 9000
ENTRYPOINT ["node", "app/public/dist/server/app/index.js"]