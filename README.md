# prospeccao-aisa-apollo

Skill do Claude Code pra prospecção B2B ativa. Você diz o nicho e a cidade, o Claude busca empresas prováveis de terem aberto recentemente, com endereço, telefone, avaliações e (quando dá) o nome do responsável — tudo sem precisar programar ou saber usar API.

## Instalar

### Opção fácil — sem terminal (recomendado pra quem não é técnico)

Abra o Claude Code, cole a mensagem abaixo no chat e mande:

```
Instale esse skill pra mim: baixe o conteúdo de
https://raw.githubusercontent.com/andrealencarz/prospeccao-aisa-apollo/main/SKILL.md
e salve em ~/.claude/skills/prospeccao-aisa-apollo/SKILL.md (criando as pastas se
precisar). Depois, adicione ao meu ~/.claude/CLAUDE.md (crie o arquivo se não existir)
um bloco dizendo que quando eu digitar /prospeccao-aisa-apollo, invoque o Skill tool
com skill: "prospeccao-aisa-apollo" antes de fazer qualquer outra coisa. Não duplique
esse bloco se ele já existir.
```

O próprio Claude baixa o arquivo e configura tudo. Depois é só usar `/prospeccao-aisa-apollo` normalmente.

### Opção terminal (pra quem tem familiaridade)

```bash
curl -fsSL https://raw.githubusercontent.com/andrealencarz/prospeccao-aisa-apollo/main/install.sh | bash
```

Isso baixa o `SKILL.md` do repositório pra `~/.claude/skills/prospeccao-aisa-apollo/` e registra o gatilho `/prospeccao-aisa-apollo` no seu `~/.claude/CLAUDE.md`. Seguro rodar mais de uma vez — não duplica nada.

## Pré-requisito: MCP da AIsa conectado

A **AIsa** é um **conector MCP** (Model Context Protocol) — um "plugin" que dá ao Claude acesso a mais de 950 APIs de dados (Google Maps, Apollo, redes sociais, etc.) usando uma chave só. É isso que o skill usa por baixo dos panos. Sem esse conector ativo na sua conta, o skill instala mas não tem o que buscar.

**Passo a passo:**

1. Crie uma conta e gere uma chave de API em [aisa.one](https://aisa.one).
2. No app do Claude, procure nas Configurações por algo como "Conectores" ou "MCP Servers" → "Adicionar conector" e informe:
   - URL: `https://mcp.aisa.one/mcp`
   - Cabeçalho de autorização: `Authorization: Bearer SUA_CHAVE_AQUI` (a chave que você gerou no passo 1)
3. Se não achar essa tela ou tiver qualquer dúvida, pergunte direto pro Claude no chat: "me ajuda a conectar o servidor MCP da AIsa, a URL é `https://mcp.aisa.one/mcp` e minha chave é `SUA_CHAVE_AQUI`" — ele te guia pela interface da sua versão específica do app.

Depois de conectado, teste digitando no Claude Code:
```
liste as ferramentas disponíveis da AIsa
```
Se o Claude conseguir listar operações do Apollo/DataForSEO, está tudo certo.

## Usar

No chat do Claude Code:

```
/prospeccao-aisa-apollo <nicho> <cidade>
```

Exemplos:
```
/prospeccao-aisa-apollo salão de beleza São Paulo
/prospeccao-aisa-apollo dentista em Fortaleza
/prospeccao-aisa-apollo imobiliária Aldeota Fortaleza
```

## O que você recebe

Uma tabela com, pra cada empresa encontrada:
- Nome
- Avaliações no Google (poucas/zero = sinal de negócio novo — é o critério de ranqueamento)
- Endereço completo (com bairro)
- Telefone
- Site (quando tem)
- Responsável (extraído do nome do negócio quando é consultório individual, ou via Apollo quando tem site)

## Limitações importantes

- **Não existe fonte de CNPJ/data de fundação oficial** no que o skill usa — o "negócio novo" é estimado pelo número de avaliações no Google, não é uma data exata.
- **Apollo não acha responsável de negócio sem site** — comum pra profissional autônomo pequeno. Nesses casos o skill tenta extrair o nome do próprio nome do negócio no Google Maps (ex: "Dra. Fulana Odontologia"), mas nem sempre tem esse padrão.
- **Cada busca gasta crédito da AIsa** (tipicamente centavos de dólar por busca completa) — não é gratuito, ainda que barato.
- **Foco em nicho + cidade grande/média brasileira** — testado em várias capitais; cidade muito pequena pode ter menos resultado.

## Se der erro

- **"Invalid Field: location_name"**: o skill já tenta se corrigir sozinho. Se persistir, tentar rodar de novo geralmente resolve.
- **Erro de instabilidade no Apollo** ("contract mismatch" ou 502): o skill já trata isso como best-effort e entrega o resto do resultado normalmente.

## Atualizar

Rodar o mesmo comando de instalação de novo — baixa a versão mais recente do `SKILL.md`.
