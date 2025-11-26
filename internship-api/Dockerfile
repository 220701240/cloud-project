FROM node:20-alpine AS base
WORKDIR /app

# Copy package files from the backend folder (build from repo root)
COPY internship-api/package*.json ./

# Install only production dependencies for smaller image
RUN npm install --production --silent

# Copy backend source
COPY internship-api/ ./

# Copy frontend static assets into the image so Express can serve them
COPY frontend/ ./frontend/

# Environment and port config
ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000

# Start the server
CMD ["node", "index.js"]
