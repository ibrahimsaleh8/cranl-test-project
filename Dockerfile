# 1) Build stage
FROM node:20-alpine AS builder

# Set working dir
WORKDIR /app

# Copy package manifest files
COPY package*.json ./

# Install all dependencies (including devDependencies needed for build)
RUN npm install

# Copy rest of project
COPY . .

# Generate Prisma Client
RUN npx prisma generate

# Build the Next.js app
RUN npm run build

# 2) Production stage
FROM node:20-alpine AS runner

WORKDIR /app

# Set environment
ENV NODE_ENV=production
ENV PORT=3000

# Copy only necessary files
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/app/generated ./app/generated

# Expose port
EXPOSE 3000

# Start the server
CMD ["npm", "start"]
