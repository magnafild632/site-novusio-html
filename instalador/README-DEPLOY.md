# 🚀 Sistema de Deploy Automático - Novusio

Este sistema fornece um deploy completo e automatizado para VPS, incluindo todas as configurações necessárias para produção.

## 📋 Pré-requisitos

- **VPS Ubuntu/Debian** (Ubuntu 20.04+ ou Debian 11+)
- **Acesso root** ao servidor
- **Domínio configurado** apontando para o IP do servidor
- **Repositório Git** com o código da aplicação

## 🔧 Instalação Rápida

### 1. Conectar ao servidor

```bash
ssh root@seu-servidor.com
```

### 2. Baixar o script de deploy

```bash
# Opção 1: Clonar o repositório
git clone https://github.com/seu-usuario/site-novusio-html.git
cd site-novusio-html/instalador

# Opção 2: Baixar diretamente
wget https://raw.githubusercontent.com/seu-usuario/site-novusio-html/main/instalador/deploy.sh
chmod +x deploy.sh
```

### 3. Executar o deploy

```bash
# Menu interativo completo
sudo ./deploy.sh

# Deploy rápido (sem menu)
sudo ./quick-deploy.sh

# Comandos rápidos
sudo ./novusio-cli.sh help
```

## 📋 Menu Interativo

O script principal agora inclui um menu interativo com as seguintes opções:

### 🚀 Menu Principal

1. **Deploy Completo** - Nova instalação completa
2. **Atualizar Aplicação** - Update do código e dependências
3. **Remover Projeto** - Deletar completamente o projeto
4. **Status do Sistema** - Verificar status e recursos
5. **Manutenção Rápida** - Limpeza e otimização
6. **Logs e Monitoramento** - Visualizar logs
7. **Sair** - Sair do script

O script irá solicitar as seguintes informações:

- **Domínio** (ex: novusio.com)
- **Email** para SSL (Let's Encrypt)
- **Usuário** do sistema (ex: novusio)
- **Porta** da aplicação (padrão: 3000)
- **Diretório** do projeto (padrão: /opt/novusio)
- **Repositório Git** da aplicação

## 🛠️ O que é instalado

### Pacotes do Sistema

- **Node.js 18.x** - Runtime JavaScript
- **Nginx** - Servidor web e proxy reverso
- **PM2** - Gerenciador de processos Node.js
- **Certbot** - Certificados SSL automáticos
- **UFW** - Firewall
- **Fail2ban** - Proteção contra ataques
- **Git** - Controle de versão

### Configurações Automáticas

- ✅ **SSL/TLS** com Let's Encrypt
- ✅ **Firewall** configurado (portas 22, 80, 443)
- ✅ **Nginx** com proxy reverso
- ✅ **PM2** com clustering e restart automático
- ✅ **Backup automático** diário
- ✅ **Monitoramento** a cada 5 minutos
- ✅ **Rate limiting** e proteção contra ataques
- ✅ **Headers de segurança**
- ✅ **Compressão Gzip**
- ✅ **Cache de arquivos estáticos**

## 📁 Estrutura de Arquivos

```
instalador/
├── deploy.sh                    # Script principal com menu interativo
├── quick-deploy.sh              # Deploy rápido sem menu
├── novusio-cli.sh               # CLI para comandos rápidos
├── ecosystem.config.js          # Configuração PM2
├── nginx.conf                   # Configuração Nginx
├── env.production.template      # Template de variáveis de ambiente
├── backup.sh                    # Script de backup automático
├── monitor.sh                   # Script de monitoramento
├── systemd.service              # Serviço systemd
├── fail2ban.conf                # Configuração Fail2ban
├── fail2ban-filters.conf        # Filtros personalizados
└── README-DEPLOY.md             # Este arquivo
```

### 🆕 Novas Funcionalidades

#### Menu Interativo

- ✅ **Deploy Completo** - Instalação nova com todas as configurações
- ✅ **Atualizar Aplicação** - Update do código sem reinstalar tudo
- ✅ **Remover Projeto** - Deletar completamente (com confirmação)
- ✅ **Status do Sistema** - Monitoramento em tempo real
- ✅ **Manutenção Rápida** - Limpeza e otimização automática
- ✅ **Logs e Monitoramento** - Visualização de logs centralizada

#### CLI Rápido

- ✅ **Comandos diretos** - Execute ações sem menu
- ✅ **Automação** - Ideal para scripts e cron jobs
- ✅ **Feedback visual** - Cores e status em tempo real

#### Segurança Automática

- ✅ **Geração automática de JWT_SECRET** - 48 bytes seguros
- ✅ **Geração automática de SESSION_SECRET** - 32 bytes seguros
- ✅ **Backup dos secrets** - Arquivo seguro para referência
- ✅ **Regeneração de secrets** - Script dedicado quando necessário

## 🔐 Configurações de Segurança

### Firewall (UFW)

- **SSH (22)** - Acesso administrativo
- **HTTP (80)** - Redirecionamento para HTTPS
- **HTTPS (443)** - Tráfego seguro
- **Porta da aplicação** - Se diferente de 80/443

### Fail2ban

- **SSH** - Proteção contra força bruta
- **Nginx** - Proteção contra ataques web
- **API** - Rate limiting e proteção
- **Admin** - Proteção do painel administrativo

### SSL/TLS

- **Let's Encrypt** - Certificados gratuitos
- **Renovação automática** - Via cron
- **HSTS** - HTTP Strict Transport Security
- **Headers de segurança** - CSP, X-Frame-Options, etc.

## 📊 Monitoramento

### Scripts Automáticos

- **backup.sh** - Backup diário às 2h
- **monitor.sh** - Monitoramento a cada 5 minutos

### Verificações

- ✅ Status da aplicação PM2
- ✅ Uso de memória e CPU
- ✅ Espaço em disco
- ✅ Conectividade da aplicação
- ✅ Certificado SSL
- ✅ Logs de erro
- ✅ Status dos serviços

### Logs

- `/var/log/novusio/` - Logs da aplicação
- `/var/log/nginx/` - Logs do Nginx
- `/var/log/novusio-backup.log` - Logs de backup
- `/var/log/novusio-monitor.log` - Logs de monitoramento

## 🎛️ Comandos Úteis

### CLI Rápido (Novusio CLI)

```bash
# Comandos básicos
sudo ./novusio-cli.sh start      # Iniciar aplicação
sudo ./novusio-cli.sh stop       # Parar aplicação
sudo ./novusio-cli.sh restart    # Reiniciar aplicação
sudo ./novusio-cli.sh status     # Status da aplicação
sudo ./novusio-cli.sh logs       # Ver logs
sudo ./novusio-cli.sh update     # Atualizar aplicação
sudo ./novusio-cli.sh backup     # Backup manual
sudo ./novusio-cli.sh monitor    # Executar monitoramento
sudo ./novusio-cli.sh ssl        # Renovar SSL
sudo ./novusio-cli.sh nginx      # Recarregar Nginx
sudo ./novusio-cli.sh maintenance # Manutenção rápida
sudo ./novusio-cli.sh info       # Informações do sistema
sudo ./novusio-cli.sh menu       # Abrir menu interativo
sudo ./novusio-cli.sh help       # Ajuda
```

### Gerenciamento Manual da Aplicação

```bash
# Status da aplicação
sudo -u novusio pm2 status

# Logs da aplicação
sudo -u novusio pm2 logs

# Reiniciar aplicação
sudo -u novusio pm2 restart novusio-server

# Parar aplicação
sudo -u novusio pm2 stop novusio-server

# Iniciar aplicação
sudo -u novusio pm2 start novusio-server
```

### Gerenciamento do Nginx

```bash
# Testar configuração
nginx -t

# Recarregar configuração
systemctl reload nginx

# Status do Nginx
systemctl status nginx

# Logs do Nginx
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

### SSL e Certificados

```bash
# Renovar certificado
certbot renew

# Status dos certificados
certbot certificates

# Testar renovação
certbot renew --dry-run
```

### Secrets de Segurança

```bash
# Regenerar JWT_SECRET e SESSION_SECRET
sudo /opt/novusio/instalador/regenerate-secrets.sh

# Ou usando o script do instalador
cd /opt/novusio/instalador
sudo ./regenerate-secrets.sh

# Ver secrets atuais (apenas para debug)
grep -E "JWT_SECRET|SESSION_SECRET" /opt/novusio/.env

# Ver backup de secrets
ls -la /opt/novusio/.secrets-*
```

### Backup e Monitoramento

```bash
# Executar backup manual
/usr/local/bin/novusio-backup.sh

# Executar monitoramento manual
/usr/local/bin/novusio-monitor.sh

# Ver logs de backup
tail -f /var/log/novusio-backup.log

# Ver logs de monitoramento
tail -f /var/log/novusio-monitor.log
```

## 🔧 Configurações Avançadas

### Variáveis de Ambiente

Edite o arquivo `.env` em `/opt/novusio/`:

```bash
nano /opt/novusio/.env
```

### Configuração do Nginx

Edite a configuração do Nginx:

```bash
nano /etc/nginx/sites-available/novusio
```

### Configuração do PM2

Edite a configuração do PM2:

```bash
nano /opt/novusio/ecosystem.config.js
```

## 🚨 Troubleshooting

### Aplicação não inicia

```bash
# Verificar logs
sudo -u novusio pm2 logs

# Verificar configuração
nginx -t

# Verificar portas
netstat -tlnp | grep :3000
```

### SSL não funciona

```bash
# Verificar certificado
certbot certificates

# Testar renovação
certbot renew --dry-run

# Verificar Nginx
nginx -t
```

### Backup não funciona

```bash
# Verificar permissões
ls -la /opt/backups/novusio

# Executar backup manual
/usr/local/bin/novusio-backup.sh

# Verificar logs
tail -f /var/log/novusio-backup.log
```

## 📞 Suporte

### Logs Importantes

- `/var/log/novusio/error.log` - Erros da aplicação
- `/var/log/nginx/error.log` - Erros do Nginx
- `/var/log/novusio-monitor.log` - Monitoramento
- `/var/log/novusio-backup.log` - Backup

### Comandos de Diagnóstico

```bash
# Status geral do sistema
systemctl status nginx fail2ban

# Status da aplicação
sudo -u novusio pm2 status

# Uso de recursos
htop
df -h
free -h

# Conectividade
curl -I https://seu-dominio.com
```

## 🔄 Atualizações

### Atualizar a aplicação

```bash
cd /opt/novusio
git pull origin main
npm ci
npm run build
sudo -u novusio pm2 restart novusio-server
```

### Atualizar o sistema

```bash
apt update && apt upgrade -y
```

## 📝 Notas Importantes

1. **Altere a senha padrão** do admin imediatamente após o deploy
2. **Configure backup regular** dos dados importantes
3. **Monitore os logs** regularmente
4. **Mantenha o sistema atualizado** com patches de segurança
5. **Configure notificações** para alertas importantes
6. **Teste o backup** periodicamente

## 🎯 Próximos Passos

Após o deploy:

1. ✅ Acesse `https://seu-dominio.com/admin`
2. ✅ Faça login com as credenciais padrão
3. ✅ Configure as informações da empresa
4. ✅ Altere a senha do admin
5. ✅ Configure backup e monitoramento
6. ✅ Teste todas as funcionalidades

---

**🎉 Deploy concluído com sucesso!** Seu site Novusio está online e pronto para uso.
