# Use lightweight Nginx base image
FROM nginx:alpine

# Remove default Nginx html files
RUN rm -rf /usr/share/nginx/html/*

# Copy your GOVT-PREP-WEB-APP files into Nginx html directory
COPY . /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Run Nginx in foreground
CMD ["nginx", "-g", "daemon off;"]
