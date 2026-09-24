# /prospeccao-aisa-apollo

Prospecção B2B ativa: encontra empresas com probabilidade alta de terem aberto/expandido recentemente, num nicho e cidade que o usuário passar, e monta lista de contatos qualificada. Motor principal: **Google Maps** (DataForSEO, via AIsa). Motor secundário/enriquecimento: **Apollo** (via AIsa).

**Este skill é de uso geral — quem invoca pode ser totalmente leigo em API, DataForSEO, Apollo etc.** Toda tradução técnica é trabalho meu (Claude), nunca do usuário. As regras abaixo existem pra isso.

## Como conversar com o usuário

1. **Só peça o essencial**: nicho + cidade/estado (bairro é opcional, só refina). Se faltar nicho ou cidade, pergunte só isso.
2. **Nunca exponha jargão técnico** — DataForSEO, `location_code`, JSON, nomes de campo, SIC. Traduza tudo pra português simples no que o usuário vê.
3. **Fluxo 100% automático, sem pergunta de confirmação no meio** — busca, filtro, enriquecimento com Apollo (fundação, responsável, contato) das top 10 são todos automáticos por padrão. Nunca parar pra perguntar "quer que eu busque X?" — já busca e entrega.
4. **Cobertura fraca não trava o fluxo, só amplia sozinho**: se vier pouco resultado, ampliar automaticamente (remover filtro de bairro se tinha, tentar variação de palavra-chave) e mencionar no resultado final o que foi ampliado — sem perguntar antes.
5. **Erro técnico vira nota curta em português no resultado final**, não pergunta nem diagnóstico técnico. Ex: "o enriquecimento de contato direto deu instabilidade agora, segue o resto normal".
6. **Defaults automáticos, sem perguntar**: tudo decidido sozinho (ver seção "Defaults" abaixo). Só mencionar no resumo final, nunca como pergunta.

## Fluxo interno

### 1. Entender o pedido
- Nicho + cidade/estado são obrigatórios; bairro é opcional (usado como filtro depois, não na busca em si).
- Erro de digitação óbvio em cidade/estado → corrigir sozinho, sem confirmar.

### 2. Buscar no Google Maps (motor principal)
```
tool: mcp__3e1df2eb-890e-4ea8-b643-a3e19b6b7387__use
operation_id: post_dataforseo_serp_google_maps_live
arguments: { body: [{ keyword: "<nicho em português>", location_name: "<Cidade,Estado,Brazil>", language_code: "pt" }] }
max_price_usd: 0.02
```
- `keyword` vai **em português direto** (ex: "salão de beleza", "imobiliária", "corretora de seguros") — Google Maps não precisa de tradução pro inglês como o Apollo precisava.
- `location_name` no formato `Cidade,Estado,Brazil` sem espaço depois da vírgula, estado sem acento/cedilha (ex: `Fortaleza,Ceara,Brazil`, `Sao Paulo,Sao Paulo,Brazil`).
- Retorna 100 resultados por padrão numa chamada só (`data.tasks[0].result[0].items[]`), cada um com `title`, `category`, `address`, `phone`, `domain`, `rating.value`, `rating.votes_count`, `place_id`. O parâmetro `depth` controla quantos vêm — não é paginação por página, é "quantos nessa mesma chamada" (testado: `depth: 200` trouxe 200 de fato, custo dobrou de $0.002 pra $0.004, ainda irrisório).
- **O resultado é grande (~200 KB) e vem salvo em arquivo** — sempre extrair com `jq`/`python` via Bash, nunca tentar ler tudo direto.

### 3. Filtrar por categoria (leve, quase sempre desnecessário)
`category`/`additional_categories` do Google Maps já vem correto na esmagadora maioria dos casos (diferente do Apollo, que precisava de filtro SIC pesado). Só descartar item se a categoria claramente não bate com o nicho pedido — não é o gargalo aqui.

### 4. Filtro de bairro (se o usuário pediu)
`address` já contém o bairro por extenso (ex: "R. Costa Barros, 915 - Aldeota, Fortaleza - CE"). Se o usuário mencionou um bairro, filtrar por substring no `address` (case-insensitive). Isso resolve de graça a limitação de bairro que o Apollo não tinha.

### 5. (Opcional) Filtrar só empresas sem site
Só aplicar se o usuário pedir explicitamente. `domain: null` no item do Google Maps já indica isso diretamente — nesse motor o campo é bem mais confiável e tem fill-rate real (~30% sem site é comum em comércio local, bem diferente do Apollo que quase não pegava ninguém sem site).

### 6. Ranquear (proxy de "empresa nova")
Google Maps não dá ano de fundação. O proxy aqui é **número de avaliações** (`rating.votes_count`): poucas ou zero avaliações é sinal forte de negócio recém-aberto (ainda não acumulou histórico no Google). Ordenar por `votes_count` ascendente. Em empate, `rating.value` desc como desempate de qualidade (não de recência).

### 7. Extrair nome do responsável do título (grátis, sempre tentar primeiro)
Em nicho de profissional autônomo/consultório individual (odontologia, saúde, estética, advocacia, psicologia, personal trainer, etc.), o **nome do dono costuma estar literal no `title` do Google Maps**: "Consultório Odontológico Dra. Fulana de Tal", "Dr. Fulano - Implantodontia", "Fulana Cardoso Odontologia Especializada". Antes de gastar qualquer coisa com Apollo, tentar extrair esse padrão do título (procurar "Dr.", "Dra.", "Dr ", ou nome próprio composto seguido/precedido do nome do serviço). Se achar, esse já é o responsável — alta confiança, custo zero.
Não funciona pra clínica com nome de marca genérico ("Clínica Odontológica Via Saúde", "Policlínica X") — aí não força, marca como "não identificado" e segue pro passo 8 se tiver domínio.

### 8. Apresentar tabela (linguagem simples, sem jargão)
| Empresa | Avaliações | Endereço | Telefone | Site | Responsável |
|---|---|---|---|---|---|
| Nome | "0 avaliações (provável negócio novo)" ou "N avaliações, nota X" | endereço completo | telefone ou "—" | domínio ou "sem site" | nome extraído do título, ou "não identificado" (a confirmar no passo 9) |

Se veio pouco resultado: ampliar sozinho (tentar sem filtro de bairro, ou variação da palavra-chave) e mencionar no resumo final — nunca citar "items_count" ou jargão técnico.

**Se veio no teto (100, o padrão sem `depth` especificado)**: nicho denso, provavelmente tem mais candidato fora da primeira leva. Rodar de nova a mesma busca com `depth: 200` (custo dobra mas continua irrisório, ~$0.004) e mesclar os resultados — sem perguntar, é ajuste automático. Testado: itens 101-200 ainda trazem candidato novo relevante (ex: mais empresas com zero avaliação), só que numa taxa menor que os 100 primeiros (Google já ordena por relevância/avaliação).

### 9. Enriquecer com Apollo (automático, só top 10 sem nome identificado no passo 7, best-effort)
Só pras da tabela do passo 8 que ficaram "não identificado" **e** têm `domain` (sem domínio nem nome no título, pular Apollo — ele precisa de identificador e ninguém acha consultório pequeno sem site lá mesmo):
```
operation_id: post_apollo_mixed_people_api_search
arguments: { q_organization_domains_list: [<domínios sem responsável ainda>], person_seniorities: ["owner","founder","c_suite"] }
```
Depois, pra quem teve responsável encontrado:
```
operation_id: post_apollo_people_match
arguments: { id: <id retornado> }
```
Isso é **enriquecimento opcional**, não a base do resultado — se o Apollo estiver instável (erro de contrato/502, já aconteceu antes) ou não achar nada, seguir o fluxo normalmente e entregar a tabela com o que já tem (título + Google Maps), mencionando em uma frase que o enriquecimento extra não completou dessa vez.
`founded_year` do Apollo, quando vier, entra como informação extra na tabela final — mas não é mais o critério de ranking (isso agora é `votes_count`).

### 10. Entregar resultado final
Tabela: empresa | avaliações (proxy de novo) | endereço | telefone | site | responsável (título ou Apollo, o que achou primeiro) | fundação Apollo (se achou) | e-mail/telefone pessoal (se achou via Apollo). Fechar com 1-2 frases resumindo ajustes automáticos feitos, sem transformar isso em pergunta.

## Defaults (decidir sozinho, não perguntar)

| Situação | Default |
|---|---|
| Palavra-chave da busca | Nicho em português, direto, sem tradução |
| Quantidade de resultados | 1 chamada ao Google Maps (retorna até 100). Só rodar de novo com keyword diferente se vier pouco |
| Filtro de bairro | Só aplica se o usuário mencionou um bairro; senão mostra a cidade toda |
| Filtro "sem site" | Off por padrão — só liga se o usuário pedir |
| Enriquecimento Apollo (fundação, responsável, contato) | Automático, sem perguntar, só nas top 10 (ranqueadas por menos avaliações). Best-effort — não trava o fluxo se falhar |
| Cobertura fraca | Ampliar sozinho (remover filtro de bairro, tentar variação de palavra-chave) sem perguntar, e mencionar no resumo final |

## Referência técnica (uso interno — nunca mostrar cru ao usuário)

### Por que Google Maps virou o motor principal (mudança de 2026-09-25)
Testado lado a lado em "imobiliária, Fortaleza" — mesmo caso que tinha ficado fraco no Apollo:

| | Apollo | Google Maps |
|---|---|---|
| Resultados relevantes | 10 (de 25 brutos, 15 falso positivo) | 100 numa chamada |
| Endereço | 0% (Apollo não tem esse campo) | 100% |
| Telefone | ~10% | 97% |
| Falso positivo | Alto (keyword solta pegava engenharia, arquitetura, investimento) | Quase zero (categoria do Google já vem certa) |
| Custo | ~$0.02/call | ~$0.002/call |
| Bairro | Sem filtro nativo | Endereço já contém o bairro, filtra de graça |

Apollo continua útil só pro que Google Maps não tem: nome do responsável e ano de fundação — por isso virou enriquecimento secundário (passo 8), não mais a busca principal.

### Lições de testes anteriores (histórico, ainda relevante pro Apollo como enriquecimento)
- **Keyword genérica em inglês no Apollo gera ruído independente do volume total**: `["gym","fitness"]` em Fortaleza trouxe 351 resultados totais mas só ~1 em 25 era academia de verdade. Isso é sintoma do problema que o Google Maps resolve — mas se algum dia usar Apollo como busca principal de novo, lembrar disso.
- **Nicho regulado/corporativo tinha cobertura melhor no Apollo** (seguradora em Pernambuco: 274 resultados, ~80% precisão) — mas o Google Maps também cobre esses nichos bem e com mais dado (endereço/telefone), então não há mais motivo forte pra usar Apollo como busca primária nem nesses casos.
- **Canal Instagram foi testado e descartado** para descoberta de leads: `get_instagram_search_profiles` com frase exata não faz correspondência de frase, só pondera termos soltos — 54 perfis retornados, 0 relevantes. `get_instagram_search_hashtag` deu erro 400 de contrato. Não usar esse canal.
- **`post_apollo_people_match` e `post_apollo_people_bulk_match` deram erro "request does not match the endpoint contract"** em teste real (2026-09-25), mesmo com parâmetros válidos e variados (por id, por nome+domínio, com/sem reveal). Parece instabilidade pontual da AIsa nesse endpoint específico — tratar como best-effort (passo 8), nunca bloquear a entrega do resultado por causa disso.
- **`post_apollo_people_bulk_match` não substitui múltiplos `post_apollo_people_match`** de forma confiável — mesmo erro de contrato nos dois. Preferir tentar `post_apollo_people_match` individual quando `bulk_match` falhar.
- **Apollo não acha responsável de negócio sem site, ponto final** (precisa de domínio, não busca por nome de empresa em texto). Pra profissional autônomo (dentista, advogado, personal, esteticista) isso é a maioria dos casos. Testado em Teresina: dos 10 do shortlist "zero avaliação", 0 tinham site, então Apollo não achava nada pra nenhum. **O nome do responsável já estava no `title` do Google Maps em 4 dos 10** ("Consultório Odontológico Dra. Fulana", "Fulana Cardoso Odontologia") — extração de texto grátis resolve o que o Apollo estruturalmente não consegue nesse perfil de negócio. Sempre tentar isso antes/em paralelo ao Apollo (ver passo 7).

### Formato de `location_name` pro Google Maps
`Cidade,Estado,Brazil` funciona pra algumas cidades (`Fortaleza,Ceara,Brazil`, `Sao Paulo,Sao Paulo,Brazil` testados e ok), mas **não é universal** — `Aracaju,Sergipe,Brazil` e `Aracaju,Brazil` deram erro `40501 Invalid Field: 'location_name'`, só funcionou com `Aracaju,State of Sergipe,Brazil` (prefixo "State of" antes do nome do estado). Inconsistência real da base de locations do DataForSEO, não erro de digitação.
**Como lidar**: tentar primeiro `Cidade,Estado,Brazil`; se vier `status_code: 40501`, tentar de novo com `Cidade,State of Estado,Brazil` antes de desistir ou perguntar ao usuário — é ajuste automático, não trava o fluxo.

### Custo de referência (plan "builder", preços podem variar)
- `post_dataforseo_serp_google_maps_live`: ~$0.002-0.012/call (até 100 resultados) — motor principal, muito barato
- `post_apollo_mixed_people_api_search`: ~$0.012/call (uma call cobre todo o shortlist)
- `post_apollo_people_match`: preço dinâmico, cotar com `get_details` antes — mas instável no momento (ver lição acima), tratar como best-effort
- `get_instagram_search_profiles`: baixo custo, mas canal descartado pra descoberta

### Regras operacionais (sempre válidas, independente da comunicação com o usuário)
- Google Maps é a busca principal — nunca pular direto pro Apollo como motor de descoberta.
- Apollo (fundação, responsável, contato) é enriquecimento best-effort das top 10, nunca bloqueia a entrega do resultado principal se falhar.
- Resultado do Google Maps vem grande (~200 KB) e salvo em arquivo — sempre processar com `jq`/`python` via Bash, nunca tentar ler tudo de uma vez.
- Sempre cotar com `get_details` (grátis) antes de rodar em volume, e passar `max_price_usd` no `use` como trava.
- Erro 502/upstream ou "contract mismatch" é instabilidade da AIsa, não do parâmetro — tentar de novo no máximo 2-3 vezes; se persistir, seguir o fluxo sem essa parte e avisar em português simples no resultado final, sem insistir em loop.
