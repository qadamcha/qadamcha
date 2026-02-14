FROM node:22-alpine AS base

WORKDIR /app

# Production dependencies faqat
COPY package.json package-lock.json ./
RUN npm ci --only=production && npm cache clean --force

# Source fayllar
COPY src/ ./src/

# Non-root user
RUN addgroup -g 1001 -S qadamcha && \
    adduser -S qadamcha -u 1001 -G qadamcha && \
    mkdir -p /app/logs && chown -R qadamcha:qadamcha /app

USER qadamcha

# Environment
ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["node", "src/app.js"]
