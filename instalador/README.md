# 🚀 Sistema de Deploy - Site Novusio

Sistema completo de instalação e gerenciamento para VPS Ubuntu Server.

## 📋 Visão Geral

Este sistema automatiza completamente a instalação, configuração e gerenciamento do Site Novusio em servidores Ubuntu, incluindo:

- ✅ Instalação automática de dependências
- ✅ Configuração de Nginx com SSL
- ✅ Serviço systemd para produção
- ✅ Firewall e segurança
- ✅ Backup automático
- ✅ Monitoramento e logs

## 📁 Arquivos Incluídos

| Arquivo | Descrição |
|---------|-----------|
| `deploy.sh` | Script principal de instalação |
| `menu.sh` | Menu de gerenciamento do sistema |
| `setup-ssl.sh` | Configuração SSL com Let's Encrypt |
| `backup.sh` | Sistema de backup automático |
| `verificar-sistema.sh` | Diagnóstico completo do sistema |
| `nginx.conf` | Configuração otimizada do Nginx |
| `novusio.service` | Arquivo de serviço systemd |
| `env.production.template` | Template de configuração |

## 🚀 Instalação Rápida

### 1. Preparar o Servidor

```bash
# Conectar ao servidor via SSH
ssh usuario@seu-servidor.com

# Clonar o repositório
git clone https://github.com/seu-usuario/site-novusio-html.git
cd site-novusio-html/instalador

# Dar permissões de execução
chmod +x *.sh
```

### 2. Executar Instalação

```bash
# Executar script de deploy
./deploy.sh
```

O script irá solicitar:
- 🌐 Domínio do site
- 👤 Usuário Linux
- 🔗 URL do repositório Git
- 🔌 Porta do servidor (padrão: 3000)
- 📧 Email para certificados SSL

### 3. Acessar o Sistema

Após a instalação:
- **Site**: `https://seu-dominio.com`
- **Painel Admin**: `https://seu-dominio.com/admin`
- **API**: `https://seu-dominio.com/api`

## 🎛️ Gerenciamento

### Menu Principal

```bash
# Executar menu de gerenciamento
./menu.sh
```

Opções disponíveis:
1. 🚀 Instalar Projeto
2. 🔄 Atualizar Projeto
3. 📊 Ver Status do Sistema
4. 📝 Gerenciar Logs
5. 💾 Backup do Projeto
6. 🔄 Restaurar Backup
7. 🗑️ Remover Projeto

### Comandos Úteis

```bash
# Status do serviço
sudo systemctl status novusio

# Reiniciar serviço
sudo systemctl restart novusio

# Ver logs em tempo real
sudo journalctl -u novusio -f

# Ver logs do Nginx
sudo tail -f /var/log/nginx/novusio_error.log

# Status SSL
sudo certbot certificates

# Backup manual
./backup.sh

# Verificar sistema
./verificar-sistema.sh
```

## 🔧 Configurações

### Arquivo .env

O arquivo `.env` é criado automaticamente durante a instalação:

```env
NODE_ENV=production
PORT=3000
JWT_SECRET=seu_secret_jwt
ADMIN_EMAIL=admin@seu-dominio.com
ADMIN_PASSWORD=senha_gerada_automaticamente
DOMAIN=seu-dominio.com
```

### Nginx

Configuração otimizada para produção:
- ✅ SSL/TLS moderno
- ✅ HSTS habilitado
- ✅ Compressão gzip
- ✅ Rate limiting
- ✅ Cache de arquivos estáticos

### Segurança

- 🔒 Firewall UFW configurado
- 🛡️ Fail2ban para proteção SSH
- 🔐 Certificados SSL automáticos
- 🔑 Senhas seguras geradas automaticamente

## 📊 Monitoramento

### Verificação do Sistema

```bash
# Executar diagnóstico completo
./verificar-sistema.sh
```

Verifica:
- ✅ Status dos serviços
- ✅ Uso de recursos
- ✅ Conectividade
- ✅ SSL e certificados
- ✅ Logs e erros
- ✅ Segurança

### Logs

```bash
# Logs do aplicativo
sudo journalctl -u novusio -f

# Logs do Nginx
sudo tail -f /var/log/nginx/novusio_access.log
sudo tail -f /var/log/nginx/novusio_error.log

# Logs do sistema
sudo tail -f /var/log/syslog
```

## 💾 Backup e Restauração

### Backup Automático

```bash
# Backup manual
./backup.sh

# Backup com retenção personalizada
./backup.sh --retention 7
```

### Restauração

```bash
# Via menu
./menu.sh
# Escolher opção 6: Restaurar Backup

# Manual
sudo systemctl stop novusio
tar -xzf /home/usuario/backups/novusio_backup_YYYYMMDD_HHMMSS.tar.gz
sudo systemctl start novusio
```

## 🔄 Atualizações

### Atualização Automática

```bash
# Via menu
./menu.sh
# Escolher opção 2: Atualizar Projeto
```

### Atualização Manual

```bash
cd /home/usuario/site-novusio
sudo systemctl stop novusio
git pull origin main
npm install
cd client && npm install
cd .. && npm run build
sudo systemctl start novusio
```

## 🛠️ Solução de Problemas

### Serviço não inicia

```bash
# Verificar status
sudo systemctl status novusio

# Verificar logs
sudo journalctl -u novusio -n 50

# Verificar configuração
sudo systemctl daemon-reload
sudo systemctl restart novusio
```

### Nginx com problemas

```bash
# Verificar configuração
sudo nginx -t

# Verificar status
sudo systemctl status nginx

# Recarregar configuração
sudo systemctl reload nginx
```

### SSL não funciona

```bash
# Verificar certificados
sudo certbot certificates

# Renovar certificados
sudo certbot renew

# Reconfigurar SSL
./setup-ssl.sh
```

### Banco de dados

```bash
# Verificar arquivo
ls -la /home/usuario/site-novusio/database.sqlite

# Fazer backup
cp database.sqlite database.sqlite.backup

# Reinicializar banco
npm run init-db
```

## 📋 Requisitos do Sistema

### Mínimos
- Ubuntu 20.04 LTS ou superior
- 1 CPU core
- 1GB RAM
- 10GB espaço em disco
- Conexão com internet

### Recomendados
- Ubuntu 22.04 LTS
- 2 CPU cores
- 2GB RAM
- 20GB espaço em disco
- Conexão estável

### Dependências Instaladas Automaticamente
- Node.js LTS
- npm
- Nginx
- Certbot
- SQLite3
- UFW (Firewall)
- Fail2ban
- Supervisor

## 🔐 Segurança

### Checklist de Segurança

- ✅ Firewall configurado (UFW)
- ✅ Fail2ban ativo
- ✅ SSL/TLS habilitado
- ✅ Senhas seguras
- ✅ Usuário não-root
- ✅ Logs monitorados
- ✅ Updates automáticos

### Manutenção

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade

# Verificar segurança
sudo ufw status
sudo fail2ban-client status

# Limpar logs antigos
sudo journalctl --vacuum-time=7d
```

## 📞 Suporte

### Logs Importantes

```bash
# Logs da aplicação
/var/log/syslog

# Logs do Nginx
/var/log/nginx/novusio_access.log
/var/log/nginx/novusio_error.log

# Logs do SSL
/var/log/letsencrypt/letsencrypt.log
```

### Informações do Sistema

```bash
# Informações detalhadas
./verificar-sistema.sh > sistema.log

# Status completo
sudo systemctl status novusio nginx fail2ban
```

## 📝 Changelog

### v1.0.0
- ✅ Instalação automática completa
- ✅ Configuração SSL automática
- ✅ Sistema de backup
- ✅ Menu de gerenciamento
- ✅ Verificação de sistema
- ✅ Documentação completa

## 🤝 Contribuição

Para contribuir com melhorias:

1. Fork o projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo LICENSE para mais detalhes.

---

**Desenvolvido com ❤️ para Novusio Paraguay**
