# Build Step 1 - Create the base
FROM node:22-alpine AS base
RUN apk add git --no-cache
COPY ./ /usr/src/app
WORKDIR /usr/src/app
RUN sh patches/cdn-patch.sh
RUN sh patches/booster-patch.sh
RUN sh patches/collection-patch.sh
RUN rm -rf app/public/src/assets/portraits/* app/public/src/assets/tilesets/* app/public/src/assets/posters/*
RUN npm pkg delete scripts.postinstall && npm install && cd edit/assetpack && npm install
RUN npm run assetpack

# Build Step 2 - Build the application
FROM base AS builder
ARG FIREBASE_API_KEY
ARG FIREBASE_AUTH_DOMAIN
ARG FIREBASE_PROJECT_ID
ARG FIREBASE_STORAGE_BUCKET
ARG FIREBASE_MESSAGING_SENDER_ID
ARG FIREBASE_APP_ID
WORKDIR /usr/src/app
RUN npm run build
RUN rm -rf app/public/dist/client/pokechess

# Build Step 3 - Build a minimal production-ready image
FROM node:22-alpine
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm install --omit=dev --ignore-scripts
COPY --from=builder /usr/src/app/app/public/dist ./app/public/dist
EXPOSE 9000
ENTRYPOINT ["node", "app/public/dist/server/app/index.js"]
