# Build stage - using Bun for fast builds
FROM oven/bun:latest AS builder

WORKDIR /build

# Install git first (this layer rarely changes)
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# Accept build argument for API base URL (this can change frequently)
ARG VITE_API_BASE_URL=http://localhost:4096

# Copy local source code (this changes often)
COPY . .

# Install dependencies (changes when package.json changes)
RUN bun install

# Build (changes when source or ARG changes)
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL
RUN bun run build

# Runtime stage - lightweight Node.js image
FROM node:20-alpine

WORKDIR /app

# Install serve to efficiently serve static files
RUN npm install -g serve

# Copy built application from builder stage
COPY --from=builder /build/dist ./dist

# Expose port 5173 (matches the dev server port used in docker-compose)
EXPOSE 5173

# Serve the built application
CMD ["serve", "-l", "5173", "-s", "dist"]
