# 📁 Pasta Instalador - Novusio

Esta pasta contém todos os arquivos essenciais para instalação, configuração e manutenção do Novusio.

## 🚀 Arquivos Principais

### 📋 Scripts de Gerenciamento

#### `novusio-manager.sh` - **GERENCIADOR PRINCIPAL**
Script unificado para todas as operações de gerenciamento:
```bash
# Comandos básicos
sudo ./novusio-manager.sh start      # Iniciar aplicação
sudo ./novusio-manager.sh stop       # Parar aplicação
sudo ./novusio-manager.sh restart    # Reiniciar aplicação
sudo ./novusio-manager.sh status     # Status da aplicação

# Comandos de manutenção
sudo ./novusio-manager.sh monitor    # Monitoramento completo
sudo ./novusio-manager.sh backup     # Backup manual
sudo ./novusio-manager.sh maintenance # Manutenção rápida
sudo ./novusio-manager.sh cleanup    # Limpeza do sistema

# Comandos de serviços
sudo ./novusio-manager.sh ssl        # Renovar SSL
sudo ./novusio-manager.sh nginx      # Recarregar Nginx
sudo ./novusio-manager.sh services   # Status dos serviços

# Comandos de monitoramento
sudo ./novusio-manager.sh health     # Verificação rápida
sudo ./novusio-manager.sh resources  # Recursos do sistema
sudo ./novusio-manager.sh security   # Verificação de segurança
sudo ./novusio-manager.sh report     # Relatório completo

# Comandos de configuração
sudo ./novusio-manager.sh deploy     # Deploy completo
sudo ./novusio-manager.sh config     # Ver configurações
sudo ./novusio-manager.sh info       # Informações do sistema
```

#### `deploy.sh` - **DEPLOY COMPLETO**
Script principal para instalação e deploy completo:
```bash
sudo ./deploy.sh
```

#### `backup.sh` - **BACKUP AUTOMÁTICO**
Script para backup completo do sistema:
```bash
sudo ./backup.sh
```

### ⚙️ Arquivos de Configuração

#### `nginx.conf` - **CONFIGURAÇÃO DO NGINX**
Configuração completa do Nginx com:
- SSL/HTTPS
- Proxy reverso
- Rate limiting
- Compressão
- Cache
- Segurança

#### `ecosystem.config.js` - **CONFIGURAÇÃO DO PM2**
Configuração do PM2 para gerenciamento de processos:
- Cluster mode
- Auto-restart
- Logs
- Monitoramento

#### `systemd.service` - **SERVIÇO SYSTEMD**
Configuração do systemd para inicialização automática:
- Auto-start
- Dependências
- Permissões
- Logs

#### `env.production.template` - **VARIÁVEIS DE AMBIENTE**
Template com todas as variáveis de ambiente necessárias:
- Banco de dados
- Autenticação
- Uploads
- SSL
- Monitoramento

### 🔒 Arquivos de Segurança

#### `fail2ban.conf` - **CONFIGURAÇÃO DO FAIL2BAN**
Configuração do Fail2ban para proteção contra ataques:
- SSH
- HTTP
- Nginx

#### `fail2ban-filters.conf` - **FILTROS DO FAIL2BAN**
Filtros personalizados para detecção de ataques.

#### `regenerate-secrets.sh` - **GERADOR DE SECRETS**
Script para regenerar chaves secretas:
```bash
sudo ./regenerate-secrets.sh
```

## 📖 Como Usar

### 🚀 Instalação Inicial
```bash
# 1. Clone o repositório
git clone <repo-url>
cd site-novusio-html

# 2. Execute o deploy completo
sudo ./instalador/deploy.sh

# 3. Configure as variáveis de ambiente
sudo cp ./instalador/env.production.template .env
sudo nano .env

# 4. Inicie o serviço
sudo ./instalador/novusio-manager.sh start
```

### 🔄 Atualizações
```bash
# Atualização rápida (inclui correção automática de permissões do Git)
sudo ./instalador/novusio-manager.sh update

# Deploy completo
sudo ./instalador/deploy.sh
```

### 📊 Monitoramento
```bash
# Verificação rápida
sudo ./instalador/novusio-manager.sh health

# Monitoramento completo
sudo ./instalador/novusio-manager.sh monitor

# Relatório detalhado
sudo ./instalador/novusio-manager.sh report
```

### 🔧 Manutenção
```bash
# Manutenção rápida
sudo ./instalador/novusio-manager.sh maintenance

# Backup manual
sudo ./instalador/novusio-manager.sh backup

# Limpeza do sistema
sudo ./instalador/novusio-manager.sh cleanup
```

## 🎯 Estrutura de Arquivos

```
instalador/
├── 📋 SCRIPTS PRINCIPAIS
│   ├── novusio-manager.sh    # Gerenciador unificado
│   ├── deploy.sh             # Deploy completo
│   └── backup.sh             # Backup automático
│
├── ⚙️ CONFIGURAÇÕES
│   ├── nginx.conf            # Nginx
│   ├── ecosystem.config.js   # PM2
│   ├── systemd.service       # Systemd
│   └── env.production.template # Variáveis de ambiente
│
├── 🔒 SEGURANÇA
│   ├── fail2ban.conf         # Fail2ban
│   ├── fail2ban-filters.conf # Filtros
│   └── regenerate-secrets.sh # Gerador de secrets
│
└── 📖 DOCUMENTAÇÃO
    └── README.md             # Este arquivo
```

## 🚨 Comandos de Emergência

### 🔥 Problemas Críticos
```bash
# Aplicação não inicia
sudo ./novusio-manager.sh restart
sudo ./novusio-manager.sh logs

# Site fora do ar
sudo ./novusio-manager.sh health
sudo ./novusio-manager.sh nginx

# SSL expirado
sudo ./novusio-manager.sh ssl

# Sistema com problemas
sudo ./novusio-manager.sh maintenance
sudo ./novusio-manager.sh cleanup
```

### 📞 Logs e Debug
```bash
# Logs da aplicação
sudo ./novusio-manager.sh logs

# Status detalhado
sudo ./novusio-manager.sh status

# Recursos do sistema
sudo ./novusio-manager.sh resources

# Relatório completo
sudo ./novusio-manager.sh report
```

## ⚠️ Importante

- **Sempre execute como root**: `sudo ./script.sh`
- **Faça backup antes de mudanças**: `sudo ./novusio-manager.sh backup`
- **Monitore regularmente**: `sudo ./novusio-manager.sh monitor`
- **Mantenha atualizado**: `sudo ./novusio-manager.sh update`

## 🔗 Links Úteis

- **Logs**: `/var/log/novusio/`
- **Configurações**: `/home/novusio/`
- **Backups**: `/opt/backups/novusio/`
- **SSL**: `/etc/letsencrypt/live/`

---

**📧 Suporte**: Para dúvidas ou problemas, consulte os logs ou execute o monitoramento completo.
