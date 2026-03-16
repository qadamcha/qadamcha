FROM node:22-alpine

WORKDIR /app

# Dependencies
COPY package.json package-lock.json ./
RUN npm ci --only=production && npm cache clean --force

# Source
COPY server.js ./
COPY public/ ./public/

# Non-root user
RUN addgroup -g 1001 -S qadamcha && \
    adduser -S qadamcha -u 1001 -G qadamcha && \
    chown -R qadamcha:qadamcha /app

USER qadamcha

ENV NODE_ENV=production
ENV PORT=4000

EXPOSE 4000

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:4000/ || exit 1

CMD ["node", "server.js"]
