# 🛡️ ISOLAMENTO E SEGURANÇA - NOVUSIO

## Garantia de Não Interferência em Outros Projetos

Este documento explica como o sistema de deploy Novusio **NÃO interfere** em outros projetos ou configurações existentes no servidor.

---

## 🔒 Isolamento Completo

### 1. **Diretório Isolado**

- ✅ Projeto instalado em diretório específico: `/opt/novusio` (ou personalizado)
- ✅ Verificação de diretório existente antes de instalar
- ✅ Todos os arquivos contidos no diretório do projeto
- ✅ Nenhuma modificação em outros diretórios de projetos

**Validações:**

```bash
# Verifica se o diretório já existe e não está vazio
if [[ -d "$PROJECT_DIR" ]] && [[ "$(ls -A $PROJECT_DIR)" ]]; then
    warning "O diretório já existe!"
    # Solicita confirmação antes de continuar
fi
```

---

### 2. **Porta Específica**

- ✅ Aplicação roda em porta específica (padrão: 3000)
- ✅ Verificação de porta em uso antes de configurar
- ✅ Não interfere com outras aplicações rodando em outras portas
- ✅ Proxy reverso via Nginx isolado por domínio

**Validações:**

```bash
# Verifica se a porta já está em uso
if netstat -tuln | grep -q ":$APP_PORT "; then
    warning "A porta $APP_PORT já está em uso!"
    # Solicita confirmação ou escolha de outra porta
fi
```

---

### 3. **Usuário Dedicado**

- ✅ Aplicação roda com usuário específico (ex: `novusio`)
- ✅ Permissões isoladas apenas para este usuário
- ✅ Verificação se usuário já existe
- ✅ Não afeta usuários de outros projetos

**Validações:**

```bash
# Verifica se o usuário já existe
if id "$USERNAME" &>/dev/null; then
    warning "O usuário $USERNAME já existe!"
    # Permite reutilizar ou criar novo
fi
```

---

### 4. **Configuração Nginx Isolada**

- ✅ Arquivo de configuração específico para o domínio
- ✅ Nome do arquivo: `/etc/nginx/sites-available/SEU_DOMINIO`
- ✅ **NÃO remove** configurações de outros sites
- ✅ **NÃO remove** configuração padrão se houver outros sites
- ✅ Testa configuração antes de aplicar

**Proteções:**

```bash
# Verifica se já existe configuração para este domínio
if [[ -f "/etc/nginx/sites-available/$DOMAIN" ]]; then
    warning "Já existe configuração para este domínio!"
    # Solicita confirmação antes de sobrescrever
fi

# NÃO remove default se houver outros sites
if [[ $(ls -A /etc/nginx/sites-enabled/ | wc -l) -gt 1 ]]; then
    # Mantém configuração padrão
fi

# Testa antes de aplicar
if nginx -t; then
    # Aplica apenas se teste passar
else
    # Reverte alterações
fi
```

---

### 5. **Certificados SSL Isolados**

- ✅ Certificado específico para o domínio do projeto
- ✅ Let's Encrypt gerencia certificados por domínio
- ✅ **NÃO afeta** certificados de outros domínios
- ✅ Renovação automática apenas do certificado específico

**Isolamento:**

```bash
# Certificado específico para o domínio
/etc/letsencrypt/live/SEU_DOMINIO/fullchain.pem
/etc/letsencrypt/live/SEU_DOMINIO/privkey.pem

# Outros domínios permanecem intactos
/etc/letsencrypt/live/outro-dominio.com/...
```

---

### 6. **PM2 Isolado**

- ✅ Aplicação registrada com nome específico: `novusio-server`
- ✅ Roda no contexto do usuário dedicado
- ✅ **NÃO interfere** com outras aplicações PM2
- ✅ Logs separados por aplicação

**Isolamento:**

```bash
# Aplicação específica
pm2 list
│ novusio-server  │ online │
│ outro-projeto   │ online │  # Não afetado
│ mais-um-projeto │ online │  # Não afetado

# Comandos afetam apenas o Novusio
pm2 restart novusio-server  # Reinicia APENAS esta aplicação
```

---

### 7. **Firewall Não Invasivo**

- ✅ **NÃO reseta** regras existentes se firewall já ativo
- ✅ Adiciona apenas regras necessárias
- ✅ Mantém regras de outros projetos
- ✅ Portas HTTP/HTTPS compartilhadas (padrão)

**Proteção:**

```bash
# Verifica se UFW já está ativo
if ufw status | grep -q "Status: active"; then
    # Adiciona APENAS regras necessárias
    ufw allow 80/tcp   # Se não existir
    ufw allow 443/tcp  # Se não existir
    # NÃO reseta regras existentes
else
    # Configuração inicial apenas se não houver firewall
fi
```

---

### 8. **Banco de Dados Isolado**

- ✅ SQLite em arquivo específico: `/opt/novusio/database.sqlite`
- ✅ **NÃO compartilha** banco com outros projetos
- ✅ **NÃO afeta** bancos PostgreSQL/MySQL de outros projetos
- ✅ Backup isolado em `/opt/backups/novusio/`

---

### 9. **Uploads Isolados**

- ✅ Diretório específico: `/opt/novusio/uploads/`
- ✅ **NÃO acessa** arquivos de outros projetos
- ✅ Permissões restritas ao usuário do projeto
- ✅ Nginx serve apenas este diretório específico

---

### 10. **Logs Isolados**

- ✅ Logs específicos em `/var/log/novusio/`
- ✅ **NÃO mistura** com logs de outros projetos
- ✅ Rotação independente
- ✅ Backup isolado

---

## 📋 Checklist de Validações

Antes de qualquer operação, o script verifica:

- [ ] **Diretório existe e não está vazio?**
- [ ] **Porta já está em uso?**
- [ ] **Usuário já existe?**
- [ ] **Domínio já tem configuração Nginx?**
- [ ] **Firewall já está ativo?**
- [ ] **Outros sites estão configurados?**

**Todas as validações solicitam confirmação do usuário!**

---

## 🔄 Operações Seguras

### Deploy Completo

✅ Verifica conflitos antes de instalar
✅ Solicita confirmação se houver conflitos
✅ Não sobrescreve sem permissão

### Atualização

✅ Afeta APENAS o projeto Novusio
✅ Backup antes de atualizar
✅ Não toca em outros projetos

### Remoção

✅ Remove APENAS arquivos do Novusio
✅ Não remove configurações compartilhadas (Nginx default, etc)
✅ Solicita confirmação para cada etapa crítica
✅ Mantém certificados de outros domínios

---

## 🚀 Exemplos de Coexistência

### Exemplo 1: Múltiplos Projetos Node.js

```
Servidor:
├── /opt/novusio/           → Porta 3000 (Novusio)
├── /opt/outro-projeto/     → Porta 3001 (Outro projeto)
└── /var/www/blog/          → Porta 3002 (Blog)

PM2:
├── novusio-server   → online (porta 3000)
├── outro-projeto    → online (porta 3001)
└── blog             → online (porta 3002)

Nginx:
├── novusio.com      → proxy para :3000
├── outro.com        → proxy para :3001
└── blog.com         → proxy para :3002
```

### Exemplo 2: Projetos em Diferentes Tecnologias

```
Servidor:
├── /opt/novusio/           → Node.js + React
├── /var/www/wordpress/     → PHP (Apache/Nginx)
└── /home/user/python-app/  → Python (Flask)

Firewall:
├── 22   → SSH (compartilhado)
├── 80   → HTTP (compartilhado)
├── 443  → HTTPS (compartilhado)
├── 3000 → Novusio
├── 8000 → Python app
└── 9000 → Outro serviço
```

---

## ⚠️ O Que o Script NÃO Faz

❌ **NÃO** reseta configurações globais
❌ **NÃO** remove arquivos de outros projetos
❌ **NÃO** modifica configurações de outros domínios
❌ **NÃO** interfere com outros usuários do sistema
❌ **NÃO** altera bancos de dados de outros projetos
❌ **NÃO** remove certificados SSL de outros domínios
❌ **NÃO** para outras aplicações PM2
❌ **NÃO** reseta firewall se já houver regras
❌ **NÃO** sobrescreve configurações sem permissão

---

## ✅ O Que o Script FAZ

✅ **Instala** em diretório isolado
✅ **Verifica** conflitos antes de qualquer operação
✅ **Solicita** confirmação em caso de conflito
✅ **Adiciona** apenas regras necessárias
✅ **Mantém** configurações existentes
✅ **Isola** completamente o projeto Novusio
✅ **Protege** outros projetos no servidor

---

## 🔍 Como Verificar o Isolamento

Após o deploy, você pode verificar que nada foi afetado:

```bash
# Verificar sites Nginx
ls -la /etc/nginx/sites-enabled/
# Deve mostrar todos os sites, incluindo o novo

# Verificar aplicações PM2
pm2 list
# Deve mostrar todas as aplicações rodando

# Verificar portas em uso
netstat -tuln | grep LISTEN
# Cada aplicação em sua porta

# Verificar certificados SSL
certbot certificates
# Todos os certificados listados

# Verificar regras do firewall
ufw status
# Todas as regras preservadas
```

---

## 🆘 Suporte

Se você encontrar algum conflito ou problema:

1. **O script sempre solicita confirmação** antes de qualquer operação crítica
2. **Escolha "N" (Não)** se não tiver certeza
3. **Configure diretório, porta ou domínio diferente**
4. **Todos os projetos existentes permanecerão intactos**

---

## 📞 Garantia

**100% de isolamento garantido!** O projeto Novusio não interfere em:

- ✅ Outros sites e domínios
- ✅ Outras aplicações Node.js
- ✅ Bancos de dados existentes
- ✅ Certificados SSL de outros domínios
- ✅ Configurações de firewall existentes
- ✅ Usuários e permissões de outros projetos
- ✅ Arquivos e diretórios de outros projetos

**Qualquer operação que possa afetar outros projetos solicita confirmação explícita!**
