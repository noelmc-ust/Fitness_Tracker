#!/bin/bash

apt update -y
apt upgrade -y
apt install nginx git npm -y

cd /var/www/html
git clone https://github.com/Msocial123/Fitness_Tracker
chmod -R 400 /var/www/html/Fitness_Tracker

rm -rf /var/www/html/index-debian.html
sudo cat <<EOF > /etc/nginx/sites-available/default
server {
    listen 80;
    server_name _;

    location /static/ {
        alias /var/www/html/Fitness_Tracker/public/;
        expires 30d;
    }

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

systemctl restart nginx
cd /var/www/html/Fitness_Tracker
npm install 
npm install -g pm2
pm2 start server/apps.js --name "fitness_app"
pm2 save
pm2 startup




