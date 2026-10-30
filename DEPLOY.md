# Guia de Deploy em Produção (VPS + Docker Compose)

> **Para começar, use o guia da Railway: [DEPLOY-RAILWAY.md](DEPLOY-RAILWAY.md)** — sem servidor próprio e
> com menos passos. Este guia de VPS fica para quando o sistema crescer.

Este guia coloca o sistema no ar com domínio próprio, subdomínio curinga por empresa
(`empresa1.labelchef.com.br`, `admin.labelchef.com.br`) e HTTPS, usando um VPS + Docker.

**Domínio:** `labelchef.com.br` — já registrado. ✅
**VPS:** ainda falta contratar (Passo 2).

## Visão geral da arquitetura escolhida

- **VPS** (um servidor próprio) rodando Docker Compose: PostgreSQL + backend + Nginx.
- **Cloudflare** como DNS (grátis) — escolhido porque emite um "Certificado de Origem"
  gratuito que já cobre `*.labelchef.com.br`, sem precisar renovar certificado toda hora
  (dura 15 anos) e sem precisar configurar Certbot.
- **Nginx** no próprio servidor recebe todo o tráfego HTTPS, decide pelo subdomínio e
  encaminha para o backend (API e WebSocket do Agente de Impressão) ou serve o frontend.

Por que um VPS: controle total e custo previsível quando houver muitas empresas. Para começar,
a Railway (guia acima) atende subdomínio curinga e WebSocket com bem menos trabalho. A Vercel não serve para o
backend (sem WebSocket persistente nem disco) e o plano gratuito dela é só para uso não comercial.

## Passo 1 — Domínio ✅ concluído

`labelchef.com.br` já está registrado.

## Passo 2 — VPS (próximo passo)

Recomendação: **DigitalOcean** (tem região em São Paulo, ~US$6-12/mês, aceita cartão
internacional) ou **Hostinger VPS** (aceita Pix/boleto, bom custo-benefício no Brasil).
Especificação mínima: 1 vCPU, 2GB RAM, Ubuntu 22.04.

- DigitalOcean: crie a conta em [digitalocean.com](https://www.digitalocean.com), depois
  "Create → Droplet", região São Paulo, imagem Ubuntu 22.04, plano Basic (menor tamanho já serve).
- Hostinger: [hostinger.com.br](https://www.hostinger.com.br) → VPS → plano mais simples,
  imagem Ubuntu 22.04.

Depois de criar o servidor, anote o **IP público** e instale o Docker nele (via SSH):

```bash
curl -fsSL https://get.docker.com | sh
```

## Passo 3 — DNS via Cloudflare

1. Crie uma conta gratuita em [cloudflare.com](https://cloudflare.com) e adicione `labelchef.com.br`.
2. Aponte os **nameservers** do domínio (no Registro.br, em "Alterar servidores DNS") para os
   nameservers que a Cloudflare indicar. Isso pode levar algumas horas para propagar.
3. Na Cloudflare, crie dois registros DNS, ambos com o proxy **ativado** (ícone laranja):
   - Tipo `A`, nome `@`, valor = IP do seu VPS
   - Tipo `A`, nome `*`, valor = IP do seu VPS
4. Em **SSL/TLS**, mude o modo para **Full (strict)**.
5. Em **SSL/TLS → Certificados de origem**, clique em **Criar certificado**, mantenha os
   hostnames sugeridos (`*.labelchef.com.br`, `labelchef.com.br`) e copie os dois blocos
   gerados (certificado e chave privada) — você vai precisar deles no Passo 5.

## Passo 4 — Levar o código para o servidor

No seu VPS:

```bash
git clone <url-do-seu-repositorio> etiquetas
cd etiquetas
```

(Se ainda não tiver o código em um repositório Git, envie a pasta do projeto via `scp` ou
`rsync` para o servidor.)

## Passo 5 — Configurar senhas e certificado

O domínio já está preenchido em `deploy/nginx.conf` e em `.env.production.example`. Falta só:

```bash
cp .env.production.example .env
nano .env   # preencha POSTGRES_PASSWORD e JWT_SECRET (uma string aleatória longa)

mkdir -p deploy/certs
nano deploy/certs/origin.pem   # cole o certificado gerado na Cloudflare
nano deploy/certs/origin.key   # cole a chave privada gerada na Cloudflare
```

## Passo 6 — Subir os containers

```bash
docker compose -f docker-compose.prod.yml up -d --build
```

Isso builda o backend e o frontend, sobe o PostgreSQL, roda as migrações do banco
automaticamente (`prisma migrate deploy`, já embutido no início do container do backend) e
liga o Nginx nas portas 80 e 443.

## Passo 7 — Criar o super admin

```bash
docker compose -f docker-compose.prod.yml exec backend npx tsx prisma/seed.ts
```

Esse comando cria o super admin com a senha **padrão de desenvolvimento (`admin123`)** — não use em produção.
Prefira definir `ADMIN_EMAIL` e `ADMIN_PASSWORD` (mín. 10 caracteres) no `.env` **antes** do primeiro `up`:
o sistema cria o super admin sozinho no primeiro start, com a sua senha.

## Passo 8 — Testar

- `https://admin.labelchef.com.br` → painel do dono do sistema, cria as empresas.
- `https://<subdominio-da-empresa>.labelchef.com.br` → sistema da empresa.
- Instale o [Agente de Impressão](../print-agent/README.md) no computador da cozinha usando
  a URL `wss://labelchef.com.br/ws/agente` e o token mostrados no painel da empresa em
  "Agente de Impressão".

## Backup do banco de dados

Configure um cron simples no VPS para backups diários:

```bash
0 3 * * * docker compose -f /caminho/etiquetas/docker-compose.prod.yml exec -T postgres pg_dump -U etiquetas etiquetas > /root/backups/etiquetas-$(date +\%F).sql
```

## Atualizando o sistema depois de mudanças no código

```bash
git pull
docker compose -f docker-compose.prod.yml up -d --build
```

## Depois do site no ar: gerar o APK Android

Com o sistema publicado em `https://*.labelchef.com.br`, dá para gerar um APK Android que
abre o sistema em tela cheia (sem barra de navegador), apontando para esse endereço
definitivo. Avise quando o deploy estiver pronto que eu preparo isso.

## Limitações desta primeira versão de produção

- Sem renovação automática de certificado necessária (o Certificado de Origem da Cloudflare
  dura 15 anos), mas se você trocar de provedor de DNS no futuro, vai precisar de outra
  estratégia de SSL (ex: Certbot com desafio DNS-01).
- Sem monitoramento/alertas configurados — considere um serviço simples de uptime (ex:
  UptimeRobot, gratuito) apontando para `https://admin.labelchef.com.br`.
