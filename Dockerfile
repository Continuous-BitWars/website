FROM python:3.12 AS builder
Run pip install pipenv

#RUN apt-get update && apt-get install -y pipenv

# Set the working directory
WORKDIR /app

# Copy Pipfile and Pipfile.lock
COPY . .

# Install pipenv
RUN pipenv install --system --deploy && pipenv run mkdocs build

# Install dependencies
#RUN pipenv run mkdocs build

# Stage 2: Serve the site using Nginx
FROM nginx:alpine

# Copy built site from the builder stage
COPY --from=builder /app/site /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]

