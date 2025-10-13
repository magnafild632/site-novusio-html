# 🔐 Geração Automática de Secrets - Novusio

## Segurança Automática Implementada

O sistema de deploy Novusio agora gera automaticamente **secrets criptográficos seguros** durante a instalação, eliminando a necessidade de configuração manual e aumentando significativamente a segurança.

---

## 🎯 O Que É Gerado Automaticamente

### 1. **JWT_SECRET** (48 bytes)

- **Uso**: Autenticação de usuários via JSON Web Tokens
- **Tamanho**: 48 bytes (384 bits)
- **Algoritmo**: OpenSSL random + base64
- **Exemplo**: `a8K3mN9pQ2rS4tU6vW8xY0zA1bC3dE5fG7hI9jK1lM3nO5pQ7rS9tU1vW3xY5zA7b==`

### 2. **SESSION_SECRET** (32 bytes)

- **Uso**: Sessões de usuário e cookies seguros
- **Tamanho**: 32 bytes (256 bits)
- **Algoritmo**: OpenSSL random + base64
- **Exemplo**: `X1yZ3aB5cD7eF9gH1iJ3kL5mN7oP9qR1sT3uV5wX7y==`

---

## ✨ Quando São Gerados

### Durante Deploy Completo

```bash
sudo ./deploy.sh
# Opção: 1. Deploy Completo

🔐 Gerando secrets de segurança...
✓ JWT Secret gerado: a8K3mN9pQ2... (48 bytes)
✓ Session Secret gerado: X1yZ3aB5cD... (32 bytes)
```

### Durante Atualização (se .env não existir)

```bash
sudo ./deploy.sh
# Opção: 2. Atualizar Aplicação

⚠️ Arquivo .env não encontrado, gerando novo...
✓ JWT Secret gerado: b9L4nO0qP3...
✓ Session Secret gerado: Y2zA4bC6dE...
```

### Manualmente (quando necessário)

```bash
sudo ./regenerate-secrets.sh

🔐 Regenerar Secrets de Segurança - Novusio
⚠️ ATENÇÃO: Esta ação irá gerar novos secrets!
```

---

## 🔒 Características de Segurança

### Força Criptográfica

- ✅ **Entropia alta**: 384 bits (JWT) e 256 bits (Session)
- ✅ **Gerador seguro**: OpenSSL CSPRNG (Cryptographically Secure PRNG)
- ✅ **Aleatoriedade**: Impossível de prever ou reproduzir
- ✅ **Único por instalação**: Cada deploy tem secrets diferentes

### Proteção dos Secrets

- ✅ **Arquivo .env**: Permissões 600 (somente dono lê/escreve)
- ✅ **Proprietário**: Usuário dedicado (`novusio`)
- ✅ **Backup seguro**: Arquivo com permissão 400 (somente leitura)
- ✅ **Não versionado**: .env incluído em .gitignore

---

## 📋 Formato do Arquivo .env Gerado

```env
# =============================================================================
# CONFIGURAÇÕES DE PRODUÇÃO - NOVUSIO
# =============================================================================
# Arquivo gerado automaticamente em: 2024-10-12 20:30:45
# =============================================================================

# =============================================================================
# CONFIGURAÇÕES DE AUTENTICAÇÃO
# =============================================================================
# JWT Secret - Gerado automaticamente (NÃO compartilhe!)
JWT_SECRET=a8K3mN9pQ2rS4tU6vW8xY0zA1bC3dE5fG7hI9jK1lM3nO5pQ7rS9tU1vW3xY5zA7b==
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d

# Bcrypt salt rounds
BCRYPT_ROUNDS=12

# Session Secret - Gerado automaticamente
SESSION_SECRET=X1yZ3aB5cD7eF9gH1iJ3kL5mN7oP9qR1sT3uV5wX7y==
SESSION_COOKIE_SECURE=true
SESSION_COOKIE_HTTP_ONLY=true
SESSION_COOKIE_SAME_SITE=strict

# ... outras configurações ...
```

---

## 💾 Backup Automático dos Secrets

### Arquivo de Backup

Após cada geração, um arquivo de backup é criado:

```
/opt/novusio/.secrets-backup-20241012_203045.txt
```

**Conteúdo:**

```
# BACKUP DE SECRETS - NOVUSIO
# Gerado em: 2024-10-12 20:30:45
# IMPORTANTE: Guarde este arquivo em local seguro e delete do servidor!

JWT_SECRET=a8K3mN9pQ2rS4tU6vW8xY0zA1bC3dE5fG7hI9jK1lM3nO5pQ7rS9tU1vW3xY5zA7b==
SESSION_SECRET=X1yZ3aB5cD7eF9gH1iJ3kL5mN7oP9qR1sT3uV5wX7y==

# Para usar estes secrets novamente, adicione-os ao arquivo .env
```

### Proteção do Backup

- **Permissões**: 400 (somente leitura pelo dono)
- **Proprietário**: Usuário `novusio`
- **Localização**: Dentro do diretório do projeto
- **Ação recomendada**: Salve em local seguro e delete do servidor

---

## 🔄 Regenerar Secrets

### Quando Regenerar?

1. **Comprometimento**: Se suspeitar que os secrets foram expostos
2. **Rotação regular**: Por política de segurança (ex: a cada 90 dias)
3. **Auditoria**: Após auditoria de segurança
4. **Mudança de equipe**: Quando membros da equipe saem

### Como Regenerar

```bash
# Opção 1: Script dedicado
cd /opt/novusio/instalador
sudo ./regenerate-secrets.sh

# Opção 2: Manual
cd /opt/novusio
sudo rm .env
sudo ./instalador/deploy.sh
# Escolha opção 2 (Atualizar Aplicação)
```

### O Que Acontece?

1. ✅ **Backup do .env atual** → `.env.backup-YYYYMMDD_HHMMSS`
2. ✅ **Geração de novos secrets** → JWT_SECRET e SESSION_SECRET
3. ✅ **Atualização do .env** → Secrets substituídos
4. ✅ **Backup dos novos secrets** → `.secrets-regenerated-YYYYMMDD_HHMMSS.txt`
5. ✅ **Restart da aplicação** → PM2 reinicia com novos secrets
6. ⚠️ **Todos os usuários deslogados** → Precisam fazer login novamente

---

## ⚠️ Impacto da Regeneração

### Imediato

- ❌ **Todos os tokens JWT existentes são invalidados**
- ❌ **Todas as sessões ativas são encerradas**
- ❌ **Usuários precisam fazer login novamente**

### Sem Impacto

- ✅ Senhas de usuários permanecem válidas
- ✅ Dados do banco não são afetados
- ✅ Uploads e arquivos permanecem intactos
- ✅ Configurações Nginx/SSL não mudam

---

## 🔍 Verificar Secrets Atuais

### Ver Secrets (somente para debug)

```bash
# CUIDADO: Não compartilhe esta saída!
sudo grep -E "JWT_SECRET|SESSION_SECRET" /opt/novusio/.env
```

### Ver Backups de Secrets

```bash
# Listar backups
ls -la /opt/novusio/.secrets-*

# Ver backup específico
sudo cat /opt/novusio/.secrets-backup-20241012_203045.txt
```

### Deletar Backups (após salvar em local seguro)

```bash
# Deletar todos os backups de secrets
sudo rm /opt/novusio/.secrets-*

# Deletar backup específico
sudo rm /opt/novusio/.secrets-backup-20241012_203045.txt
```

---

## 🛡️ Boas Práticas

### ✅ Faça

1. **Salve os backups** em local seguro (gerenciador de senhas, cofre)
2. **Delete backups do servidor** após salvar
3. **Use permissões corretas** (600 para .env, 400 para backups)
4. **Regenere periodicamente** (ex: trimestralmente)
5. **Monitore acessos** ao arquivo .env

### ❌ Não Faça

1. **Não versione** o arquivo .env (use .env.example)
2. **Não compartilhe** secrets em emails, chat, etc.
3. **Não use secrets fracos** (sempre gere automaticamente)
4. **Não reutilize secrets** entre ambientes (dev, staging, prod)
5. **Não ignore backups** de secrets no servidor

---

## 📊 Comparação de Segurança

| Método                           | Entropia  | Segurança  | Facilidade |
| -------------------------------- | --------- | ---------- | ---------- |
| **Geração automática (Novusio)** | 384 bits  | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Manual com OpenSSL               | 256 bits  | ⭐⭐⭐⭐   | ⭐⭐⭐     |
| Gerador online                   | 128 bits  | ⭐⭐       | ⭐⭐⭐⭐   |
| Senha escolhida                  | < 64 bits | ⭐         | ⭐⭐⭐⭐⭐ |

---

## 🔬 Detalhes Técnicos

### Comando de Geração

```bash
# JWT_SECRET (48 bytes)
openssl rand -base64 48 | tr -d '\n'

# SESSION_SECRET (32 bytes)
openssl rand -base64 32 | tr -d '\n'
```

### Por Que Base64?

- ✅ Seguro para usar em variáveis de ambiente
- ✅ Compatível com todos os sistemas
- ✅ Fácil de copiar/colar
- ✅ Sem caracteres especiais problemáticos

### Por Que 48 e 32 bytes?

- **48 bytes (JWT)**: 384 bits de entropia = 2^384 possibilidades
- **32 bytes (Session)**: 256 bits de entropia = 2^256 possibilidades
- Ambos considerados **criptograficamente seguros** por décadas

---

## 🆘 Problemas Comuns

### 1. "Secret inválido" após atualização

**Causa**: Secrets mudaram, tokens antigos invalidados
**Solução**: Faça login novamente

### 2. "Arquivo .env não encontrado"

**Causa**: .env foi deletado acidentalmente
**Solução**: Execute atualização ou regenere secrets

### 3. "Permissão negada ao ler .env"

**Causa**: Permissões incorretas
**Solução**:

```bash
sudo chown novusio:novusio /opt/novusio/.env
sudo chmod 600 /opt/novusio/.env
```

### 4. "Aplicação não inicia após regenerar"

**Causa**: Erro no formato do secret
**Solução**: Use o backup anterior

```bash
sudo cp /opt/novusio/.env.backup-YYYYMMDD_HHMMSS /opt/novusio/.env
sudo -u novusio pm2 restart novusio-server
```

---

## 📞 Suporte

Se você precisar de ajuda com secrets:

1. **Verifique os logs**: `pm2 logs novusio-server`
2. **Verifique permissões**: `ls -la /opt/novusio/.env`
3. **Use o backup**: Se algo der errado, use o backup anterior
4. **Regenere**: Se necessário, regenere novamente

---

## 🎉 Conclusão

A geração automática de secrets:

✅ **Elimina erro humano** (secrets fracos, reutilizados)
✅ **Aumenta segurança** (entropia máxima, CSPRNG)
✅ **Facilita deploy** (zero configuração manual)
✅ **Fornece backups** (recuperação fácil se necessário)
✅ **É reversível** (backup do .env anterior)

**Seu sistema está protegido com os melhores padrões de segurança! 🔐**
