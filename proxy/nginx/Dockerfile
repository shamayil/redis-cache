# Use AMD64-compatible NGINX base image
FROM nginx:1.19.7-alpine

# Install required packages
RUN apk add --no-cache jq curl coreutils sudo nano zsh

# Set working directory
WORKDIR /var/www/html

# Create necessary directories and set permissions
RUN mkdir -p /var/www/html/storage/logs && \
    chmod -R 755 /var/www/html/storage && \
    mkdir -p /var/log/nginx && \
    chmod -R 755 /var/log/nginx

# Set ownership of the NGINX configuration file
RUN chown nginx:nginx /etc/nginx/nginx.conf

# Copy NGINX configuration
COPY ./proxy/nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY ./proxy/nginx/nginx.conf /etc/nginx/nginx.conf

# Copy application files
COPY . .

# Expose port 80
EXPOSE 80

# Run NGINX in foreground
CMD ["nginx", "-g", "daemon off;"]
