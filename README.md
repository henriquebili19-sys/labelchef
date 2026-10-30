# Agente de Impressão

Programa que fica rodando no computador da cozinha, conectado ao sistema pela internet, e envia as etiquetas para a impressora térmica na rede local (Zebra, Sato, HPRT, Urovo) via IP e porta (padrão 9100).

## Instalação (recomendada — roda sozinho, sem janela)

1. Copie esta pasta (`print-agent`) para o computador que está na mesma rede da impressora.
2. Copie `config.example.json` para `config.json` e preencha com o endereço do servidor e o token da empresa (disponíveis no painel, em **Agente de Impressão**).
3. Abra o PowerShell nesta pasta e rode uma única vez:

```powershell
./instalar-inicializacao.ps1
```

Isso instala as dependências, compila o agente, inicia ele agora mesmo **sem abrir nenhuma janela**, e deixa configurado para iniciar sozinho, escondido, toda vez que o Windows ligar. Não precisa fazer mais nada — pode até fechar o PowerShell.

Para conferir se está tudo certo, veja o arquivo `agente.log` (criado nesta mesma pasta) ou o painel **Agente de Impressão** do sistema, que mostra "Agente conectado" em tempo real.

### Parar o agente

Se precisar encerrar (por exemplo, para atualizar o código):

```powershell
./parar-agente.ps1
```

Para ele parar de iniciar sozinho com o Windows, apague o atalho `AgenteImpressaoEtiquetas` da pasta de inicialização (tecla Windows + R, digite `shell:startup`, Enter).

## Alternativa: rodar manualmente numa janela

Se preferir ver os logs em tempo real numa janela de terminal (útil para testar):

```bash
npm install
npm start
```

Nesse modo, a janela precisa ficar aberta — se fechar, o agente para. Se a conexão cair, ele tenta reconectar automaticamente.
