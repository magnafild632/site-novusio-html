# ⚡ CORRIGIR ERRO 404 DOS ARQUIVOS CSS/JS

## 🎯 Execute AGORA no Servidor

### Solução Rápida (Copie e Cole):

```bash
# Editar configuração do Nginx
sudo tee /etc/nginx/sites-available/novusiopy.com > /dev/null << 'EOF'
# Rate limiting
limit_req_zone $binary_remote_addr zone=api_3000:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=login_3000:10m rate=1r/s;

# Upstream para a aplicação
upstream novusio_backend_3000 {
    server 127.0.0.1:3000;
    keepalive 32;
}

server {
    listen 80;
    listen [::]:80;
    server_name novusiopy.com www.novusiopy.com;

    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    location / {
        return 301 https://$server_name$request_uri;
    }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name novusiopy.com www.novusiopy.com;

    ssl_certificate /etc/letsencrypt/live/novusiopy.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/novusiopy.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;

    # IMPORTANTE: Root do React
    root /opt/novusio/client/dist;
    index index.html;

    # Gzip
    gzip on;
    gzip_vary on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml+rss;

    # Arquivos estáticos do React
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Cache de assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # API
    location /api/ {
        limit_req zone=api_3000 burst=20 nodelay;
        proxy_pass http://novusio_backend_3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Admin login
    location /api/auth/login {
        limit_req zone=login_3000 burst=5 nodelay;
        proxy_pass http://novusio_backend_3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # Uploads
    location /uploads/ {
        alias /opt/novusio/uploads/;
        expires 1y;
        add_header Cache-Control "public";
    }
}
EOF

# Testar e recarregar
sudo nginx -t && sudo systemctl reload nginx

echo "✅ Nginx corrigido! Atualize a página no navegador."
```

---

## 🎉 Pronto!

Após executar, atualize a página e tudo funcionará! ✨
