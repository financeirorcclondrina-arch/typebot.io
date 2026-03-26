# ================= INSTALL BUN ===================
ARG BUN_VERSION=1.3.9

FROM oven/bun:${BUN_VERSION}-slim AS bun

# ================= BASE ==========================
FROM node:24-bullseye-slim AS base

COPY --from=bun /usr/local/bin/bun /usr/local/bin/bun
COPY --from=bun /usr/local/bin/bunx /usr/local/bin/bunx

RUN apt-get update -qq \
    && apt-get install -qq --no-install-recommends \
    build-essential \
    ca-certificates \
    git \
    g++ \
    openssl \
    python3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# =============== INSTALL & BUILD =================
FROM base AS builder
ARG SCOPE=viewer

COPY --from=bun /usr/local/bin/bun /usr/local/bin/bun
COPY --from=bun /usr/local/bin/bunx /usr/local/bin/bunx

COPY . .

RUN SENTRYCLI_SKIP_DOWNLOAD=1 bun install --frozen-lockfile
RUN DATABASE_URL=postgresql://user:pass@localhost:5432/db SKIP_ENV_CHECK=true NEXT_PUBLIC_VIEWER_URL=http://localhost bunx nx build ${SCOPE}
RUN DATABASE_URL=postgresql:// bunx nx db:generate prisma

# ================== RELEASE ======================
FROM base AS release
ARG SCOPE=viewer
ENV SCOPE=${SCOPE}

COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/packages/prisma/postgresql ./packages/prisma/postgresql
COPY --from=builder --chown=node:node /app/apps/${SCOPE}/.next/standalone ./
COPY --from=builder --chown=node:node /app/apps/${SCOPE}/.next/static ./apps/${SCOPE}/.next/static
COPY --from=builder --chown=node:node /app/apps/${SCOPE}/public ./apps/${SCOPE}/public

COPY scripts/builder-entrypoint.sh ./entrypoint.sh
RUN chmod +x ./entrypoint.sh && chown node:node ./entrypoint.sh

USER node

ENTRYPOINT ["./entrypoint.sh"]

EXPOSE 3000
ENV PORT=3000
