# ⚡ Completar Deploy - Passos Finais

## 🎉 Ótimas Notícias!

Sua aplicação está quase pronta! Faltam apenas os passos finais.

---

## 📋 Execute no Servidor AGORA

### **1️⃣ Configurar PM2 Startup (IMPORTANTE)**

```bash
# Copie e execute o comando que o PM2 mostrou:
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u novusio --hp /home/novusio
```

### **2️⃣ Configurar Nginx**

```bash
# Remover configuração padrão se existir
sudo rm -f /etc/nginx/sites-enabled/default

# Criar configuração do site (substitua SEU-DOMINIO.com)
sudo tee /etc/nginx/sites-available/SEU-DOMINIO.com > /dev/null << 'EOF'
# Rate limiting
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;

# Upstream para a aplicação
upstream novusio_backend {
    server 127.0.0.1:3000;
    keepalive 32;
}

# Redirecionamento HTTP para HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name SEU-DOMINIO.com www.SEU-DOMINIO.com;

    # Certbot challenge
    location /.well-known/acme-challenge/ {
        root /var/www/html;
    }

    # Redirecionar para HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# Configuração HTTPS (será atualizada pelo Certbot)
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name SEU-DOMINIO.com www.SEU-DOMINIO.com;

    # Arquivos estáticos (React build)
    root /opt/novusio/client/dist;
    index index.html;

    # Gzip
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml+rss;

    # Static files
    location / {
        try_files $uri $uri/ @backend;

        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # Backend API
    location @backend {
        proxy_pass http://novusio_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # API routes
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        proxy_pass http://novusio_backend;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Admin login
    location /api/auth/login {
        limit_req zone=login burst=5 nodelay;
        proxy_pass http://novusio_backend;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Uploads
    location /uploads/ {
        alias /opt/novusio/uploads/;
        expires 1y;
        add_header Cache-Control "public";
    }
}
EOF

# Habilitar site
sudo ln -sf /etc/nginx/sites-available/SEU-DOMINIO.com /etc/nginx/sites-enabled/

# Testar configuração
sudo nginx -t

# Recarregar Nginx
sudo systemctl reload nginx
```

### **3️⃣ Configurar SSL com Certbot**

```bash
# Instalar Certbot
sudo apt-get install -y certbot python3-certbot-nginx

# Obter certificado SSL (substitua os valores)
sudo certbot --nginx \
  -d SEU-DOMINIO.com \
  -d www.SEU-DOMINIO.com \
  --non-interactive \
  --agree-tos \
  --email seu-email@gmail.com \
  --redirect

# Configurar renovação automática
(sudo crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | sudo crontab -
```

### **4️⃣ Inicializar Banco de Dados**

```bash
cd /opt/novusio
sudo -u novusio npm run init-db
```

### **5️⃣ Verificar Status**

```bash
# Status PM2
sudo -u novusio pm2 status

# Status Nginx
sudo systemctl status nginx

# Testar aplicação
curl http://localhost:3000

# Testar site (após SSL)
curl -I https://SEU-DOMINIO.com
```

---

## 🎯 Comandos Resumidos (Copie e Cole)

**ATENÇÃO:** Substitua `SEU-DOMINIO.com` e `seu-email@gmail.com` pelos seus valores reais!

```bash
# 1. PM2 Startup
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u novusio --hp /home/novusio

# 2. Criar diretório web
sudo mkdir -p /var/www/html

# 3. Instalar Certbot
sudo apt-get install -y certbot python3-certbot-nginx

# 4. Obter SSL (SUBSTITUA OS VALORES!)
sudo certbot --nginx \
  -d SEU-DOMINIO.com \
  -d www.SEU-DOMINIO.com \
  --non-interactive \
  --agree-tos \
  --email seu-email@gmail.com \
  --redirect

# 5. Inicializar banco
cd /opt/novusio
sudo -u novusio npm run init-db

# 6. Verificar
sudo -u novusio pm2 status
curl -I https://SEU-DOMINIO.com
```

---

## ✅ Verificação Final

### Sua aplicação está funcionando se:

```bash
# 1. PM2 mostra "online"
sudo -u novusio pm2 status
# Deve mostrar: │ 0 │ novusio-server │ online │

# 2. Nginx está ativo
sudo systemctl status nginx
# Deve mostrar: active (running)

# 3. Site responde
curl -I https://SEU-DOMINIO.com
# Deve mostrar: HTTP/2 200

# 4. Porta 3000 responde
curl http://localhost:3000
# Deve retornar HTML ou JSON
```

---

## 🎊 Após Concluir

Acesse seu site:

- 🌐 **Site público:** https://SEU-DOMINIO.com
- 👤 **Admin:** https://SEU-DOMINIO.com/admin

**Credenciais padrão:**

- Usuário: `admin`
- Senha: `admin123`

**⚠️ ALTERE A SENHA IMEDIATAMENTE!**

---

## 🔐 Secrets Gerados

Seus secrets foram salvos em:

```bash
/opt/novusio/.secrets-backup-20251013_004245.txt
```

**IMPORTANTE:**

1. Copie este arquivo para local seguro (seu computador)
2. Delete do servidor após copiar

```bash
# Copiar para seu computador
scp root@seu-servidor:/opt/novusio/.secrets-backup-*.txt ~/Downloads/

# Depois, deletar do servidor
sudo rm /opt/novusio/.secrets-backup-*.txt
```

---

## 📋 Configurar Backup e Monitoramento

```bash
# Copiar scripts
sudo cp /opt/novusio/instalador/backup.sh /usr/local/bin/novusio-backup.sh
sudo cp /opt/novusio/instalador/monitor.sh /usr/local/bin/novusio-monitor.sh
sudo chmod +x /usr/local/bin/novusio-*.sh

# Configurar cron para backup diário (2h da manhã)
(sudo crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/novusio-backup.sh") | sudo crontab -

# Configurar cron para monitoramento (a cada 5 minutos)
(sudo crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/novusio-monitor.sh") | sudo crontab -

# Verificar crontab
sudo crontab -l
```

---

## 🎯 Próximos Passos

1. ✅ Acessar https://SEU-DOMINIO.com
2. ✅ Fazer login no admin
3. ✅ Alterar senha padrão
4. ✅ Configurar informações da empresa
5. ✅ Adicionar conteúdo (slides, serviços, portfólio)
6. ✅ Testar todas as funcionalidades
7. ✅ Salvar backup dos secrets
8. ✅ Deletar secrets do servidor

---

## 🆘 Se Algo Não Funcionar

```bash
# Ver logs da aplicação
sudo -u novusio pm2 logs

# Ver logs do Nginx
sudo tail -f /var/log/nginx/error.log

# Reiniciar aplicação
sudo -u novusio pm2 restart novusio-server

# Reiniciar Nginx
sudo systemctl restart nginx

# Verificar firewall
sudo ufw status
```

---

## 🎉 Pronto!

Seu sistema Novusio está instalado e funcionando com:

- ✅ Node.js 18
- ✅ React + Vite
- ✅ PM2 (cluster mode)
- ✅ Nginx
- ✅ SSL/HTTPS
- ✅ JWT Secrets gerados automaticamente
- ✅ Firewall configurado
- ✅ Backup automático configurado
- ✅ Monitoramento ativo

**Parabéns! 🚀**
