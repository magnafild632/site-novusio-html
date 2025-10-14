# 🚀 Instalador Automático - Site Novusio

Sistema completo de instalação e deploy para VPS com todas as configurações necessárias para produção.

## 📋 Pré-requisitos

- Ubuntu 20.04+ ou Debian 11+
- Usuário com sudo
- Domínio configurado apontando para o servidor
- Acesso SSH ao servidor

## 🎯 O que será instalado

- ✅ **Node.js 18+** - Runtime JavaScript
- ✅ **PM2** - Gerenciador de processos
- ✅ **Nginx** - Servidor web e proxy reverso
- ✅ **Certbot** - Certificados SSL automáticos
- ✅ **Fail2ban** - Proteção contra ataques
- ✅ **UFW Firewall** - Firewall básico
- ✅ **Systemd** - Inicialização automática
- ✅ **Backup automático** - Backup diário do banco

## 🚀 Instalação Rápida

### 1. Preparar o servidor

```bash
# Conectar via SSH
ssh usuario@seu-servidor.com

# Clonar o repositório (ou fazer upload dos arquivos)
git clone https://github.com/seu-usuario/site-novusio-html.git
cd site-novusio-html
```

### 2. Usar o Menu Interativo (Recomendado)

```bash
# Tornar scripts executáveis
chmod +x instalador/*.sh

# Executar menu principal
./instalador/menu-principal.sh
```

### 3. Ou executar instalação direta

```bash
# Tornar o script executável
chmod +x instalador/install.sh

# Executar instalação
sudo ./instalador/install.sh
```

### 4. Configurar SSL

```bash
# Executar configuração SSL
sudo ./instalador/setup-ssl.sh
```

### 5. Verificar sistema

```bash
# Verificar se tudo está funcionando
./instalador/verificar-sistema.sh
```

### 6. Verificar aplicação

```bash
# A aplicação já foi iniciada automaticamente
# Verificar status
sudo systemctl status novusio

# Se necessário, reiniciar
sudo systemctl restart novusio
```

## 📁 Estrutura dos Arquivos

```
instalador/
├── README.md                 # Este arquivo
├── menu-principal.sh         # Menu interativo principal
├── install.sh               # Instalação automática completa
├── configurar-env.sh        # Configurador de .env
├── setup-ssl.sh             # Configuração SSL com Certbot
├── deploy.sh                # Script de deploy
├── backup.sh                # Script de backup
├── verificar-sistema.sh     # Verificador de sistema
├── verificar-antes-commit.sh # Verificador pré-deploy
├── regenerate-secrets.sh    # Gerador de secrets
├── novusio-manager.sh       # Gerenciador da aplicação
├── ecosystem.config.js      # Configuração PM2
├── nginx.conf               # Configuração Nginx
├── novusio.service          # Serviço systemd
├── fail2ban.conf            # Configuração Fail2ban
├── fail2ban-filters.conf    # Filtros Fail2ban
├── env.production.template  # Template .env para produção
└── INSTRUCOES-DEPLOY.md     # Instruções detalhadas
```

## 🎛️ Menu Interativo

O menu principal oferece uma interface amigável para todas as operações:

```bash
# Executar menu interativo
./instalador/menu-principal.sh
```

**Opções disponíveis:**
- 🆕 **Instalação Completa** - Instalar tudo do zero (inclui .env automático)
- 🔄 **Atualizar Aplicação** - Deploy de atualizações
- ⚙️ **Configurar .env** - Reconfigurar variáveis de ambiente
- 🔒 **Configurar SSL** - Instalar certificados SSL
- 💾 **Backup/Restore** - Gerenciar backups
- 🛠️ **Gerenciar Serviços** - Controlar aplicação
- 🔍 **Verificar Sistema** - Diagnóstico completo
- 🆘 **Suporte e Logs** - Ajuda e troubleshooting

## 🔧 Comandos Úteis

### Gerenciar aplicação

```bash
# Status da aplicação
sudo systemctl status novusio

# Parar aplicação
sudo systemctl stop novusio

# Iniciar aplicação
sudo systemctl start novusio

# Reiniciar aplicação
sudo systemctl restart novusio

# Ver logs
sudo journalctl -u novusio -f
```

### PM2 (alternativo)

```bash
# Status
pm2 status

# Parar
pm2 stop novusio

# Iniciar
pm2 start novusio

# Reiniciar
pm2 restart novusio

# Logs
pm2 logs novusio
```

### Nginx

```bash
# Testar configuração
sudo nginx -t

# Recarregar configuração
sudo systemctl reload nginx

# Status
sudo systemctl status nginx
```

### SSL

```bash
# Renovar certificados
sudo certbot renew

# Testar renovação
sudo certbot renew --dry-run
```

## 🔒 Segurança

O instalador configura automaticamente:

- **Firewall UFW** com portas 22, 80, 443
- **Fail2ban** para proteção contra ataques
- **Certificados SSL** automáticos
- **Headers de segurança** no Nginx
- **Rate limiting** para APIs
- **Backup automático** diário

## 📊 Monitoramento

### Logs importantes

```bash
# Aplicação
sudo journalctl -u novusio -f

# Nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Fail2ban
sudo tail -f /var/log/fail2ban.log
```

### Status dos serviços

```bash
# Verificar todos os serviços
sudo systemctl status novusio nginx fail2ban ufw
```

## 🔄 Backup e Restore

### Backup automático

O backup é executado diariamente às 2:00 AM via cron.

### Backup manual

```bash
# Executar backup manual
sudo ./instalador/backup.sh
```

### Restore

```bash
# Restaurar backup
sudo ./instalador/restore.sh /caminho/para/backup.tar.gz
```

## 🆘 Solução de Problemas

### Aplicação não inicia

```bash
# Verificar logs
sudo journalctl -u novusio -f

# Verificar configuração
sudo nginx -t

# Verificar portas
sudo netstat -tlnp | grep :3000
```

### SSL não funciona

```bash
# Verificar certificados
sudo certbot certificates

# Renovar certificados
sudo certbot renew --force-renewal
```

### Nginx não carrega

```bash
# Verificar configuração
sudo nginx -t

# Verificar sintaxe
sudo cat /etc/nginx/sites-available/novusio
```

## 📞 Suporte

Para problemas técnicos:

1. Verificar logs: `sudo journalctl -u novusio -f`
2. Verificar status: `sudo systemctl status novusio nginx`
3. Verificar SSL: `sudo certbot certificates`
4. Contatar: suporte@novusiopy.com

---

**Desenvolvido com ❤️ para Novusio Paraguay 🇵🇾**
