# Escolha de esforço dos agentes

Direção do usuário em **20/10/2026**: reutilizar referências locais e recomendar
o esforço ao apresentar um plano. Começar por este guia; não carregar todas as
páginas completas. As recomendações abaixo são julgamento do projeto, não uma
garantia da OpenAI sobre uma tarefa específica.

**Leitura habitual:** somente a seção Consulta rápida. As demais seções servem
para dúvidas sobre atualização, fontes ou economia; não precisam ser relidas
a cada recomendação.

## Consulta rápida

Para **Sol 6.1**, começar pelo menor esforço adequado ao problema:

| Esforço | Uso recomendado neste projeto |
| --- | --- |
| Baixo | Alteração pontual conhecida, texto ou consulta simples, sem investigação relevante. |
| Médio | Correção delimitada, implementação usual, plano incremental, diagnóstico com contratos e testes conhecidos. |
| Alto | Ambiguidade importante, investigação difícil, decisões entre vários módulos ou alteração delicada de persistência/cálculos. |
| Muito alto/máximo, quando disponíveis | Somente se a dificuldade demonstrada justificar o custo adicional. Não usar por rotina. |

Complexidade e incerteza importam mais que tamanho do arquivo ou número da etapa.
Médio não reduz critérios de aceitação; alto não substitui testes nem garante
ausência de falhas. Elevar a recomendação se a investigação revelar complexidade
nova; não presumir que qualquer tarefa financeira exige alto.

Ao apresentar um plano ou uma nova etapa relevante, informar uma frase como:
**“Esforço recomendado: Sol 6.1 no Médio — correção delimitada com causa conhecida.”**
Justificar pelo escopo real e respeitar o modelo escolhido pelo usuário. Não
repetir o aviso a cada mensagem, bloquear trabalho autorizado, trocar configurações
automaticamente nem alegar ter mudado o esforço da sessão.

## Consulta e atualização das fontes

1. Usar este resumo para a recomendação habitual por escopo.
2. Se necessário, pesquisar com `rg` e ler só a seção pertinente da cópia local.
3. Consultar a fonte oficial quando houver pedido de informação atual, novo
   modelo/configuração, divergência, provável desatualização ou exigência de
   instrução superior. Não refazer uma pesquisa só para repetir a mesma orientação.
   Cópias são registros datados, não prova de que o produto permaneceu igual.

As cinco cópias Markdown foram baixadas da **documentação oficial da OpenAI** em
20/10/2026. [Manifesto](referencias_agentes/esforco_openai/manifest.json) conserva
URL original, URL baixada, data UTC, tamanho e SHA-256. Ao atualizar uma cópia,
atualizar sua procedência e conferir este resumo; não revalidar todas por rotina.

| Cópia local | Consultar para |
| --- | --- |
| [Sol 6.1](referencias_agentes/esforco_openai/gpt-6.1-sol.md) | Modelo específico e níveis suportados na data da consulta. |
| [Reasoning](referencias_agentes/esforco_openai/reasoning.md) | Esforço e tokens de raciocínio. |
| [Deployment checklist](referencias_agentes/esforco_openai/deployment-checklist.md) | Critérios gerais de esforço e avaliação por tarefa. |
| [Latency optimization](referencias_agentes/esforco_openai/latency-optimization.md) | Tempo de resposta, quantidade de chamadas e contexto. |
| [Prompt caching](referencias_agentes/esforco_openai/prompt-caching.md) | Diferença entre reutilização do prompt e arquivos salvos no repositório. |

## Economia esperada e limites

Evitar buscas repetidas pode reduzir chamadas, espera de rede e texto trazido
para o contexto. O ganho depende da consulta; ler o acervo inteiro pode anular
a economia. O resumo curto e a leitura seletiva são a parte essencial.

**44 segundos não permitem calcular tokens ou créditos consumidos.** O tempo
inclui raciocínio, geração, rede e ferramentas. Esforço menor costuma reduzir
tokens de raciocínio, mas retrabalho também custa. Não prometer percentuais de
economia sem medição comparável de uso, tempo e resultado.

Salvar páginas localmente não ativa o prompt caching da OpenAI. As fontes
descrevem a API; não converter seus preços em gasto/limites do plano Codex do
usuário nem supor cache hit. Orientação prática: responder de forma proporcional,
reutilizar o contexto conhecido e verificar o necessário para a tarefa.
