#!/bin/bash

# Clear and cache various Laravel caches
for cmd in cache:clear route:clear view:clear config:clear view:cache config:cache; do
    cd /var/www/html && /usr/local/bin/php artisan $cmd
done

# Start the SQS worker service in the background and log its output
echo "[INFO] Starting medium worker service..."
cd /var/www/html && /usr/local/bin/php artisan queue:work --queue=$QUEUE_URL_DEFAULT

echo "fail"
