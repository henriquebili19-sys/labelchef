# Deploy na Railway (caminho recomendado para começar)

Coloca o **LabelChef** no ar em `labelchef.com.br`, com subdomínio por empresa
(`admin.labelchef.com.br`, `restaurante1.labelchef.com.br`…) e HTTPS, **sem VPS e sem Vercel**.

## Como fica

Um único serviço na Railway roda o `Dockerfile` da raiz do projeto, que contém tudo:

- a API e o WebSocket do Agente de Impressão (Fastify);
- o site (build do Vite), entregue pelo próprio backend;
- o PostgreSQL (serviço da Railway) e um **volume** para os logos enviados.

Como o site e a API ficam no mesmo endereço, o login por cookie funciona sem configuração extra de CORS.

### Por que não Vercel (nem Vercel + Railway)

- A Vercel aceita subdomínio curinga, mas só com os nameservers do domínio apontados para ela, e o plano
  gratuito (Hobby) é restrito a uso **não comercial** — um SaaS pago exigiria o plano Pro.
- O backend não pode rodar na Vercel (funções serverless não mantêm o WebSocket do Agente de Impressão
  nem gravam arquivos em disco), então precisaria de Railway de qualquer forma. Dividir em dois serviços só
  adiciona custo e complexidade.

Custo estimado na Railway: plano Hobby (US$ 5/mês) + uso (banco, volume e tráfego). Confira os valores atuais em
[railway.com/pricing](https://railway.com/pricing).

---

## Passo 1 — Colocar o código no GitHub

A Railway faz o deploy a partir de um repositório. Crie um repositório **privado** no GitHub e, na pasta do projeto:

```bash
git init
git add .
git commit -m "LabelChef"
git branch -M main
git remote add origin https://github.com/SEU-USUARIO/labelchef.git
git push -u origin main
```

O `.gitignore` já impede o envio de `.env`, `node_modules`, `uploads/` e do `config.json` do agente.
Antes do primeiro `git push`, confira com `git status` que nenhum arquivo com senha foi incluído.

## Passo 2 — Criar o projeto na Railway

1. Crie a conta em [railway.com](https://railway.com) e assine o plano Hobby.
2. **New Project → Deploy from GitHub repo** e escolha o repositório. A Railway lê o `railway.json`
   e usa o `Dockerfile` da raiz.
3. No mesmo projeto: **New → Database → Add PostgreSQL**.

## Passo 3 — Volume para os logos

No serviço do app: **Settings → Volumes → New Volume**, com *mount path* `/data`.
(A imagem já usa `UPLOADS_DIR=/data/uploads`; sem o volume os logos somem a cada novo deploy.)

## Passo 4 — Variáveis do serviço

No serviço do app, aba **Variables**:

| Variável | Valor |
|---|---|
| `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` (referência ao banco; ajuste o nome se o serviço do banco tiver outro nome) |
| `JWT_SECRET` | uma string aleatória longa (veja abaixo como gerar) |
| `BASE_DOMAIN` | `labelchef.com.br` |
| `PUBLIC_URL` | `https://labelchef.com.br` |
| `ADMIN_EMAIL` | o e-mail do dono do sistema (super admin) |
| `ADMIN_PASSWORD` | senha forte, **mínimo 10 caracteres** |
| `SMTP_HOST`, `SMTP_PORT`, `SMTP_SECURE`, `SMTP_USER`, `SMTP_PASS`, `SMTP_FROM` | dados do provedor de e-mail (ex: Brevo). Sem isso, os alertas por e-mail não chegam de verdade |

Gerar o `JWT_SECRET` no PowerShell:

```powershell
-join ((48..57)+(65..90)+(97..122) | Get-Random -Count 48 | ForEach-Object {[char]$_})
```

A porta é definida pela própria Railway (variável `PORT`). No primeiro start o sistema aplica as migrações do
banco e **cria o super admin** com `ADMIN_EMAIL`/`ADMIN_PASSWORD` (só se ainda não existir nenhum).
Depois de entrar pela primeira vez, você pode apagar `ADMIN_PASSWORD` das variáveis.

## Passo 5 — Domínio e DNS

No serviço: **Settings → Networking → Custom Domain**. Adicione **dois** domínios:

- `labelchef.com.br`
- `*.labelchef.com.br` (curinga: cobre `admin.`, `www.` e cada empresa)

A Railway mostra os registros DNS a criar (CNAME e, no curinga, um registro TXT de verificação).
**Crie exatamente o que ela mostrar.** Pontos de atenção:

- O Registro.br não permite CNAME no domínio raiz (`labelchef.com.br`). Use o DNS da **Cloudflare**
  (gratuito, com *CNAME flattening*): crie a conta, adicione o domínio e troque os nameservers no Registro.br
  pelos da Cloudflare.
- Na Cloudflare, deixe esses registros como **"Somente DNS"** (nuvem cinza). Com o proxy laranja ligado, a
  Railway não consegue emitir os certificados.
- O plano Hobby tem limite de 2 domínios personalizados por serviço — `labelchef.com.br` + `*.labelchef.com.br`
  usam exatamente os 2.
- A propagação do DNS e a emissão do certificado podem levar de minutos a algumas horas.

## Passo 6 — Primeiro acesso

1. Abra `https://admin.labelchef.com.br` e entre com `ADMIN_EMAIL` / `ADMIN_PASSWORD`.
2. Crie os **planos** e a primeira **empresa** (o subdomínio vira `https://<subdominio>.labelchef.com.br`).
3. Em cada empresa, crie o usuário administrador.

## Passo 7 — Agente de Impressão nas empresas

Em cada empresa, o administrador abre **Agente de Impressão** no sistema e usa o endereço e o token mostrados
lá (em produção o endereço é `wss://labelchef.com.br/ws/agente`). O guia está em
[print-agent/README.md](../print-agent/README.md).

## Atualizando o sistema

```bash
git add .
git commit -m "descrição da mudança"
git push
```

A Railway detecta o push e faz o deploy sozinha. As migrações do banco rodam no início de cada deploy.

## Backups

Confira no painel da Railway quais opções de backup do PostgreSQL o seu plano inclui e **não dependa só disso**:
programe um `pg_dump` periódico (por exemplo semanal) e guarde o arquivo fora da Railway. Os logos ficam no
volume, que também deve ser considerado nos backups.

## Limitações conhecidas

- O Agente de Impressão conecta no processo do servidor: mantenha **uma única instância** do serviço
  (não escale horizontalmente sem antes trocar o registro de agentes em memória por algo compartilhado, como Redis).
- A Railway derruba conexões ociosas após cerca de 60 s; o servidor envia um *ping* a cada 25 s para manter o
  agente conectado.
- Este deploy foi preparado e validado **sem Docker** (não há Docker na máquina de desenvolvimento): os mesmos
  passos do `Dockerfile` (build do site e do backend, `prisma migrate deploy` em banco vazio, servidor em modo
  produção) foram executados e testados à mão. O primeiro build real na Railway pode exigir pequenos ajustes.
- Quando o sistema crescer, o caminho de VPS com Docker Compose continua disponível em [DEPLOY.md](DEPLOY.md).
