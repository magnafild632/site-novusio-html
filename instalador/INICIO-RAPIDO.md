# 🚀 INÍCIO RÁPIDO - Novusio

## Como Iniciar o Projeto

Este guia mostra os passos necessários para fazer o deploy do seu projeto Novusio em um servidor VPS.

---

## 📋 Pré-requisitos

Antes de começar, você precisa ter:

1. ✅ **Servidor VPS** (Ubuntu 20.04+ ou Debian 11+)
2. ✅ **Acesso root** ao servidor (via SSH)
3. ✅ **Domínio** configurado apontando para o IP do servidor
4. ✅ **Repositório Git** com o código (ex: GitHub, GitLab)

---

## 🎯 Passo a Passo

### **1️⃣ Fazer Upload dos Arquivos**

#### Opção A: Clonar o Repositório no Servidor

```bash
# Conectar ao servidor
ssh root@seu-servidor.com

# Clonar o repositório
git clone https://github.com/seu-usuario/site-novusio-html.git
cd site-novusio-html/instalador
```

#### Opção B: Fazer Upload Manual

```bash
# No seu computador local
cd /Users/mac/Documents/GitHub/site-novusio-html
scp -r instalador/ root@seu-servidor.com:/root/

# Conectar ao servidor
ssh root@seu-servidor.com
cd /root/instalador
```

---

### **2️⃣ Executar o Script de Deploy**

```bash
# PRIMEIRO: Corrigir formato dos scripts (IMPORTANTE!)
bash fix-scripts.sh

# Agora executar o deploy
sudo ./deploy.sh
```

**⚠️ IMPORTANTE:** Se encontrar erro `cannot execute: required file not found`, execute:

```bash
bash fix-scripts.sh
```

---

### **3️⃣ Menu Interativo**

Você verá este menu:

```
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║              🚀 NOVUSIO DEPLOY AUTOMÁTICO 🚀                ║
║                                                              ║
║              Deploy completo para VPS Ubuntu/Debian          ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

📋 MENU PRINCIPAL - NOVUSIO
==================================
1. 🚀 Deploy Completo (Nova Instalação)
2. 🔄 Atualizar Aplicação
3. 🗑️  Remover Projeto Completamente
4. 📊 Status do Sistema
5. 🔧 Manutenção Rápida
6. 📝 Logs e Monitoramento
7. ❌ Sair

Escolha uma opção [1-7]:
```

**Escolha a opção `1` (Deploy Completo)**

---

### **4️⃣ Fornecer Informações**

O script pedirá as seguintes informações:

```bash
📋 CONFIGURAÇÃO INICIAL
==================================
🌐 Domínio (ex: novusio.com): SEU-DOMINIO.com
📧 Email para SSL (Let's Encrypt): seu-email@gmail.com
👤 Usuário do sistema (ex: novusio): novusio
🔧 Porta da aplicação [3000]: 3000
📁 Diretório do projeto [/opt/novusio]: /opt/novusio
🔗 Repositório Git: https://github.com/seu-usuario/site-novusio-html.git
```

**Preencha com suas informações!**

---

### **5️⃣ Aguardar Instalação**

O script irá automaticamente:

```
✓ Validar informações
✓ Verificar DNS
✓ Atualizar sistema
✓ Instalar Node.js, Nginx, PM2, Certbot
✓ Configurar firewall
✓ Clonar repositório
✓ Instalar dependências
✓ Fazer build da aplicação
✓ Gerar JWT_SECRET e SESSION_SECRET automaticamente
✓ Configurar PM2
✓ Configurar Nginx
✓ Instalar SSL (Let's Encrypt)
✓ Configurar backup automático
✓ Configurar monitoramento
✓ Inicializar banco de dados

🎉 Deploy concluído com sucesso!
```

**Tempo estimado: 5-10 minutos**

---

### **6️⃣ Acessar o Site**

Após o deploy, seu site estará disponível em:

```
🌐 Site público: https://seu-dominio.com
👤 Painel Admin: https://seu-dominio.com/admin
```

**Credenciais padrão do Admin:**

- **Usuário**: `admin`
- **Senha**: `admin123`

**⚠️ IMPORTANTE: Altere a senha padrão imediatamente!**

---

## 🔐 Informações de Segurança

### Secrets Gerados Automaticamente

O sistema gera automaticamente:

- ✅ **JWT_SECRET**: 48 bytes (384 bits)
- ✅ **SESSION_SECRET**: 32 bytes (256 bits)

**Localização do backup:**

```bash
/opt/novusio/.secrets-backup-TIMESTAMP.txt
```

**⚠️ Salve este arquivo em local seguro e delete do servidor!**

---

## 📊 Verificar se Está Funcionando

### Verificar Status da Aplicação

```bash
# Status PM2
sudo -u novusio pm2 status

# Deve mostrar:
│ novusio-server │ online │
```

### Verificar Nginx

```bash
# Status Nginx
systemctl status nginx

# Deve mostrar: active (running)
```

### Verificar SSL

```bash
# Listar certificados
certbot certificates

# Deve mostrar seu domínio
```

### Testar Acesso

```bash
# Testar HTTP (deve redirecionar para HTTPS)
curl -I http://seu-dominio.com

# Testar HTTPS
curl -I https://seu-dominio.com
```

---

## 🎛️ Comandos Úteis

### Gerenciar Aplicação

```bash
# Status
sudo ./novusio-cli.sh status

# Logs
sudo ./novusio-cli.sh logs

# Reiniciar
sudo ./novusio-cli.sh restart

# Parar
sudo ./novusio-cli.sh stop

# Iniciar
sudo ./novusio-cli.sh start
```

### Atualizar Código

```bash
# Atualizar do Git
sudo ./novusio-cli.sh update

# Ou pelo menu
sudo ./deploy.sh
# Escolha opção 2 (Atualizar Aplicação)
```

### Ver Logs

```bash
# Logs da aplicação
sudo -u novusio pm2 logs

# Logs do Nginx
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# Logs do sistema
journalctl -u nginx -f
```

---

## 🔧 Configurações Pós-Deploy

### 1. Alterar Senha do Admin

```
1. Acesse https://seu-dominio.com/admin
2. Faça login com admin/admin123
3. Vá em Configurações → Alterar Senha
4. Defina uma senha forte
```

### 2. Configurar Informações da Empresa

```
1. Acesse o Painel Admin
2. Vá em Configurações da Empresa
3. Atualize:
   - Nome da empresa
   - Email de contato
   - Telefone
   - Endereço
   - Redes sociais
```

### 3. Adicionar Conteúdo

```
1. Slides do Hero → Adicione imagens e textos
2. Serviços → Configure seus serviços
3. Portfólio → Adicione clientes
4. Mensagens → Configure notificações
```

---

## 🆘 Problemas Comuns

### 1. "DNS não aponta para o servidor"

```bash
# Verificar IP do servidor
curl ifconfig.me

# Verificar DNS do domínio
dig seu-dominio.com

# Espere alguns minutos para DNS propagar
```

### 2. "Porta já está em uso"

```bash
# Ver o que está usando a porta
netstat -tuln | grep :3000

# Ou escolha outra porta durante instalação
```

### 3. "Aplicação não inicia"

```bash
# Ver logs de erro
sudo -u novusio pm2 logs --err

# Reiniciar
sudo -u novusio pm2 restart novusio-server
```

### 4. "SSL não funciona"

```bash
# Verificar certificado
certbot certificates

# Renovar manualmente
certbot renew

# Verificar Nginx
nginx -t
systemctl reload nginx
```

---

## 📁 Estrutura Após Instalação

```
/opt/novusio/                          → Projeto principal
├── client/                            → Frontend React
│   └── dist/                          → Build de produção
├── server/                            → Backend Node.js
│   ├── routes/                        → Rotas da API
│   └── server.js                      → Servidor principal
├── uploads/                           → Arquivos enviados
├── database.sqlite                    → Banco de dados
├── .env                               → Variáveis de ambiente
├── .secrets-backup-TIMESTAMP.txt      → Backup dos secrets
└── ecosystem.config.js                → Configuração PM2

/etc/nginx/sites-available/            → Configurações Nginx
└── seu-dominio.com                    → Config do seu site

/var/log/novusio/                      → Logs da aplicação
├── error.log                          → Erros
├── out.log                            → Saída padrão
└── combined.log                       → Logs combinados

/opt/backups/novusio/                  → Backups automáticos
├── database_TIMESTAMP.sqlite          → Backup do banco
└── uploads_TIMESTAMP.tar.gz           → Backup dos uploads
```

---

## 🎯 Próximos Passos

Após o deploy bem-sucedido:

1. ✅ **Alterar senha padrão do admin**
2. ✅ **Configurar informações da empresa**
3. ✅ **Adicionar conteúdo (slides, serviços, portfólio)**
4. ✅ **Configurar email SMTP** (opcional, para notificações)
5. ✅ **Fazer backup manual** para testar
6. ✅ **Configurar monitoramento** (já está automático)
7. ✅ **Testar todas as funcionalidades**

---

## 📞 Suporte Rápido

### Comandos de Diagnóstico

```bash
# Status geral
sudo ./novusio-cli.sh status

# Informações do sistema
sudo ./novusio-cli.sh info

# Logs recentes
sudo ./novusio-cli.sh logs

# Monitoramento
sudo ./novusio-cli.sh monitor
```

### Arquivos Importantes

```bash
# Configuração da aplicação
/opt/novusio/.env

# Configuração Nginx
/etc/nginx/sites-available/seu-dominio.com

# Logs
/var/log/novusio/
/var/log/nginx/

# Banco de dados
/opt/novusio/database.sqlite
```

---

## 🎉 Pronto!

Seu site Novusio está online e funcionando! 🚀

- ✅ **Frontend React** rodando
- ✅ **Backend Node.js** rodando
- ✅ **Nginx** configurado
- ✅ **SSL** ativo
- ✅ **PM2** gerenciando
- ✅ **Firewall** configurado
- ✅ **Backup** automático
- ✅ **Monitoramento** ativo

**Aproveite seu novo site!** 🎊
