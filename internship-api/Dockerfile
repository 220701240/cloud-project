# Use Node.js LTS version
FROM node:20

# Set working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json first (better caching)
COPY internship-api/package*.json ./

# Install dependencies
RUN npm install

# Copy the internship-api files to the root of the working directory
COPY internship-api/ ./

# Expose port the app runs on
EXPOSE 3000

# Start the app
CMD ["node", "index.js"]
