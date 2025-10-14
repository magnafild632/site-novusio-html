# 🚀 Instruções de Deploy - Site Novusio

## 📋 Resumo do que foi criado

A pasta `instalador/` contém todos os arquivos necessários para fazer deploy completo da aplicação em uma VPS:

### 🔧 Scripts Principais

1. **`install.sh`** - Instalação automática completa
2. **`setup-ssl.sh`** - Configuração SSL com Certbot
3. **`deploy.sh`** - Deploy da aplicação
4. **`backup.sh`** - Backup automático
5. **`novusio-manager.sh`** - Gerenciador da aplicação
6. **`regenerate-secrets.sh`** - Gerador de chaves seguras

### ⚙️ Configurações

1. **`nginx.conf`** - Configuração Nginx com proxy reverso
2. **`ecosystem.config.js`** - Configuração PM2
3. **`novusio.service`** - Serviço systemd
4. **`fail2ban.conf`** - Configuração Fail2ban
5. **`fail2ban-filters.conf`** - Filtros de segurança
6. **`env.production.template`** - Template de variáveis de ambiente

## 🚀 Como fazer o deploy

### 1. Preparar o servidor

```bash
# Conectar via SSH
ssh usuario@seu-servidor.com

# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar dependências básicas
sudo apt install -y curl wget git unzip
```

### 2. Fazer upload dos arquivos

```bash
# Clonar repositório ou fazer upload
git clone https://github.com/seu-usuario/site-novusio-html.git
cd site-novusio-html

# OU fazer upload via SCP/SFTP
scp -r . usuario@servidor:/home/usuario/site-novusio-html
```

### 3. Executar instalação

```bash
# Tornar scripts executáveis
chmod +x instalador/*.sh

# Executar instalação automática
sudo ./instalador/install.sh
```

### 4. Configurar variáveis de ambiente

```bash
# Editar arquivo de configuração
sudo nano /opt/novusio/.env

# Configurar com suas informações:
DOMAIN=seu-dominio.com
EMAIL=seu-email@exemplo.com
JWT_SECRET=sua-chave-secreta-muito-forte
```

### 5. Configurar SSL

```bash
# Executar configuração SSL
sudo ./instalador/setup-ssl.sh
```

### 6. Iniciar aplicação

```bash
# Iniciar aplicação
sudo systemctl start novusio

# Verificar status
sudo systemctl status novusio
```

## 🔧 Comandos úteis

### Gerenciar aplicação

```bash
# Usar o gerenciador
novusio-manager status
novusio-manager logs
novusio-manager restart

# Ou usar systemctl diretamente
sudo systemctl start novusio
sudo systemctl stop novusio
sudo systemctl restart novusio
sudo systemctl status novusio
```

### Ver logs

```bash
# Logs da aplicação
sudo journalctl -u novusio -f

# Logs do Nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Logs do Fail2ban
sudo tail -f /var/log/fail2ban.log
```

### Backup e restore

```bash
# Backup manual
sudo -u novusio /opt/novusio/backup.sh

# Listar backups
ls -lh /opt/novusio/backups/

# Deploy
sudo -u novusio /opt/novusio/app/instalador/deploy.sh
```

## 🛡️ Segurança configurada

- ✅ **Firewall UFW** - Portas 22, 80, 443 abertas
- ✅ **Fail2ban** - Proteção contra ataques
- ✅ **SSL/TLS** - Certificados automáticos
- ✅ **Headers de segurança** - XSS, CSRF, etc.
- ✅ **Rate limiting** - Proteção contra spam
- ✅ **Backup automático** - Backup diário às 2:00 AM

## 📊 Monitoramento

### Status dos serviços

```bash
# Verificar todos os serviços
sudo systemctl status novusio nginx fail2ban ufw

# Verificar portas
sudo netstat -tlnp | grep -E ":(80|443|3000)"
```

### Logs importantes

```bash
# Aplicação
sudo journalctl -u novusio --since "1 hour ago"

# Nginx
sudo tail -f /var/log/nginx/novusio_access.log
sudo tail -f /var/log/nginx/novusio_error.log

# Sistema
sudo tail -f /var/log/syslog
```

## 🔄 Atualizações

### Deploy de atualizações

```bash
# Fazer pull das mudanças
cd /opt/novusio/app
git pull origin main

# Executar deploy
sudo -u novusio ./instalador/deploy.sh
```

### Atualizar sistema

```bash
# Atualizar sistema operacional
sudo apt update && sudo apt upgrade -y

# Renovar certificados SSL
sudo certbot renew
```

## 🆘 Solução de problemas

### Aplicação não inicia

```bash
# Verificar logs
sudo journalctl -u novusio -f

# Verificar configuração
sudo nginx -t

# Verificar permissões
sudo chown -R novusio:novusio /opt/novusio
```

### SSL não funciona

```bash
# Verificar certificados
sudo certbot certificates

# Testar renovação
sudo certbot renew --dry-run

# Verificar Nginx
sudo nginx -t
```

### Problemas de permissão

```bash
# Corrigir permissões
sudo chown -R novusio:novusio /opt/novusio
sudo chmod -R 755 /opt/novusio
sudo chmod 600 /opt/novusio/.env
```

## 📞 Suporte

Para problemas técnicos:

1. Verificar logs: `sudo journalctl -u novusio -f`
2. Verificar status: `sudo systemctl status novusio nginx`
3. Verificar SSL: `sudo certbot certificates`
4. Contatar: suporte@novusiopy.com

## 🎯 Checklist de deploy

- [ ] Servidor Ubuntu 20.04+ configurado
- [ ] Domínio apontando para o servidor
- [ ] Arquivos da aplicação enviados
- [ ] Script de instalação executado
- [ ] Arquivo .env configurado
- [ ] SSL configurado
- [ ] Aplicação iniciada e funcionando
- [ ] Backup automático funcionando
- [ ] Monitoramento configurado

---

**Desenvolvido com ❤️ para Novusio Paraguay 🇵🇾**
