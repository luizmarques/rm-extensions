# rm-extensions

Repositorio com o ruleset base Rolemaster Classic para Fantasy Grounds e extensoes complementares.

## Visao geral

Este projeto e composto por tres pacotes principais:

1. `RolemasterClassic.pak`
- Ruleset base do sistema Rolemaster Classic.
- Contem definicoes XML de janelas/records e scripts Lua de regras, combate e acoes.

2. `RMC - Spell Caster.ext`
- Extensao para fluxo de conjuracao e ajustes relacionados a magias.
- Sobrepoe/estende componentes do ruleset base.

3. `RMC - XP TAB.ext`
- Extensao que adiciona a aba de XP na ficha.
- Inclui automacao de preenchimento para eventos de rolagem e combate.

## Estrutura do repositorio

- `RolemasterClassic.pak/`
  - `base.xml`: manifesto principal do ruleset (ordem de includes/scripts)
  - `campaign/`, `ct/`, `desktop/`, `ref/`, `scripts/`, etc.
- `RMC - Spell Caster.ext/`
  - `extension.xml`: manifesto da extensao
  - `campaign/`, `scripts/`, `graphics/`
- `RMC - XP TAB.ext/`
  - `extension.xml`: manifesto da extensao
  - `campaign/record_char_xp.xml`: UI e calculos da aba de XP
  - `scripts/manager_xp_auto.lua`: automacao de XP
  - `README.md`: documentacao detalhada da extensao

## Como usar

1. Instale o ruleset base `RolemasterClassic.pak` no Fantasy Grounds.
2. Habilite as extensoes desejadas ao carregar a campanha:
- `RMC - Spell Caster`
- `RMC - XP TAB`
3. Verifique compatibilidade de load order pelos arquivos `extension.xml`.

## Automacao de XP (resumo)

A extensao `RMC - XP TAB` automatiza principalmente:

- Sucessos de skill/manobra por dificuldade.
- Sucessos de basecasting por nivel de magia.
- Dano causado e recebido (`hitsgiven` e `hitstaken`) no ponto real de aplicacao de dano.
- Abates (`foekill`) e classificacao de criticos na matriz A-E.
- Ajuste de `combatxpdesc` por diferenca de nivel do oponente.

Para detalhes, consulte `RMC - XP TAB.ext/README.md`.

## Desenvolvimento e manutencao

- Linguagens principais: Lua e XML.
- Nao ha pipeline local de build/test automatizado no repositorio.
- Validacao e feita por consistencia de manifests/includes/scripts e testes funcionais no Fantasy Grounds.

Recomendacoes:

1. Sempre atualizar manifests (`base.xml` / `extension.xml`) quando adicionar ou renomear arquivos carregados.
2. Preservar padroes de API do Fantasy Grounds (`DB`, `ActorManager`, `ActionsManager`, `OOBManager`, `Comm`).
3. Evitar mudancas fora do escopo da extensao alvo sem necessidade.

## Documentacao adicional

- `.github/copilot-instructions.md`: diretrizes de alteracao para este workspace.
- `SESSION_MODIFICACOES_2026-04-09.md`: registro das modificacoes da sessao.

## Licenca e creditos

Consulte `RolemasterClassic.pak/license.html` para atribuicoes e informacoes de licenciamento.
