# 🚀 Instruções de Deploy - Site Novusio

## 📋 Pré-requisitos

Antes de começar, certifique-se de que:

- ✅ Você tem acesso SSH ao servidor Ubuntu
- ✅ O domínio está apontando para o IP do servidor
- ✅ Você tem a URL do repositório Git do projeto
- ✅ Você tem um email válido para os certificados SSL

## 🚀 Instalação Passo a Passo

### 1. Conectar ao Servidor

```bash
ssh usuario@seu-servidor.com
```

### 2. Clonar o Projeto

```bash
git clone https://github.com/seu-usuario/site-novusio-html.git
cd site-novusio-html/instalador
```

### 3. Preparar Scripts

```bash
chmod +x *.sh
```

### 4. Executar Deploy

```bash
./deploy.sh
```

O script irá solicitar:
- 🌐 **Domínio**: `exemplo.com`
- 👤 **Usuário Linux**: `ubuntu` (ou seu usuário)
- 🔗 **URL Git**: `https://github.com/usuario/repositorio.git`
- 🔌 **Porta**: `3000` (padrão)
- 📧 **Email SSL**: `suporte@novusiopy.com` (padrão)

### 5. Aguardar Instalação

O processo levará alguns minutos e incluirá:
- ✅ Instalação de dependências
- ✅ Clonagem do projeto
- ✅ Configuração do banco de dados
- ✅ Build do projeto React
- ✅ Configuração do Nginx
- ✅ Configuração SSL
- ✅ Configuração do firewall
- ✅ Inicialização dos serviços

## 🎛️ Gerenciamento

### Menu Principal

```bash
./menu.sh
```

Opções disponíveis:
1. **Instalar Projeto** - Nova instalação
2. **Atualizar Projeto** - Atualizar código
3. **Ver Status** - Status do sistema
4. **Gerenciar Logs** - Visualizar logs
5. **Backup** - Fazer backup
6. **Restaurar** - Restaurar backup
7. **Remover** - Remover projeto

### Comandos Úteis

```bash
# Status do serviço
sudo systemctl status novusio

# Reiniciar serviço
sudo systemctl restart novusio

# Ver logs
sudo journalctl -u novusio -f

# Verificar sistema
./verificar-sistema.sh

# Backup manual
./backup.sh
```

## 🔧 Configurações

### Arquivo .env

Localizado em: `/home/usuario/site-novusio/.env`

```env
NODE_ENV=production
PORT=3000
JWT_SECRET=seu_secret_jwt
ADMIN_EMAIL=admin@seu-dominio.com
ADMIN_PASSWORD=senha_gerada_automaticamente
DOMAIN=seu-dominio.com
```

### Credenciais de Acesso

Após a instalação, você receberá:
- 📧 **Email**: `admin@seu-dominio.com`
- 🔑 **Senha**: Gerada automaticamente

⚠️ **IMPORTANTE**: Altere essas credenciais após o primeiro login!

## 🌐 Acessos

Após a instalação, você pode acessar:

- **Site Principal**: `https://seu-dominio.com`
- **Painel Admin**: `https://seu-dominio.com/admin`
- **API**: `https://seu-dominio.com/api`

## 🔒 Segurança

O sistema inclui:

- ✅ Firewall UFW configurado
- ✅ Fail2ban para proteção SSH
- ✅ SSL/TLS com Let's Encrypt
- ✅ Senhas seguras geradas automaticamente
- ✅ Logs de monitoramento

## 💾 Backup

### Backup Automático

```bash
# Backup manual
./backup.sh

# Backup com retenção personalizada
./backup.sh --retention 7
```

### Restaurar Backup

```bash
./menu.sh
# Escolher opção 6: Restaurar Backup
```

## 🔄 Atualizações

### Atualizar Código

```bash
./menu.sh
# Escolher opção 2: Atualizar Projeto
```

### Atualizar Sistema

```bash
sudo apt update && sudo apt upgrade
```

## 🛠️ Solução de Problemas

### Serviço não inicia

```bash
# Verificar status
sudo systemctl status novusio

# Verificar logs
sudo journalctl -u novusio -n 50

# Reiniciar
sudo systemctl restart novusio
```

### Nginx com problemas

```bash
# Verificar configuração
sudo nginx -t

# Recarregar
sudo systemctl reload nginx
```

### SSL não funciona

```bash
# Verificar certificados
sudo certbot certificates

# Renovar
sudo certbot renew
```

### Banco de dados

```bash
# Verificar arquivo
ls -la /home/usuario/site-novusio/database.sqlite

# Reinicializar
cd /home/usuario/site-novusio
npm run init-db
```

## 📊 Monitoramento

### Verificação Completa

```bash
./verificar-sistema.sh
```

### Logs Importantes

```bash
# Logs da aplicação
sudo journalctl -u novusio -f

# Logs do Nginx
sudo tail -f /var/log/nginx/novusio_error.log

# Logs do sistema
sudo tail -f /var/log/syslog
```

## 📞 Suporte

### Informações do Sistema

```bash
# Status completo
sudo systemctl status novusio nginx fail2ban

# Verificação detalhada
./verificar-sistema.sh > sistema.log
```

### Logs para Suporte

```bash
# Coletar logs
sudo journalctl -u novusio --since "1 hour ago" > logs_servico.txt
sudo tail -100 /var/log/nginx/novusio_error.log > logs_nginx.txt
./verificar-sistema.sh > status_sistema.txt
```

## ✅ Checklist Pós-Instalação

- [ ] Site acessível via HTTPS
- [ ] Painel admin funcionando
- [ ] API respondendo
- [ ] SSL configurado corretamente
- [ ] Firewall ativo
- [ ] Backup funcionando
- [ ] Logs sendo gerados
- [ ] Credenciais alteradas

## 🎉 Concluído!

Seu site está rodando em produção com:

- ✅ Instalação automatizada
- ✅ SSL/TLS configurado
- ✅ Firewall e segurança
- ✅ Backup automático
- ✅ Monitoramento
- ✅ Documentação completa

**Acesse seu site**: `https://seu-dominio.com`

---

**Desenvolvido com ❤️ para Novusio Paraguay**
