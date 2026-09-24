# prospeccao-aisa-apollo

Skill do Claude Code pra prospecção B2B ativa. Você diz o nicho e a cidade, o Claude busca empresas prováveis de terem aberto recentemente, com endereço, telefone, avaliações e (quando dá) o nome do responsável — tudo sem precisar programar ou saber usar API.

## Instalar

Rode no terminal (não dentro do chat do Claude):

```bash
curl -fsSL https://raw.githubusercontent.com/andrealencarz/prospeccao-aisa-apollo/main/install.sh | bash
```

Isso baixa o `SKILL.md` do repositório pra `~/.claude/skills/prospeccao-aisa-apollo/` e registra o gatilho `/prospeccao-aisa-apollo` no seu `~/.claude/CLAUDE.md`. Seguro rodar mais de uma vez — não duplica nada.

## Pré-requisito: MCP da AIsa conectado

Esse skill usa ferramentas de um conector chamado **AIsa** (gateway com acesso a Google Maps, Apollo e outras +950 fontes de dados numa chave só). Sem esse conector ativo na sua conta do Claude Code, o skill instala mas não tem o que buscar.

> ⚠️ **Professor, preencha aqui como o aluno deve conectar a AIsa no ambiente de vocês** (ex: link de cadastro, onde pegar a chave de API, como adicionar o MCP server no Claude Code).

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
