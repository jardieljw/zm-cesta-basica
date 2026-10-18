# Piloto real: pagamento revisado de uma conta existente

**Continuidade em FE-054 — 17/10/2026:** [Receber revisado](PILOTO_RECEBER_REVISADO.md)
foi integrado. Pagar e Receber agora usam máquina de apresentação e motor de
retomada compartilhados, com adaptadores próprios; JSON/chaves anteriores de
Pagar preservados. O material nativo ganhou luzes radiais/sombra suave. A lista
de Pagar conserva sua composição e filtros. Os resultados e capturas FE-053
abaixo são históricos; ver a evidência FE-054 para a verificação da extração.

**FE-053 — 16/10/2026. Implementação incremental Flutter/API.** Autorização:
usuário respondeu “Show vamo embora” após a indicação de Pagar funcionando no
aplicativo como próxima entrega concreta. Esse retorno autoriza o recorte
preparado em FE-050; não precisa de outra aprovação para cada ajuste rotineiro.
Fonte visual conservada: [FE-052](referencias_frontend/rodada-acabamento-2026-10-16/README.md).

## 1. Onde está e o que foi entregue

Em **Contas a Pagar → Pagar / Amortizar**, o diálogo antigo foi substituído por
uma página com consulta do detalhe, saldo/histórico, formulário, revisão,
confirmação e retorno à lista. A lista e seus filtros existentes permanecem;
os totais continuam explicitamente das contas exibidas, com carregamento de
mais páginas de cem. Pendências locais aparecem acima da lista, inclusive se
uma quitação deixou de aparecer no filtro de contas abertas.

- Integral do saldo consultado é o padrão. Parcial revela seu campo; valor
  parcial oculto não entra no comando. Valores são analisados em centavos,
  sem arredondar entrada com casas decimais excedentes.
- Data de negócio começa no dia atual UTC−03; calendário seleciona dia civil.
  Forma começa sem seleção, com os códigos próprios de Pagar. Observação é opcional.
- Revisar consulta o título novamente. Mudança do saldo/situação conserva o
  preenchimento, apresenta o valor atualizado e exige nova revisão.
- Revisão identifica favorecido, descrição, número da conta, valor, data,
  forma, observação e consequência no saldo. Editar conserva campos.
- Confirmar congela a identificação e o corpo antes de qualquer POST. Envio
  em andamento bloqueia repetição e saída da etapa; resposta HTTP tem limite de
  vinte segundos neste cliente vinculado, sem afirmar que timeout cancelou o servidor.
- Resposta desconhecida mantém comando e chave em armazenamento local. A pessoa
  pode sair e retomar a mesma tentativa depois; não se cria outra chave automaticamente.
- Confirmação conhecida e consulta do saldo são resultados separados. Se o GET
  falhar, permanece “Pagamento registrado”; Atualizar repete a consulta.
- Sair pelo botão da confirmação reconhece o recibo local. Sair pela navegação
  conserva o recibo para acompanhamento. Isso não apaga o registro do servidor.

O material da página é local ao piloto: fundo suave, painéis de raio 32, campos
24 e grupos 20, leitura sem negrito generalizado, azul padrão #2866ae. Superfícies
sólidas são usadas com alto contraste/navegação assistiva. Isso não homologa
Reduce Transparency nativo. Navegação principal, tema global, Receber e demais
áreas não foram migrados por esse recorte.

## 2. Responsabilidades e arquivos

| Camada | Responsabilidade |
| --- | --- |
| [PayablePaymentView](../client/lib/views/payable_payment_view.dart) | Apresentação, rascunho, validação de entrada, calendário, revisão e estados conhecidos/incertos. |
| [PayablePaymentCoordinator / AttemptStore](../client/lib/services/payable_payment_coordinator.dart) | Corpo congelado, identidade, persistência, retomada, recibo e classificação conservadora de erros. |
| [PayableService](../client/lib/services/payable_service.dart) e [ApiClient](../client/lib/core/api_client.dart) | REST existente, pinning TLS, token e conexão vinculada. Nenhuma tela acessa SQLite. |
| [FinancialSurface](../client/lib/widgets/shared/financial_surface.dart), [AnimatedReveal](../client/lib/widgets/shared/animated_reveal.dart) | Material e revelação reutilizáveis, sem regras contábeis. |
| [BusinessDates](../client/lib/utils/business_dates.dart), [MoneyInput](../client/lib/utils/money_input.dart), [AppFormatters](../client/lib/utils/formatters.dart) | Dia civil, entrada inteira e exibição centralizada. |
| [Schema](../backend/app/schemas/financial.py), [API](../backend/app/api/v1/payables.py), [serviço financeiro](../backend/app/services/financial.py) | Contrato, replay, precondição e mutação transacional do domínio. |

Textos usam l10n; códigos viram mensagens pelo
[ApiErrorMapper](../client/lib/utils/api_error_mapper.dart). Não foram adicionadas
dependências, tabelas ou migrações. Pagamento e livro-caixa seguem as operações
de domínio existentes, preservando histórico e estornos.

## 3. Contrato aditivo e concorrência

`POST /api/v1/payables/{id}/payments` aceita, adicionalmente:

| Campo | Contrato |
| --- | --- |
| `expected_balance_cents` | Opcional para consumidores legados; o piloto sempre envia o saldo revisado. Verificado no callback sob a transação `BEGIN IMMEDIATE` existente. Divergência retorna 409 `PAYABLE_BALANCE_CHANGED` antes de gravar. |
| `payment_business_date` | Dia ISO `YYYY-MM-DD` na convenção atual UTC−03. Não pode acompanhar `payment_date`. Armazenado no início desse dia, 03:00Z; é representação técnica do dia escolhido, sem atribuir ao operador um horário efetivo informado. |

Consumidores que enviam `payment_date` ou omitem a data preservam seu contrato.
Instantes históricos não são reescritos. Serialização de pagamentos consultados
explicita UTC; o cliente também interpreta respostas legadas sem offset como UTC.

O hash legado **exclui os campos novos quando nulos** e conserva todos os campos
anteriores. Assim, uma chave antiga não se torna incompatível apenas por atualizar
o schema. Replay é resolvido antes da precondição: a quitação já confirmada pode
ser recuperada mesmo que o saldo atual seja zero ou tenha mudado depois.

O detalhe informa `payment_review_version=1`. O cliente exige essa capacidade
antes de enviar/retomar, impedindo que um servidor antigo ignore silenciosamente
os campos novos. Atualizar servidor e cliente correspondentes antes de usar o
piloto instalado; não foi aplicado automaticamente no servidor da empresa.

Saldo conferido não é versão completa do histórico. GET antes de POST melhora
a revisão, mas a garantia de saldo é a precondição dentro da transação. O
pagamento continua limitado ao saldo, com conta interna resolvida pelo domínio.

## 4. Persistência e resposta desconhecida

Cada tentativa conserva origem (URL normalizada + fingerprint público), título,
chave UUID, corpo imutável e referências de identificação. Token não é persistido
nesse objeto. Tentativas usam chaves separadas por origem/título em
SharedPreferences; falha ao salvar impede POST. Dados locais corrompidos bloqueiam
novo comando, sem serem descartados silenciosamente.

Um bloqueio local impede dois coordenadores do mesmo processo de iniciar nova
gravação simultânea para a conta. O servidor protege a operação entre terminais.
Cliente vinculado congela URL/fingerprint, revalida a conexão e mantém o pinning
antes do HTTP. Troca de servidor/fingerprint conserva a tentativa na origem
original e impede enviá-la à conexão nova. Conexões vinculadas são reutilizadas
e fechadas ao encerrar o coordenador proprietário.

**Retomar registro** repete o POST com mesma chave e corpo. Pode obter o recibo
anterior ou concluir a intenção que ainda não havia chegado. Não é uma consulta
somente de leitura. Uma consulta sem registro visível não libera chave nova.

Somente recusas estruturadas do callback, depois da busca por replay, liberam a
tentativa: `PAYABLE_BALANCE_CHANGED`, `PAYABLE_NOT_OPEN`,
`PAYABLE_AMOUNT_EXCEEDS_BALANCE`, `PAYABLE_NOT_FOUND`,
`PAYABLE_PAYMENT_METHOD_INVALID`. Esses erros preservam seus status HTTP usuais;
o corpo passou a usar `detail.error_code/message`, suportado pelo mapper existente.
Não decidir pelo texto traduzido. Erros de consulta, transporte, autenticação,
422, 5xx, `REQUEST_IN_PROGRESS` e incompatibilidade da chave conservam a tentativa.

Se gravar o recibo local falhar após uma confirmação válida, a tela mantém a
confirmação conhecida; o comando pendente anterior ainda pode fazer replay após
reiniciar. Não existe ação de descartar um pagamento incerto como se fosse recusado.
Rascunho ainda não enviado não tem promessa de persistência após fechar o aplicativo.

## 5. Datas de vencimento e cobertura

Em Pagar, lista `overdue_only` e serializador `is_overdue` agora usam a data
civil de vencimento anterior ao dia de negócio, em acordo com o resumo existente.
Vencimento de hoje não é atraso apenas porque passou de 00:00. O transporte de
vencimento mantém o contrato existente. Referência central:
[business_dates](../backend/app/core/business_dates.py).

A harmonização equivalente de Receber permanece para seu incremento. O novo
Início/Negócio das prévias não foi aplicado ao Flutter. Listas paginam e seus
totais identificam as contas exibidas; não representam agregação global nem saldo
bancário. Filtro/contexto são preservados ao voltar do pagamento.

## 6. Evidências e continuação

Verificação final: **420 testes backend e 274 Flutter aprovados**, análise estática
sem pendências e compilação Windows **debug** concluída. A instalação da empresa
não foi substituída. A compilação de teste depende da pasta Debug completa e de
um servidor atualizado com este contrato; não distribuir somente o executável.

O [registro FE-053](validacoes_frontend/fe-053-piloto-pagar-2026-10-16/README.md)
conserva resultados, hashes e capturas de widgets Flutter com dados de teste.
Não confundir essas imagens com uso no aparelho ou com dados da empresa.

Testes cobrem resposta perdida com reinício do coordenador, corpo/chave/data
idênticos, recibo sem novo POST, recusa versus falha incerta, persistência
indisponível/corrompida, conexão alterada, servidor antigo, saldo após reversão,
compatibilidade do hash legado, dia de negócio e fluxo responsivo com calendário.

Próximo recorte: aplicar o padrão em Receber com seus métodos e efeitos nas vendas,
reaproveitando somente os contratos adequados. Depois integrar organização e
aparência das áreas principais e validar os alvos nativos. Não reabrir a disputa
tipográfica nem substituir a navegação acolhida para fazer essa integração.
