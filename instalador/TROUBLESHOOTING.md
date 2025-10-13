# 🔧 Troubleshooting - Novusio

## Problemas Comuns e Soluções

---

## ❌ Erro: "cannot execute: required file not found"

### Problema
```bash
root@servidor:~/instalador# ./deploy.sh
-bash: ./deploy.sh: cannot execute: required file not found
```

### Causa
Este erro ocorre por:
1. **Formato de linha incorreto** (Windows CRLF vs Unix LF)
2. **Falta de permissão de execução**
3. **Shebang incorreto** (primeira linha do script)

### Solução 1: Use o Script Corretor (RECOMENDADO)
```bash
cd instalador
bash fix-scripts.sh
```

**Saída esperada:**
```
🔧 Corrigindo scripts do Novusio...
==================================
📝 Convertendo formato de linha...
  ✓ backup.sh
  ✓ deploy.sh
  ✓ monitor.sh
  ✓ novusio-cli.sh
  ✓ quick-deploy.sh
  ✓ regenerate-secrets.sh

🔐 Configurando permissões...
  ✓ [todos os scripts]

✅ Scripts corrigidos com sucesso!
```

**Agora execute novamente:**
```bash
sudo ./deploy.sh
```

### Solução 2: Corrigir Manualmente

#### A. Instalar dos2unix
```bash
# Ubuntu/Debian
apt-get update
apt-get install -y dos2unix

# Converter todos os scripts
cd instalador
dos2unix *.sh
```

#### B. Usar sed (se dos2unix não disponível)
```bash
cd instalador
for file in *.sh; do
    sed -i 's/\r$//' "$file"
done
```

#### C. Dar permissão de execução
```bash
chmod +x *.sh
```

### Solução 3: Executar com bash diretamente
```bash
# Em vez de ./deploy.sh
bash deploy.sh

# Ou
sh deploy.sh
```

---

## ❌ Erro: Permission Denied

### Problema
```bash
-bash: ./deploy.sh: Permission denied
```

### Solução
```bash
# Dar permissão de execução
chmod +x deploy.sh

# Ou executar com sudo
sudo bash deploy.sh
```

---

## ❌ Erro: No such file or directory

### Problema
```bash
-bash: ./deploy.sh: No such file or directory
```

### Causa
Você não está no diretório correto

### Solução
```bash
# Verificar onde você está
pwd

# Ir para o diretório correto
cd /caminho/para/site-novusio-html/instalador

# Ou
cd ~/site-novusio-html/instalador

# Listar arquivos
ls -la
```

---

## ❌ Erro: DNS não aponta para o servidor

### Problema
```bash
⚠️ ATENÇÃO: O domínio seu-dominio.com não aponta para este servidor
```

### Solução

#### 1. Verificar IP do servidor
```bash
curl ifconfig.me
# Exemplo: 192.168.1.100
```

#### 2. Verificar DNS do domínio
```bash
dig seu-dominio.com +short
# Ou
nslookup seu-dominio.com
```

#### 3. Configurar DNS
No painel do seu provedor de domínio (GoDaddy, Namecheap, etc):
- **Tipo**: A
- **Nome**: @ (ou seu-dominio.com)
- **Valor**: IP do servidor (ex: 192.168.1.100)
- **TTL**: 3600

#### 4. Aguardar propagação
```bash
# DNS pode levar de 5 minutos a 48 horas para propagar
# Normalmente leva 15-30 minutos

# Verificar propagação
watch -n 10 'dig seu-dominio.com +short'
```

#### 5. Continuar mesmo assim
Se quiser continuar sem DNS configurado:
- Digite `Y` quando perguntado
- Configure DNS depois
- Execute `sudo ./deploy.sh` novamente para obter SSL

---

## ❌ Erro: Porta já está em uso

### Problema
```bash
⚠️ A porta 3000 já está em uso por outro processo!
```

### Solução 1: Ver o que está usando a porta
```bash
# Ver processo na porta 3000
netstat -tuln | grep :3000
# Ou
lsof -i :3000
# Ou
ss -tuln | grep :3000
```

### Solução 2: Matar o processo
```bash
# Encontrar PID
lsof -i :3000
# kill PID

# Ou matar diretamente
fuser -k 3000/tcp
```

### Solução 3: Escolher outra porta
Durante o deploy, quando perguntado:
```bash
🔧 Porta da aplicação [3000]: 3001
```

---

## ❌ Erro: Node.js não instalado

### Problema
```bash
Command 'node' not found
```

### Solução
```bash
# Instalar Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Verificar instalação
node --version
npm --version
```

---

## ❌ Erro: Nginx test failed

### Problema
```bash
nginx: configuration file /etc/nginx/nginx.conf test failed
```

### Solução
```bash
# Ver detalhes do erro
nginx -t

# Verificar sintaxe do arquivo
cat /etc/nginx/sites-available/seu-dominio.com

# Remover configuração com problema
rm /etc/nginx/sites-enabled/seu-dominio.com

# Executar deploy novamente
sudo ./deploy.sh
```

---

## ❌ Erro: Cannot connect to database

### Problema
```bash
Error: SQLITE_CANTOPEN: unable to open database file
```

### Solução
```bash
# Verificar permissões
ls -la /opt/novusio/database.sqlite

# Corrigir permissões
chown novusio:novusio /opt/novusio/database.sqlite
chmod 644 /opt/novusio/database.sqlite

# Recriar banco se necessário
cd /opt/novusio
npm run init-db
```

---

## ❌ Erro: PM2 not found

### Problema
```bash
Command 'pm2' not found
```

### Solução
```bash
# Instalar PM2 globalmente
npm install -g pm2

# Verificar instalação
pm2 --version
```

---

## ❌ Erro: SSL Certificate not found

### Problema
```bash
❌ Certificado SSL não encontrado
```

### Solução
```bash
# Instalar Certbot
apt-get install -y certbot python3-certbot-nginx

# Obter certificado
certbot --nginx -d seu-dominio.com -d www.seu-dominio.com \
    --non-interactive --agree-tos --email seu-email@gmail.com

# Verificar certificado
certbot certificates
```

---

## ❌ Erro: Build failed

### Problema
```bash
npm ERR! code ELIFECYCLE
npm ERR! errno 1
```

### Solução
```bash
# Limpar cache
cd /opt/novusio
rm -rf node_modules package-lock.json
cd client
rm -rf node_modules package-lock.json

# Reinstalar
cd /opt/novusio
npm install
cd client
npm install

# Build novamente
npm run build
```

---

## ❌ Erro: Out of memory

### Problema
```bash
FATAL ERROR: Ineffective mark-compacts near heap limit
```

### Solução
```bash
# Aumentar limite de memória
export NODE_OPTIONS="--max-old-space-size=4096"

# Build novamente
npm run build
```

---

## ❌ Erro: Git clone failed

### Problema
```bash
fatal: could not read Username for 'https://github.com'
```

### Solução 1: Usar HTTPS com token
```bash
git clone https://TOKEN@github.com/usuario/repo.git
```

### Solução 2: Usar SSH
```bash
# Gerar chave SSH
ssh-keygen -t ed25519 -C "seu-email@gmail.com"

# Copiar chave pública
cat ~/.ssh/id_ed25519.pub

# Adicionar no GitHub (Settings → SSH Keys)

# Clonar com SSH
git clone git@github.com:usuario/repo.git
```

### Solução 3: Repositório público
```bash
# Se o repositório for público, não precisa autenticação
git clone https://github.com/usuario/repo.git
```

---

## 🔍 Comandos de Diagnóstico

### Status Geral
```bash
# Status da aplicação
sudo -u novusio pm2 status

# Status Nginx
systemctl status nginx

# Status Firewall
ufw status

# Portas em uso
netstat -tuln | grep LISTEN

# Processos Node
ps aux | grep node

# Espaço em disco
df -h

# Memória
free -h
```

### Logs
```bash
# Logs da aplicação
sudo -u novusio pm2 logs

# Logs Nginx
tail -f /var/log/nginx/error.log
tail -f /var/log/nginx/access.log

# Logs do sistema
journalctl -u nginx -f
journalctl -xe
```

### Testes
```bash
# Testar Nginx
nginx -t

# Testar conectividade
curl -I http://localhost:3000
curl -I https://seu-dominio.com

# Testar DNS
dig seu-dominio.com
nslookup seu-dominio.com

# Testar SSL
openssl s_client -connect seu-dominio.com:443
```

---

## 📞 Se Nada Funcionar

### 1. Reset Completo
```bash
# Remover instalação
sudo ./deploy.sh
# Escolha opção 3 (Remover Projeto)

# Instalar novamente
sudo ./deploy.sh
# Escolha opção 1 (Deploy Completo)
```

### 2. Verificar Requisitos
```bash
# Sistema operacional
lsb_release -a

# Versão do kernel
uname -r

# Espaço em disco
df -h

# Memória RAM
free -h

# Arquitetura
uname -m
```

### 3. Executar com Debug
```bash
# Modo debug
bash -x deploy.sh 2>&1 | tee deploy-debug.log

# Enviar log para análise
cat deploy-debug.log
```

---

## ✅ Checklist de Verificação

Antes de pedir ajuda, verifique:

- [ ] Todos os scripts têm permissão de execução (`chmod +x`)
- [ ] Scripts têm formato Unix LF (não Windows CRLF)
- [ ] DNS aponta para o servidor
- [ ] Porta escolhida não está em uso
- [ ] Servidor tem pelo menos 1GB RAM
- [ ] Servidor tem pelo menos 10GB disco livre
- [ ] Node.js 18+ instalado
- [ ] Nginx instalado e funcionando
- [ ] Firewall permite portas 22, 80, 443
- [ ] Root ou sudo disponível

---

## 🆘 Obter Ajuda

Se ainda tiver problemas:

1. **Execute o corretor**:
   ```bash
   bash fix-scripts.sh
   ```

2. **Colete informações**:
   ```bash
   # Informações do sistema
   uname -a
   lsb_release -a
   node --version
   npm --version
   
   # Status dos serviços
   systemctl status nginx
   pm2 status
   
   # Logs recentes
   tail -100 /var/log/novusio/error.log
   ```

3. **Use o troubleshooter automático**:
   ```bash
   sudo ./novusio-cli.sh info
   sudo ./novusio-cli.sh monitor
   ```

---

**🎯 Na maioria dos casos, o `fix-scripts.sh` resolve o problema!**
