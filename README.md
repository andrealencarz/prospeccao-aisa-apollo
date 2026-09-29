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
/prospeccao-aisa-apollo gráfica Teresina
```

Use sempre **cidade** (com bairro opcional). Se pedir só o estado ("agência digital Ceará"), o skill busca na capital automaticamente — buscar o estado inteiro de uma vez trava.

## O que você recebe

Uma tabela com, pra cada empresa encontrada:
- **Nome**
- **Avaliações no Google** — poucas ou zero = sinal de negócio novo (é o critério de ordenação)
- **Endereço completo** (com bairro)
- **Telefone**
- **Site** — sempre aparece, com um destes valores: o domínio próprio, "só Instagram", "só link" (Linktree, WhatsApp, página de construtor de site) ou "sem site". Quem não tem site é um ótimo lead pra serviço de presença digital.
- **Responsável** — extraído do nome do negócio quando é autônomo ("Dra. Fulana Odontologia", "Luciano Gráfica"), ou via Apollo quando a empresa tem site próprio
- **LinkedIn do responsável** — quando encontrado com confiança (nome e empresa batendo); senão fica "—"

Quando a primeira busca vem cheia (nicho denso), o skill puxa uma segunda leva sozinho, chegando a até 200 empresas.

## Limitações importantes

- **Não existe fonte de CNPJ/data de fundação oficial** no que o skill usa — o "negócio novo" é estimado pelo número de avaliações no Google, não é uma data exata.
- **Responsável nem sempre aparece**: o Apollo só acha quem tem site próprio. Em nichos de comércio local (gráfica, salão, oficina) quase ninguém tem site, e o nome do negócio muitas vezes traz só o primeiro nome do dono.
- **E-mail e telefone pessoal do responsável estão indisponíveis no momento**: a função do Apollo que revela esse contato está com defeito do lado da AIsa (confirmado em teste). O telefone da empresa, que vem do Google, continua saindo normalmente. A alternativa de enriquecimento em lote do Apollo funciona, mas custa ~US$ 1,78 por pessoa, então o skill **não** usa.
- **LinkedIn acerta em cerca de 1 a cada 3 tentativas**: funciona bem quando a pessoa cita a própria empresa no perfil; com nome comum, o skill prefere deixar "—" a colar um link errado.
- **Cada busca gasta crédito da AIsa** (tipicamente centavos de dólar por busca completa) — não é gratuito, ainda que barato.

## Se der erro

- **"Invalid Field: location_name"**: o skill já tenta se corrigir sozinho (algumas cidades exigem um formato diferente). Se persistir, rodar de novo geralmente resolve.
- **Timeout na busca**: normalmente acontece quando se pede um estado inteiro. Use uma cidade.
- **Erro "contract mismatch" no Apollo**: é o defeito conhecido do lado da AIsa (ver Limitações). O skill segue sozinho e entrega o resto do resultado.

## Atualizar

Mande de novo, no chat do Claude Code, a mesma mensagem da instalação — ela baixa a versão mais recente do `SKILL.md`. O skill é atualizado aqui no repositório conforme novos testes.
