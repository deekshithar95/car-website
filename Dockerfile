# Use Nginx base image
FROM nginx:latest

# Copy HTML file into Nginx default directory
COPY . /usr/share/nginx/html

# Expose port 80
EXPOSE 80
