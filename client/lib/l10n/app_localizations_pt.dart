// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'ZM Cesta Básica';

  @override
  String get homeHeaderTitle => 'ZM Cestas - Gestão de Estoque';

  @override
  String get commonSave => 'Salvar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get commonDelete => 'Excluir';

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonClose => 'Fechar';

  @override
  String get commonBack => 'Voltar';

  @override
  String get commonSearch => 'Buscar';

  @override
  String get commonFilter => 'Filtrar';

  @override
  String get commonClear => 'Limpar';

  @override
  String get commonLoading => 'Carregando...';

  @override
  String get commonRefresh => 'Atualizar';

  @override
  String get commonStatus => 'Status';

  @override
  String get commonActions => 'Ações';

  @override
  String get commonNotes => 'Observações';

  @override
  String get commonOptional => 'Opcional';

  @override
  String get commonRequired => 'Obrigatório';

  @override
  String get commonYes => 'Sim';

  @override
  String get commonNo => 'Não';

  @override
  String get commonSuccess => 'Operação realizada com sucesso';

  @override
  String get commonError => 'Ocorreu um erro';

  @override
  String get commonWarning => 'Atenção';

  @override
  String get commonUnit => 'un';

  @override
  String get commonViewDetails => 'Ver Detalhes';

  @override
  String get statusOnline => 'Conectado';

  @override
  String get statusOffline => 'Desconectado';

  @override
  String get statusPaired => 'Pareado';

  @override
  String get statusUnpaired => 'Não Pareado';

  @override
  String get serverUrlLabel => 'URL do Servidor';

  @override
  String get fingerprintLabel => 'Fingerprint TLS';

  @override
  String get moduleProducts => 'Produtos & Insumos';

  @override
  String get moduleBasketTypes => 'Tipos de Cestas';

  @override
  String get modulePurchases => 'Entrada de Compras';

  @override
  String get moduleProduction => 'Ordens de Produção';

  @override
  String get moduleAssembly => 'Montar Cestas';

  @override
  String get moduleInventorySummary => 'Posição de Estoque';

  @override
  String get moduleInventoryMovements => 'Histórico de Movimentações';

  @override
  String get moduleSettings => 'Configurações';

  @override
  String get modulePairing => 'Pareamento de Dispositivo';

  @override
  String get productsTitle => 'Produtos e Insumos';

  @override
  String get productNew => 'Novo Produto';

  @override
  String get productEdit => 'Editar Produto';

  @override
  String get productName => 'Nome do Produto';

  @override
  String get productCategory => 'Categoria';

  @override
  String get productBaseUnit => 'Unidade Base';

  @override
  String get productCostPrice => 'Preço de Custo';

  @override
  String get productMinStock => 'Estoque Mínimo';

  @override
  String get productActive => 'Ativo';

  @override
  String get productInactive => 'Inativo';

  @override
  String get productPackagings => 'Embalagens / Apresentações';

  @override
  String get packagingNew => 'Nova Embalagem';

  @override
  String get packagingName => 'Nome da Embalagem';

  @override
  String get packagingBarcode => 'Código de Barras';

  @override
  String get packagingMultiplier => 'Fator Multiplicador';

  @override
  String get packagingUnit => 'Unidade de Embalagem';

  @override
  String get basketTypesTitle => 'Tipos de Cestas';

  @override
  String get basketTypeNew => 'Novo Tipo de Cesta';

  @override
  String get basketTypeEdit => 'Editar Tipo de Cesta';

  @override
  String get basketTypeCode => 'Código da Cesta';

  @override
  String get basketTypeName => 'Nome da Cesta';

  @override
  String get basketTypeAllowsCustom => 'Permite Personalização';

  @override
  String get recipesTitle => 'Ficha Técnica / Receita';

  @override
  String get recipeVersionLabel => 'Versão da Receita';

  @override
  String get recipeAddIngredient => 'Adicionar Insumo';

  @override
  String get recipeQuantityPerBasket => 'Quantidade por Cesta';

  @override
  String get recipeSection => 'Seção do Insumo';

  @override
  String get purchasesTitle => 'Entrada de Compras';

  @override
  String get purchaseNew => 'Registrar Compra';

  @override
  String get purchaseInvoiceNumber => 'Número da NF';

  @override
  String get purchaseSupplier => 'Fornecedor';

  @override
  String get purchaseDate => 'Data da Compra';

  @override
  String get purchaseItems => 'Itens da Compra';

  @override
  String get purchasePackagesCount => 'Qtd. Embalagens';

  @override
  String get purchaseUnitCost => 'Preço Unitário';

  @override
  String get purchaseTotalCost => 'Custo Total';

  @override
  String get productionBatchesTitle => 'Lotes de Produção';

  @override
  String get productionBatchNew => 'Nova Montagem de Cestas';

  @override
  String productionBatchNumber(int number) {
    return 'Lote #$number';
  }

  @override
  String get productionQuantityProduced => 'Qtd. Produzida';

  @override
  String get productionQuantityDisassembled => 'Qtd. Desmontada';

  @override
  String get productionCurrentStock => 'Saldo em Estoque';

  @override
  String get productionUnitCost => 'Custo Unitário';

  @override
  String get productionTotalCost => 'Custo Total do Lote';

  @override
  String get productionStatusConfirmed => 'Confirmado';

  @override
  String get productionStatusDisassembled => 'Desmontado';

  @override
  String get productionStatusCanceled => 'Cancelado';

  @override
  String get productionDirectSale => 'Venda Direta';

  @override
  String get productionCustom => 'Cesta Personalizada';

  @override
  String productionDisassembleTitle(int number) {
    return 'Desmontar Lote #$number';
  }

  @override
  String get productionDisassembleConfirm => 'Confirmar Desmontagem';

  @override
  String get productionDisassembleQtyLabel => 'Qtd. a Desmontar';

  @override
  String get productionDisassembleReasonLabel => 'Motivo da Desmontagem';

  @override
  String get productionDisassembleReasonHint =>
      'Ex: Avaria em embalagem, readequação';

  @override
  String get productionDisassembleTriageTitle => 'Triagem Física dos Insumos';

  @override
  String get productionDisassembleAllIntact => '100% Intacto (Sem Avarias)';

  @override
  String productionIntactQtyLabel(String unit) {
    return 'Intacto ($unit)';
  }

  @override
  String productionLossQtyLabel(String unit) {
    return 'Perda/Avaria ($unit)';
  }

  @override
  String get productionLossReasonLabel => 'Motivo da Perda';

  @override
  String get productionDisassembleDescription =>
      'A desmontagem realiza triagem física: itens intactos retornam ao estoque e avarias são registradas como perda sem inflar o estoque fisicamente.';

  @override
  String get productionDisassembledSuccess => 'Lote desmontado com sucesso!';

  @override
  String get productionBatchSearchHint =>
      'Buscar por lote (#1), tipo ou observações...';

  @override
  String get productionBatchFilterAllStatus => 'Todos os Status';

  @override
  String get productionBatchFilterConfirmed => 'Confirmados';

  @override
  String get productionBatchFilterDisassembled => 'Desmontados';

  @override
  String get productionBatchFilterAllTypes => 'Todos os Tipos';

  @override
  String get productionBatchFilterStandard => 'Cesta Padrão';

  @override
  String get productionBatchFilterCustom => 'Personalizada';

  @override
  String get productionBatchEmpty => 'Nenhum lote de produção encontrado.';

  @override
  String get productionBatchMountFirst => 'Montar Primeira Cesta';

  @override
  String productionBatchCancelTitle(int number) {
    return 'Estorno Total do Lote #$number';
  }

  @override
  String get productionBatchCancelDescription =>
      'Esta operação cancela a ordem de produção, deduz o saldo das cestas acabadas e retorna 100% dos insumos consumidos ao estoque fisicamente.\\n\\nRequer que todas as cestas acabadas estejam disponíveis em estoque.';

  @override
  String get productionBatchCancelReasonLabel => 'Motivo do Estorno';

  @override
  String get productionBatchCancelReasonHint =>
      'Ex: Ordem gerada em duplicidade';

  @override
  String get productionBatchCancelConfirm => 'Confirmar Estorno';

  @override
  String get productionBatchCancelSuccess => 'Lote estornado com sucesso!';

  @override
  String get productionBatchSnapshotTitle =>
      'Snapshot Imutável de Insumos Consumidos';

  @override
  String productionBatchSectionLabel(String section, String cost) {
    return 'Seção: $section | Custo un: $cost';
  }

  @override
  String productionBatchTotalItemCost(String cost) {
    return 'Total: $cost';
  }

  @override
  String get productionBatchDisassembleButton => 'Desmontar Lote';

  @override
  String get productionBatchCancelButton => 'Estorno Total';

  @override
  String get productionBatchDetailProduced => 'Quantidade Produzida';

  @override
  String get productionBatchDetailStock => 'Saldo Disponível';

  @override
  String get productionBatchDetailDisassembled => 'Quantidade Desmontada';

  @override
  String get productionBatchDetailUnitCost => 'Custo Unitário';

  @override
  String get productionBatchDetailTotalCost => 'Custo Total';

  @override
  String productionBatchDetailDate(String date) {
    return 'Data: $date';
  }

  @override
  String productionBatchDetailNotes(String notes) {
    return 'Observações: $notes';
  }

  @override
  String productionBatchDetailDisassembledAt(String date, String reason) {
    return 'Desmontado em: $date ($reason)';
  }

  @override
  String productionBatchDescriptionLabel(String description) {
    return 'Descrição: $description';
  }

  @override
  String productionBatchConsumedTotal(String quantity) {
    return 'Consumido total: $quantity';
  }

  @override
  String get validationInvalid => 'Inválido';

  @override
  String validationMinChars(int min) {
    return 'Mínimo de $min caracteres';
  }

  @override
  String get validationMustBePositive =>
      'A quantidade a desmontar deve ser maior que zero.';

  @override
  String validationInsufficientStockForDisassembly(int max) {
    return 'Saldo insuficiente para desmontagem: máximo permitido é de $max unidade(s).';
  }

  @override
  String get commonTryAgain => 'Tentar Novamente';

  @override
  String get homePhase2Header => 'Cadastros e Receitas';

  @override
  String get homeProductsDescription =>
      'Catálogo de itens, embalagens comerciais e estoque mínimo.';

  @override
  String get homeBasketTypesDescription =>
      'Tipos de cestas e versionamento imutável de receitas.';

  @override
  String get homePhase3Header => 'Estoque, Compras e Razão Contábil';

  @override
  String get homePurchasesDescription =>
      'Entrada de notas, conversão de fardos/caixas e cancelamento seguro.';

  @override
  String get homeInventorySummaryDescription =>
      'Posição consolidada e alerta de ruptura de estoque.';

  @override
  String get homeInventoryMovementsDescription =>
      'Histórico auditável e imutável de todas as movimentações.';

  @override
  String get homePhase4Header => 'Produção e Desmontagem';

  @override
  String get homeProductionBatchesDescription =>
      'Histórico de ordens, desmontagem com triagem e estorno total.';

  @override
  String get homeProductionAssemblyDescription =>
      'Simulação de viabilidade com CMPM e baixa atômica.';

  @override
  String get homeServerStatusTitle => 'Status do Servidor';

  @override
  String get homeCentralServer => 'Servidor Central';

  @override
  String get homeCheckConnection => 'Verificar Conexão';

  @override
  String get homePairDevice => 'Parear Dispositivo';

  @override
  String get inventorySummaryTitle => 'Posição de Estoque';

  @override
  String get inventoryMovementsTitle => 'Movimentações de Estoque';

  @override
  String get stockAdjustmentsTitle => 'Ajuste Manual de Estoque';

  @override
  String get stockAdjustmentNew => 'Novo Ajuste de Estoque';

  @override
  String get stockAdjustmentTypeIn => 'Sobra / Entrada (+)';

  @override
  String get stockAdjustmentTypeOut => 'Avaria / Saída (-)';

  @override
  String get stockAdjustmentReasonLabel => 'Justificativa do Ajuste';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get pairingTitle => 'Pareamento do Dispositivo';

  @override
  String get pairingPinLabel => 'PIN de Pareamento';

  @override
  String get pairingScanQr => 'Escanear QR Code';

  @override
  String get pairingDeviceName => 'Nome deste Dispositivo';

  @override
  String get errorInsufficientStock =>
      'Estoque insuficiente para realizar esta operação.';

  @override
  String get errorIdempotencyMismatch =>
      'Operação já executada com parâmetros divergentes.';

  @override
  String get errorRequestInProgress =>
      'Requisição em processamento concorrente. Aguarde alguns instantes.';

  @override
  String get errorUnauthorized =>
      'Dispositivo não autenticado. Realize o pareamento novamente.';

  @override
  String get errorDeviceRevoked =>
      'Dispositivo revogado pelo servidor central.';

  @override
  String get errorForbidden => 'Acesso não permitido.';

  @override
  String get errorNotFound => 'Registro ou recurso não encontrado.';

  @override
  String get errorConflict =>
      'Conflito de estado ou dados inconsistentes na operação.';

  @override
  String get errorValidationError =>
      'Dados enviados são inválidos. Verifique os campos preenchidos.';

  @override
  String get errorServer =>
      'Erro interno no servidor local. Tente novamente mais tarde.';

  @override
  String get errorConnectionFailed =>
      'Não foi possível conectar ao servidor local. Verifique sua rede e se o serviço está ativo.';

  @override
  String get errorUnexpected => 'Ocorreu um erro inesperado.';

  @override
  String get productsCatalogTitle => 'Catálogo de Produtos e Insumos';

  @override
  String get productSearchHint => 'Buscar por nome, SKU ou código de barras...';

  @override
  String get productEmpty =>
      'Nenhum produto encontrado com os filtros selecionados.';

  @override
  String get productInactivateTitle => 'Inativar Produto';

  @override
  String productInactivateConfirm(String name) {
    return 'Deseja inativar o produto \"$name\"?\n\nA exclusão física é proibida para preservar a integridade das transações anteriores. O produto deixará de aparecer em novas composições.';
  }

  @override
  String get productInactivateButton => 'Inativar';

  @override
  String get productInactivatedSuccess => 'Produto inativado com sucesso.';

  @override
  String productInactivateError(String error) {
    return 'Falha ao inativar produto: $error';
  }

  @override
  String productLoadError(String error) {
    return 'Erro ao carregar produtos: $error';
  }

  @override
  String get productCostPriceRef => 'Custo Ref.:';

  @override
  String get productSalePriceRef => 'Venda Ref.:';

  @override
  String productPackagingsCount(int count) {
    return 'Embalagens ($count)';
  }

  @override
  String productSkuLabel(String sku) {
    return 'SKU: $sku  ';
  }

  @override
  String productBarcodeLabel(String barcode) {
    return 'EAN: $barcode';
  }

  @override
  String get productFormNewTitle => 'Novo Produto / Insumo';

  @override
  String get productFormEditTitle => 'Editar Produto / Insumo';

  @override
  String get productFormNameLabel => 'Nome do Produto *';

  @override
  String get productFormNameHint => 'Ex: Arroz Agulhinha 5kg, Detergente 500ml';

  @override
  String get productFormNameRequired => 'Nome é obrigatório';

  @override
  String get productFormCategoryLabel => 'Categoria *';

  @override
  String get productFormBaseUnitLabel => 'Unidade Base no Estoque *';

  @override
  String get productFormSkuLabel => 'SKU / Código Interno';

  @override
  String get productFormSkuHint => 'Ex: ARR-5KG';

  @override
  String get productFormBarcodeLabel => 'Código de Barras / EAN';

  @override
  String get productFormBarcodeHint => 'Ex: 7891234567890';

  @override
  String productFormMinStockLabel(String unit) {
    return 'Estoque Mínimo ($unit)';
  }

  @override
  String get productFormMinStockInvalid => 'Mínimo deve ser >= 0';

  @override
  String get productFormCostPriceLabel => 'Preço de Custo (R\$)';

  @override
  String get productFormSalePriceLabel => 'Preço de Venda (R\$)';

  @override
  String get productFormNotesLabel => 'Observações';

  @override
  String get productFormStatusActive => 'Status Ativo';

  @override
  String get productFormStatusActiveSubtitle =>
      'Produtos inativos não podem ser incluídos em novas receitas ou compras.';

  @override
  String get productFormSaveCreate => 'Cadastrar Produto';

  @override
  String get productFormSaveUpdate => 'Atualizar Produto';

  @override
  String productFormSaveError(String error) {
    return 'Falha ao salvar produto: $error';
  }

  @override
  String get packagingsTitle => 'Embalagens Comerciais';

  @override
  String packagingProductSubtitle(String name, String unit) {
    return '$name (Base: $unit)';
  }

  @override
  String get packagingEmpty =>
      'Nenhuma embalagem comercial cadastrada. O estoque será movimentado diretamente na unidade base.';

  @override
  String packagingFactorLabel(int factor, String unit, String defaultTag) {
    return 'Fator: $factor $unit $defaultTag';
  }

  @override
  String get packagingDefaultTag => '• (Padrão)';

  @override
  String get packagingInactivateTooltip => 'Inativar';

  @override
  String get packagingAddButton => 'Adicionar Embalagem';

  @override
  String get packagingDialogNewTitle => 'Nova Embalagem Comercial';

  @override
  String get packagingDialogNameLabel => 'Nome da Embalagem *';

  @override
  String get packagingDialogNameHint => 'Ex: Fardo c/ 10 un, Caixa c/ 12';

  @override
  String packagingDialogQtyLabel(String unit) {
    return 'Quantidade na Unidade Base * ($unit)';
  }

  @override
  String get packagingDialogQtyHint => 'Ex: 10, 5000';

  @override
  String get packagingDialogDefaultSwitch => 'Embalagem Padrão de Compra';

  @override
  String get packagingDialogValidation =>
      'Informe nome e quantidade maior que 0.';

  @override
  String packagingDialogSaveError(String error) {
    return 'Falha ao cadastrar: $error';
  }

  @override
  String packagingDialogLoadError(String error) {
    return 'Erro ao carregar embalagens: $error';
  }

  @override
  String get basketTypesHeaderTitle => 'Tipos de Cestas e Receitas';

  @override
  String get basketTypeSearchHint => 'Buscar por nome ou código...';

  @override
  String get basketTypeEmpty => 'Nenhum tipo de cesta encontrado.';

  @override
  String get basketTypeInactivateTitle => 'Inativar Tipo de Cesta';

  @override
  String basketTypeInactivateConfirm(String name) {
    return 'Deseja inativar \"$name\"?\n\nA exclusão física é proibida para preservar histórico de vendas e montagens.';
  }

  @override
  String get basketTypeInactivateButton => 'Inativar';

  @override
  String get basketTypeInactivatedSuccess =>
      'Tipo de cesta inativado com sucesso.';

  @override
  String basketTypeInactivateError(String error) {
    return 'Falha ao inativar: $error';
  }

  @override
  String basketTypeLoadError(String error) {
    return 'Erro ao carregar tipos de cestas: $error';
  }

  @override
  String basketTypeRecipeActive(int version, int count) {
    return 'Receita Versão $version Ativa ($count itens)';
  }

  @override
  String get basketTypeRecipeNone => 'Sem receita cadastrada';

  @override
  String get basketTypeManageRecipe => 'Gerenciar Receita';

  @override
  String get basketTypeFormNewTitle => 'Novo Tipo de Cesta';

  @override
  String get basketTypeFormEditTitle => 'Editar Tipo de Cesta';

  @override
  String get basketTypeFormCodeLabel => 'Código da Cesta *';

  @override
  String get basketTypeFormCodeHint => 'Ex: BASICA-FAMILIA-01';

  @override
  String get basketTypeFormCodeRequired => 'Código é obrigatório';

  @override
  String get basketTypeFormNameLabel => 'Nome da Cesta *';

  @override
  String get basketTypeFormNameHint => 'Ex: Cesta Básica Familiar Completa';

  @override
  String get basketTypeFormNameRequired => 'Nome é obrigatório';

  @override
  String get basketTypeFormCategoryLabel => 'Categoria *';

  @override
  String get basketTypeFormPriceLabel => 'Preço de Venda Padrão (R\$)';

  @override
  String get basketTypeFormDescLabel => 'Descrição / Apresentação';

  @override
  String get basketTypeFormAllowsCustom => 'Permite Personalização';

  @override
  String get basketTypeFormAllowsCustomSubtitle =>
      'Permite que operadores alterem itens durante a montagem física.';

  @override
  String get basketTypeFormTracksStock => 'Controla Estoque de Cesta Acabada';

  @override
  String get basketTypeFormTracksStockSubtitle =>
      'Mantém saldo da cesta como produto acabado no inventário.';

  @override
  String get basketTypeFormStatusActive => 'Status Ativo';

  @override
  String get basketTypeFormSaveCreate => 'Cadastrar Tipo de Cesta';

  @override
  String get basketTypeFormSaveUpdate => 'Atualizar Tipo de Cesta';

  @override
  String basketTypeFormSaveError(String error) {
    return 'Falha ao salvar tipo de cesta: $error';
  }

  @override
  String recipeAppTitle(String name) {
    return 'Receita: $name';
  }

  @override
  String get recipeNewVersionButton => 'Nova Versão';

  @override
  String get recipeEmptyVersions =>
      'Nenhuma versão de receita cadastrada para esta cesta.';

  @override
  String get recipeCreateFirstVersion => 'Criar Primeira Versão';

  @override
  String get recipeImmutabilityBanner =>
      'Versionamento Imutável: As receitas gravadas nunca são sobrescritas. Para alterar componentes, clique em \"Nova Versão\". Montagens antigas mantêm fidelidade exata à composição da época.';

  @override
  String get recipeVersionDisplayed => 'Versão em exibição: ';

  @override
  String recipeVersionItem(int version) {
    return 'Versão $version';
  }

  @override
  String get recipeStatusActive => 'ATIVA';

  @override
  String get recipeStatusArchived => 'ARQUIVADA';

  @override
  String recipeNotesLabel(String notes) {
    return 'Notas da Versão: \"$notes\"';
  }

  @override
  String recipeSectionHeader(String section, int count) {
    return 'Seção: $section ($count itens)';
  }

  @override
  String get recipeDialogTitle => 'Nova Versão de Receita (Imutável)';

  @override
  String get recipeDialogSubtitle =>
      'Ao salvar, a composição atual será arquivada permanentemente e uma nova versão ativa será criada.';

  @override
  String get recipeDialogNotesLabel => 'Motivo da revisão / Notas da versão';

  @override
  String get recipeDialogNotesHint =>
      'Ex: Troca de fornecedor do arroz, ajuste sazonal';

  @override
  String recipeDialogItemsTitle(int count) {
    return 'Insumos da Receita ($count)';
  }

  @override
  String get recipeDialogAllProductsAdded =>
      'Todos os produtos ativos já estão na receita.';

  @override
  String get recipeDialogDuplicateItem =>
      'Este insumo já está na receita. Consolide a quantidade em um único item.';

  @override
  String get recipeDialogNoItems =>
      'Nenhum insumo adicionado. Clique em \"Adicionar Insumo\".';

  @override
  String recipeDialogQtyLabel(String unit) {
    return 'Qtd ($unit)';
  }

  @override
  String get recipeDialogValidationMinItems =>
      'A receita deve ter ao menos 1 item.';

  @override
  String get recipeDialogSaveButton => 'Salvar Nova Versão';

  @override
  String get recipeDialogSaveSuccess =>
      'Nova versão de receita criada com sucesso!';

  @override
  String recipeDialogSaveError(String error) {
    return 'Falha ao criar receita: $error';
  }

  @override
  String recipeLoadError(String error) {
    return 'Erro ao carregar receitas: $error';
  }

  @override
  String recipeLoadProductsError(String error) {
    return 'Erro ao carregar insumos: $error';
  }

  @override
  String get recipeNoActiveProducts =>
      'Nenhum insumo ativo encontrado. Cadastre produtos primeiro.';

  @override
  String purchaseNumberTitle(int number) {
    return 'Compra #$number';
  }

  @override
  String get purchaseFilterAll => 'Todos os Status';

  @override
  String get purchaseFilterConfirmed => 'Confirmadas';

  @override
  String get purchaseFilterDraft => 'Rascunho';

  @override
  String get purchaseFilterCanceled => 'Canceladas';

  @override
  String get purchaseSearchHint => 'Buscar por fornecedor, NF ou notas...';

  @override
  String get purchaseEmpty => 'Nenhuma compra registrada.';

  @override
  String purchaseCancelTitle(int number) {
    return 'Cancelar Compra #$number';
  }

  @override
  String get purchaseCancelWarning =>
      'Esta operação realizará o estorno contábil dos produtos no livro-razão. Se os produtos já foram consumidos e não houver saldo suficiente, a operação será rejeitada.';

  @override
  String get purchaseCancelReasonLabel => 'Motivo do Cancelamento';

  @override
  String get purchaseCancelReasonHint =>
      'Ex: Nota fiscal cancelada pelo fornecedor';

  @override
  String get purchaseCancelReasonRequired => 'Informe o motivo do cancelamento';

  @override
  String get purchaseCancelSuccess =>
      'Compra cancelada e estoque estornado com sucesso!';

  @override
  String purchaseCancelError(String error) {
    return 'Falha ao cancelar compra: $error';
  }

  @override
  String purchaseLoadError(String error) {
    return 'Erro ao carregar compras: $error';
  }

  @override
  String purchaseDetailItems(int count) {
    return 'Itens da Compra ($count)';
  }

  @override
  String purchaseDetailInvoice(String invoice) {
    return 'NF: $invoice';
  }

  @override
  String purchaseDetailSupplier(String supplier) {
    return 'Fornecedor: $supplier';
  }

  @override
  String purchaseDetailDate(String date) {
    return 'Data: $date';
  }

  @override
  String purchaseDetailTotal(String total) {
    return 'Total da Compra: $total';
  }

  @override
  String get purchaseStatusConfirmed => 'CONFIRMADA';

  @override
  String get purchaseStatusDraft => 'RASCUNHO';

  @override
  String get purchaseStatusCanceled => 'CANCELADA';

  @override
  String get purchaseCancelButton => 'Cancelar Compra';

  @override
  String get purchaseFormTitle => 'Nova Entrada de Compras';

  @override
  String get purchaseFormSupplierLabel => 'Fornecedor *';

  @override
  String get purchaseFormSupplierHint => 'Ex: Atacadão Distribuidora Ltda';

  @override
  String get purchaseFormSupplierRequired => 'Informe o fornecedor';

  @override
  String get purchaseFormInvoiceLabel => 'Número da NF';

  @override
  String get purchaseFormInvoiceHint => 'Ex: 123456';

  @override
  String get purchaseFormDateLabel => 'Data da Compra';

  @override
  String get purchaseFormNotesLabel => 'Observações';

  @override
  String get purchaseFormNotesHint =>
      'Ex: Prazo de pagamento 30 dias, lote promocional';

  @override
  String get purchaseFormItemsHeader => 'Itens da Compra';

  @override
  String get purchaseFormAddItem => 'Adicionar Item';

  @override
  String get purchaseFormProductLabel => 'Produto *';

  @override
  String get purchaseFormPackagingLabel => 'Embalagem';

  @override
  String purchaseFormBaseUnitPackaging(String unit) {
    return 'Unidade Base ($unit)';
  }

  @override
  String get purchaseFormQtyLabel => 'Qtd. Embalagens';

  @override
  String get purchaseFormQtyRequired => 'Informe a quantidade';

  @override
  String get purchaseFormUnitCostLabel => 'Preço Unitário (R\$)';

  @override
  String get purchaseFormUnitCostRequired => 'Informe o preço unitário';

  @override
  String purchaseFormTotalItem(String total) {
    return 'Subtotal: $total';
  }

  @override
  String purchaseFormTotalOverall(String total) {
    return 'Total Geral da Compra: $total';
  }

  @override
  String get purchaseFormSaveButton => 'Salvar Compra';

  @override
  String get purchaseFormSuccess => 'Compra registrada com sucesso!';

  @override
  String purchaseFormSaveError(String error) {
    return 'Falha ao registrar compra: $error';
  }

  @override
  String get purchaseFormAtLeastOneItem =>
      'Adicione ao menos um item à compra.';

  @override
  String purchaseFormConvertedStock(int qty, String unit) {
    return 'Equivalente em Estoque: $qty $unit';
  }

  @override
  String get inventorySummaryHeaderTitle => 'Saldo de Estoque em Tempo Real';

  @override
  String get inventorySummaryHistoryTooltip => 'Extrato do Razão Contábil';

  @override
  String get inventorySummaryAdjustmentTooltip => 'Ajuste Manual';

  @override
  String get inventorySummarySearchHint => 'Buscar por produto, categoria...';

  @override
  String get inventorySummaryBelowMinFilter => 'Apenas Abaixo do Mínimo';

  @override
  String get inventorySummaryEmpty =>
      'Nenhum item em estoque com os filtros selecionados.';

  @override
  String inventorySummaryCurrentStock(String quantity) {
    return 'Saldo Atual: $quantity';
  }

  @override
  String inventorySummaryMinStock(String quantity) {
    return 'Mínimo: $quantity';
  }

  @override
  String inventorySummaryAverageCost(String cost) {
    return 'Custo Médio Ponderado: $cost';
  }

  @override
  String inventorySummaryTotalValue(String value) {
    return 'Valor em Estoque: $value';
  }

  @override
  String get inventorySummaryAdjustmentSuccess =>
      'Ajuste de estoque registrado com sucesso!';

  @override
  String inventorySummaryLoadError(String error) {
    return 'Erro ao carregar saldo de estoque: $error';
  }

  @override
  String get inventorySummaryStatusOk => 'ESTOQUE REGULAR';

  @override
  String get inventorySummaryStatusAlert => 'ALERTA: ABAIXO DO MÍNIMO';

  @override
  String get inventoryMovementsHeaderTitle => 'Extrato do Razão Contábil';

  @override
  String get inventoryMovementsFilterAll => 'Todos os Tipos';

  @override
  String get inventoryMovementsFilterPurchase => 'Compras';

  @override
  String get inventoryMovementsFilterCancel => 'Estornos';

  @override
  String get inventoryMovementsFilterAdjustment => 'Ajustes Manuais';

  @override
  String get inventoryMovementsFilterAssembly => 'Produção / Montagem';

  @override
  String get inventoryMovementsEmpty =>
      'Nenhuma movimentação registrada no livro-razão.';

  @override
  String inventoryMovementDelta(String delta, String unit) {
    return 'Qtd: $delta $unit';
  }

  @override
  String inventoryMovementBalanceAfter(String balance, String unit) {
    return 'Saldo Após: $balance $unit';
  }

  @override
  String inventoryMovementUnitPrice(String price) {
    return 'Custo Unit: $price';
  }

  @override
  String inventoryMovementReason(String reason) {
    return 'Motivo: $reason';
  }

  @override
  String inventoryMovementsLoadError(String error) {
    return 'Erro ao carregar extrato de movimentações: $error';
  }

  @override
  String get movementPurchase => 'COMPRA';

  @override
  String get movementPurchaseCancel => 'ESTORNO COMPRA';

  @override
  String get movementAdjustmentIn => 'SOBRA / ENTRADA';

  @override
  String get movementAdjustmentOut => 'AVARIA / SAÍDA';

  @override
  String get movementLoss => 'PERDA / DESCARTE';

  @override
  String get movementAssemblyConsume => 'CONSUMO MONTAGEM';

  @override
  String get movementAssemblyProduce => 'CESTA MONTADA';

  @override
  String get movementSale => 'VENDA';

  @override
  String get stockAdjustmentDialogTitle => 'Ajuste Manual de Estoque';

  @override
  String get stockAdjustmentProductLabel => 'Produto *';

  @override
  String get stockAdjustmentTypeLabel => 'Tipo de Ajuste *';

  @override
  String get stockAdjustmentTypeLoss => 'Perda / Avaria (-)';

  @override
  String get stockAdjustmentTypeCount => 'Contagem Física (Balanço)';

  @override
  String stockAdjustmentQtyLabel(String unit) {
    return 'Quantidade ($unit)';
  }

  @override
  String get stockAdjustmentQtyRequired =>
      'Informe uma quantidade válida maior que 0';

  @override
  String get stockAdjustmentReasonHint =>
      'Ex: Quebra acidental no transporte, acerto de inventário';

  @override
  String get stockAdjustmentReasonRequired =>
      'A justificativa é obrigatória para auditoria contábil';

  @override
  String get stockAdjustmentConfirmButton => 'Confirmar Ajuste';

  @override
  String get stockAdjustmentSelectProductError => 'Selecione um produto.';

  @override
  String get assemblyHeaderTitle => 'Montagem de Cestas (Ordem de Produção)';

  @override
  String get assemblyTabStandard => 'Cesta Padrão';

  @override
  String get assemblyTabCustom => 'Cesta Personalizada';

  @override
  String get assemblyStandardBasketLabel => 'Tipo de Cesta *';

  @override
  String get assemblyStandardQtyLabel => 'Quantidade a Montar *';

  @override
  String get assemblyStandardQtyValidation =>
      'Informe uma quantidade válida maior que zero';

  @override
  String get assemblyStandardDirectSale =>
      'Venda Direta (Não adiciona ao estoque acabado)';

  @override
  String get assemblyStandardDirectSaleSubtitle =>
      'Baixa os insumos consumidos sem criar saldo da cesta montada no inventário.';

  @override
  String get assemblyStandardNotesLabel => 'Observações da Ordem';

  @override
  String get assemblyStandardNotesHint => 'Ex: Pedido especial cliente XPTO';

  @override
  String get assemblyFeasibilityTitle =>
      'Simulação de Viabilidade e Custo Médio (CMPM)';

  @override
  String get assemblyFeasibleOk => 'Estoque Suficiente para Montagem';

  @override
  String get assemblyFeasibleFail => 'Estoque Insuficiente para Montagem';

  @override
  String assemblyTotalCostPreview(String cost) {
    return 'Custo Total do Lote: $cost';
  }

  @override
  String assemblyUnitCostPreview(String cost) {
    return 'Custo Unitário da Cesta: $cost';
  }

  @override
  String get assemblyConfirmDialogTitle => 'Confirmar Montagem de Cestas';

  @override
  String assemblyConfirmDialogContent(int qty, String name) {
    return 'Deseja confirmar a montagem de $qty cesta(s) \"$name\"?\n\nOs insumos serão baixados e o lote de cestas acabadas será adicionado ao estoque imediatamente.';
  }

  @override
  String assemblyConfirmSuccess(int number, String cost) {
    return 'Lote #$number montado com sucesso! Custo unitário: $cost';
  }

  @override
  String get assemblySubmitStandard => 'Confirmar Montagem da Cesta Padrão';

  @override
  String get assemblySubmitCustom =>
      'Confirmar Montagem da Cesta Personalizada';

  @override
  String get assemblyCustomBaseBasket => 'Modelo Base da Cesta';

  @override
  String get assemblyCustomDescLabel => 'Descrição da Cesta Personalizada *';

  @override
  String get assemblyCustomDescHint =>
      'Ex: Cesta Natalina Especial para Empresa Alpha';

  @override
  String get assemblyCustomDescRequired =>
      'Informe a descrição da cesta personalizada';

  @override
  String assemblyCustomItemsHeader(int count) {
    return 'Composição Customizada de Insumos ($count)';
  }

  @override
  String get assemblyCustomAddItem => 'Adicionar Insumo';

  @override
  String get assemblyCustomQtyValidation => 'Quantidade inválida';

  @override
  String get pairingViewTitle => 'Pareamento do Dispositivo';

  @override
  String get pairingTabManual => 'Código PIN';

  @override
  String get pairingTabQr => 'Escanear QR';

  @override
  String get pairingPinValidation => 'O PIN deve conter exatamente 6 dígitos.';

  @override
  String get pairingUrlValidation => 'Informe o endereço IP/URL do servidor.';

  @override
  String pairingSuccess(String name) {
    return 'Dispositivo \"$name\" pareado com sucesso!';
  }

  @override
  String pairingError(String error) {
    return 'Erro ao parear: $error';
  }

  @override
  String get pairingServerUrlHint => 'Ex: https://192.168.1.100:8000';

  @override
  String get pairingPinHint => 'PIN de 6 dígitos exibido no servidor';

  @override
  String get pairingFingerprintHint =>
      'Fingerprint SHA256 do certificado (opcional se auto-assinado)';

  @override
  String get pairingDeviceNameHint => 'Ex: Tablet Depósito 01';

  @override
  String get pairingButton => 'Parear Dispositivo';

  @override
  String get pairingQrInstructions =>
      'Aponte a câmera para o QR Code de Pareamento exibido na tela do servidor central.';

  @override
  String get pairingScanning => 'Processando pareamento...';

  @override
  String get settingsHeaderTitle => 'Configurações de Rede e Dispositivo';

  @override
  String get settingsServerSection => 'Servidor Local';

  @override
  String get settingsServerUrlHint => 'Ex: https://192.168.1.100:8000';

  @override
  String get settingsFingerprintHint => 'Fingerprint SHA256 do certificado';

  @override
  String get settingsSaved => 'Configurações de rede salvas.';

  @override
  String get settingsDeviceInfoSection => 'Identificação do Dispositivo';

  @override
  String get settingsDeviceIdLabel => 'ID do Dispositivo (UUID)';

  @override
  String get settingsDeviceNameLabel => 'Nome do Dispositivo';

  @override
  String get settingsDeviceTokenLabel => 'Token de Autenticação';

  @override
  String get settingsDeviceTokenConfigured => 'Configurado e Ativo';

  @override
  String get settingsDeviceTokenMissing => 'Não autenticado';

  @override
  String get settingsSaveButton => 'Salvar Configurações';

  @override
  String get settingsUnpairButton => 'Desvincular Dispositivo';

  @override
  String get settingsUnpairTitle => 'Confirmar Desconexão';

  @override
  String get settingsUnpairContent =>
      'Deseja realmente desvincular este dispositivo do servidor local?';

  @override
  String get settingsUnpairConfirm => 'Desvincular';

  @override
  String get settingsUnpairedSuccess => 'Dispositivo desvinculado com sucesso.';

  @override
  String get settingsPairNewButton => 'Novo Pareamento';

  @override
  String get settingsGenerateQrTitle => 'Pareamento de Celulares / Tablets';

  @override
  String get settingsGenerateQrButton => 'Gerar QR Code para Celular';

  @override
  String get settingsQrDialogTitle => 'Conectar Celular / Tablet';

  @override
  String get settingsQrDialogInstructions =>
      'No celular Android, abra o aplicativo, toque em \'Parear Dispositivo\' > aba \'Escanear QR\' e aponte a câmera para a imagem abaixo:';

  @override
  String settingsPinExpiresLabel(String pin) {
    return 'PIN válido por 5 minutos: $pin';
  }

  @override
  String get settingsQrClose => 'Fechar';

  @override
  String get cameraPermissionDenied =>
      'Câmera aguardando permissão ou reinicialização.';

  @override
  String get cameraPermissionRequest => 'Ativar Câmera';

  @override
  String purchaseDetailUnitCost(String cost) {
    return 'Unit.: $cost';
  }

  @override
  String get purchaseStatusConfirmedWithStock => 'Confirmada (Aumenta Estoque)';

  @override
  String get purchaseStatusDraftWithoutStock =>
      'Rascunho (Sem movimentar estoque)';

  @override
  String purchaseItemIndex(int index) {
    return 'Item #$index';
  }

  @override
  String get stockAdjustmentQtyHint => 'Ex: 10';

  @override
  String get categoryFood => 'Alimentação';

  @override
  String get categoryCleaning => 'Limpeza';

  @override
  String get categoryMeat => 'Carnes & Frios';

  @override
  String get categoryHygiene => 'Higiene';

  @override
  String get categoryOthers => 'Outros';

  @override
  String get categoryInput => 'Insumo';

  @override
  String get categoryAll => 'Todas';

  @override
  String get categoryStandard => 'Padrão';

  @override
  String get categoryChristmas => 'Natalina';

  @override
  String get categoryCustom => 'Personalizada';

  @override
  String recipeUnknownIngredient(String id) {
    return 'Insumo ($id)';
  }

  @override
  String get productionBatchViewIngredients => 'Ver Insumos';

  @override
  String get productionDisassemble => 'Desmontar';

  @override
  String get productionDisassembleNoIngredients =>
      'Nenhum insumo registrado neste lote.';

  @override
  String get homeLocalConnectionInfo => 'Informações da Conexão Local';

  @override
  String get homeApiVersionLabel => 'Versão da API';

  @override
  String get homeDatabaseStatusLabel => 'Banco de Dados';

  @override
  String get homeTlsFingerprintLabel => 'Impressão Digital TLS (SHA-256)';

  @override
  String get homeNotConfigured => 'Não configurado';

  @override
  String get homeNotAvailable => 'Não disponível';

  @override
  String get homePending => 'Pendente';

  @override
  String get errorCustomerDocumentConflict =>
      'Já existe um cliente cadastrado com este documento (CPF/CNPJ).';

  @override
  String get errorCreditLimitExceeded =>
      'Limite de crédito do cliente excedido para esta operação.';

  @override
  String get homePhase5Header => 'Fase 5 — Vendas, Clientes e Recebíveis';

  @override
  String get homeCustomersDescription =>
      'Cadastro de clientes, limites de crédito e histórico financeiro';

  @override
  String get homeSalesDescription =>
      'Vendas diretas, montagem sob demanda e vendas a prazo';

  @override
  String get homeReceivablesDescription =>
      'Controle de fiados, vencimentos e recebimentos parciais';

  @override
  String get moduleCustomers => 'Clientes';

  @override
  String get moduleSales => 'Vendas de Cestas';

  @override
  String get moduleReceivables => 'Contas a Receber (Fiados)';

  @override
  String get customersTitle => 'Clientes';

  @override
  String get customerNew => 'Novo Cliente';

  @override
  String get customerEdit => 'Editar Cliente';

  @override
  String get customerName => 'Nome / Razão Social';

  @override
  String get customerDocument => 'CPF / CNPJ';

  @override
  String get customerPhone => 'Telefone';

  @override
  String get customerAddress => 'Endereço';

  @override
  String get customerCreditLimit => 'Limite de Crédito';

  @override
  String get customerCreditLimitUnlimited => 'Sem limite pré-definido';

  @override
  String get customerCurrentDebt => 'Dívida Atual';

  @override
  String get customerAvailableCredit => 'Crédito Disponível';

  @override
  String get customerStatement => 'Extrato do Cliente';

  @override
  String customerStatementTitle(String name) {
    return 'Extrato Financeiro — $name';
  }

  @override
  String get customerStatementEmpty =>
      'Nenhuma movimentação registrada para este cliente.';

  @override
  String get customerInactivate => 'Inativar Cliente';

  @override
  String customerInactivateConfirm(String name) {
    return 'Deseja realmente inativar o cliente \"$name\"?';
  }

  @override
  String get customerActive => 'Ativo';

  @override
  String get customerInactive => 'Inativo';

  @override
  String get customerSavedSuccess => 'Cliente salvo com sucesso.';

  @override
  String get customerInactivatedSuccess => 'Cliente inativado com sucesso.';

  @override
  String get customersEmpty => 'Nenhum cliente cadastrado.';

  @override
  String get customerNameHint => 'Ex: Supermercado São José';

  @override
  String get customerDocumentHint => 'CPF ou CNPJ';

  @override
  String get customerPhoneHint => '(11) 99999-9999';

  @override
  String get customerAddressHint => 'Rua, número, bairro, cidade';

  @override
  String get salesTitle => 'Vendas de Cestas';

  @override
  String get saleNew => 'Nova Venda';

  @override
  String saleNumber(int number) {
    return 'Venda #$number';
  }

  @override
  String get saleDate => 'Data da Venda';

  @override
  String get saleCustomer => 'Cliente';

  @override
  String get saleCustomerAnonymous => 'Consumidor Não Identificado (Balcão)';

  @override
  String get salePaymentMode => 'Forma de Pagamento';

  @override
  String get salePaymentModeCash => 'Dinheiro (À Vista)';

  @override
  String get salePaymentModePix => 'PIX';

  @override
  String get salePaymentModeCard => 'Cartão';

  @override
  String get salePaymentModeCredit => 'Venda a Prazo (Fiado)';

  @override
  String get saleDueDate => 'Data de Vencimento';

  @override
  String get saleDueDateSuggested => 'Sugerido 30 dias';

  @override
  String get saleItemsSection => 'Cestas e Composição';

  @override
  String get saleAddItem => 'Adicionar Cesta';

  @override
  String get saleBasketType => 'Tipo de Cesta';

  @override
  String get saleQuantity => 'Quantidade';

  @override
  String get saleUnitPrice => 'Preço Unitário';

  @override
  String get saleDiscount => 'Desconto';

  @override
  String get saleSubtotal => 'Subtotal';

  @override
  String get saleAssemblyMode => 'Origem da Cesta';

  @override
  String get saleAssemblyModeStock => 'Estoque Acabado';

  @override
  String get saleAssemblyModeDemand => 'Montar Imediatamente';

  @override
  String get saleGrossTotal => 'Total Bruto';

  @override
  String get saleTotalDiscount => 'Total de Descontos';

  @override
  String get saleNetTotal => 'Total Líquido';

  @override
  String get saleStatusConfirmed => 'Confirmada';

  @override
  String get saleStatusCanceled => 'Cancelada';

  @override
  String get salePaymentStatusPaid => 'Pago';

  @override
  String get salePaymentStatusPending => 'Pendente';

  @override
  String get salePaymentStatusPartial => 'Parcial';

  @override
  String get saleCancel => 'Cancelar Venda';

  @override
  String saleCancelConfirm(int number) {
    return 'Deseja realmente estornar a venda #$number?';
  }

  @override
  String get saleCancelReason => 'Motivo do cancelamento';

  @override
  String get saleCanceledSuccess =>
      'Venda cancelada e estoque estornado com sucesso.';

  @override
  String get saleCreatedSuccess => 'Venda registrada com sucesso.';

  @override
  String get saleCreditLimitAlertTitle => 'Limite de Crédito Excedido';

  @override
  String saleCreditLimitAlertMessage(String amount) {
    return 'O valor da venda excede o limite de crédito do cliente em $amount. Deseja autorizar a liberação manual desta venda?';
  }

  @override
  String get saleCreditLimitAuthorize => 'Autorizar e Concluir Venda';

  @override
  String saleStockAvailable(int qty) {
    return 'Saldo disponível: $qty';
  }

  @override
  String get salesEmpty => 'Nenhuma venda registrada.';

  @override
  String get saleCreditCustomerRequired =>
      'Vendas a prazo (fiado) exigem a seleção de um cliente cadastrado.';

  @override
  String get saleSelectBasketTypeRequired =>
      'Selecione a cesta para todos os itens.';

  @override
  String get saleQuantityMustBePositive =>
      'A quantidade deve ser maior que zero.';

  @override
  String saleInsufficientStockAlert(String name, int stock, int qty) {
    return 'Estoque insuficiente de cestas prontas para \"$name\". Saldo: $stock, Solicitado: $qty. Marque \"Montar Imediatamente\" para produzir na hora.';
  }

  @override
  String get saleAnonymousCustomerHint =>
      'Nome do cliente no balcão (opcional)';

  @override
  String saleCmvAndMargin(String cmv, String margin) {
    return 'CMV: $cmv | Margem: $margin';
  }

  @override
  String saleNotesPrefix(String notes) {
    return 'Obs: $notes';
  }

  @override
  String get receivablesTitle => 'Contas a Receber (Fiados)';

  @override
  String get receivablesSummaryTotal => 'Total a Receber';

  @override
  String get receivablesSummaryOpen => 'Títulos em Aberto';

  @override
  String get receivablesSummaryPartial => 'Pagamentos Parciais';

  @override
  String get receivablesSummaryPaid => 'Títulos Quitados';

  @override
  String get receivableOriginalAmount => 'Valor Original';

  @override
  String get receivablePaidAmount => 'Valor Pago';

  @override
  String get receivableRemainingBalance => 'Saldo Devedor';

  @override
  String receivableDueDateLabel(String date) {
    return 'Vencimento: $date';
  }

  @override
  String get receivableOverdue => 'Vencido';

  @override
  String get receivableRecordPayment => 'Receber Pagamento';

  @override
  String get receivablePaymentAmount => 'Valor a Receber';

  @override
  String get receivablePaymentMethod => 'Meio de Recebimento';

  @override
  String get receivablePaymentNotes => 'Observações do Pagamento';

  @override
  String get receivablePaymentSuccess => 'Recebimento registrado com sucesso.';

  @override
  String get receivablePaymentsHistory => 'Histórico de Amortizações';

  @override
  String get receivableNoPayments => 'Nenhum pagamento registrado ainda.';

  @override
  String get receivableStatusOpen => 'Em Aberto';

  @override
  String get receivableStatusPartial => 'Parcialmente Pago';

  @override
  String get receivableStatusPaid => 'Quitado';

  @override
  String get receivableStatusCanceled => 'Cancelado';

  @override
  String get receivablesEmpty => 'Nenhum título a receber encontrado.';

  @override
  String get receivablePaymentAmountMustBePositive =>
      'Informe um valor maior que zero.';

  @override
  String get receivablePaymentAmountExceedsBalance =>
      'Valor informado excede o saldo devedor.';

  @override
  String get homePhase6Header => 'Fase 6: Expedição, Conferência e Custódia';

  @override
  String get moduleDispatches => 'Saídas e Conferências';

  @override
  String get homeDispatchesDescription =>
      'Controle de saídas físicas, conferência e repasses';

  @override
  String get moduleResponsiblePersons => 'Pessoas Responsáveis';

  @override
  String get homeResponsiblePersonsDescription =>
      'Cadastro de entregadores, vendedores externos e motoristas';

  @override
  String get responsiblePersonsTitle => 'Pessoas Responsáveis';

  @override
  String get responsiblePersonNew => 'Novo Responsável';

  @override
  String get responsiblePersonEdit => 'Editar Responsável';

  @override
  String get responsiblePersonName => 'Nome';

  @override
  String get responsiblePersonPhone => 'Telefone / WhatsApp';

  @override
  String get responsiblePersonNotes => 'Observações';

  @override
  String get responsiblePersonActive => 'Ativo';

  @override
  String get responsiblePersonInactive => 'Inativo';

  @override
  String get responsiblePersonsEmpty =>
      'Nenhuma pessoa responsável cadastrada.';

  @override
  String get responsiblePersonCustodyTitle => 'Custódia Atual de Cestas';

  @override
  String responsiblePersonTotalInCustody(int qty) {
    return 'Total sob custódia: $qty cestas';
  }

  @override
  String get responsiblePersonNoCustody =>
      'Nenhuma cesta sob custódia no momento.';

  @override
  String get responsiblePersonSavedSuccess => 'Responsável salvo com sucesso.';

  @override
  String get dispatchesTitle => 'Saídas Físicas e Conferência';

  @override
  String get dispatchNew => 'Nova Saída de Cestas';

  @override
  String dispatchNumber(int number) {
    return 'Saída #$number';
  }

  @override
  String get dispatchResponsible => 'Responsável';

  @override
  String get dispatchDate => 'Data da Saída';

  @override
  String get dispatchTotalBaskets => 'Total de Cestas';

  @override
  String get dispatchTotalReference => 'Valor de Referência';

  @override
  String get dispatchStatusOpen => 'Aberta';

  @override
  String get dispatchStatusConcluded => 'Concluída';

  @override
  String get dispatchStatusPendingInvestigation => 'Sob Investigação';

  @override
  String get dispatchStatusCanceled => 'Cancelada';

  @override
  String get dispatchStatusResolved => 'Resolvido';

  @override
  String get dispatchesEmpty => 'Nenhuma saída física registrada.';

  @override
  String get dispatchCancel => 'Cancelar Saída';

  @override
  String dispatchCancelConfirm(int number) {
    return 'Deseja realmente cancelar a saída #$number?';
  }

  @override
  String get dispatchCancelReason => 'Motivo do cancelamento';

  @override
  String get dispatchCancelSuccess =>
      'Saída cancelada com sucesso. Cestas retornadas ao estoque da loja.';

  @override
  String get dispatchCreatedSuccess => 'Saída registrada com sucesso.';

  @override
  String get dispatchFormTitle => 'Registrar Saída Física';

  @override
  String get dispatchSelectResponsible => 'Selecione o Responsável';

  @override
  String get dispatchItemsTitle => 'Cestas a Retirar';

  @override
  String get dispatchAddItem => 'Adicionar Cesta';

  @override
  String get dispatchItemBasket => 'Tipo de Cesta';

  @override
  String get dispatchItemQuantity => 'Quantidade';

  @override
  String get dispatchItemUnitPrice => 'Preço de Referência';

  @override
  String get dispatchItemSubtotal => 'Subtotal';

  @override
  String get dispatchItemNotes => 'Personalizações / Observações';

  @override
  String dispatchAvailableStoreStock(int qty) {
    return 'Estoque loja: $qty';
  }

  @override
  String dispatchInsufficientStoreStock(String name, int stock, int qty) {
    return 'Estoque insuficiente na loja para \"$name\". Disponível: $stock, Solicitado: $qty.';
  }

  @override
  String get dispatchDuplicateBasketConsolidatedNotice =>
      'Cesta repetida: será consolidada automaticamente no despacho.';

  @override
  String get dispatchSubmit => 'Confirmar Saída Física';

  @override
  String conferenceTitle(int number) {
    return 'Conferência da Saída #$number';
  }

  @override
  String get conferenceScreenTitle => 'Conferência de Saída';

  @override
  String conferenceStatusLabel(String status) {
    return 'Status da Saída: $status';
  }

  @override
  String get conferencePhysicalEquationTitle =>
      'Equação Física de Custódia (4 Termos)';

  @override
  String conferenceDispatchedLabel(int qty) {
    return '1. Retiradas: $qty';
  }

  @override
  String conferenceSoldLabel(int qty) {
    return '2. Vendidas: $qty';
  }

  @override
  String conferenceReturnedLabel(int qty) {
    return '3. Devolvidas Intactas: $qty';
  }

  @override
  String conferenceLostLabel(int qty) {
    return '4. Avariadas / Perdidas: $qty';
  }

  @override
  String conferenceCustodyRemainingLabel(int qty) {
    return 'Em Trânsito / Custódia: $qty';
  }

  @override
  String conferenceDiscrepancyLabel(int qty) {
    return 'Divergência Física: $qty cestas';
  }

  @override
  String get conferencePhysicalEquationBalanced =>
      'Equação Física Bateu (Sem divergências)';

  @override
  String get conferencePhysicalEquationDivergent =>
      'Divergência Física Detectada!';

  @override
  String get conferenceFinancialTitle =>
      'Controle Financeiro de Rota e Repasses';

  @override
  String conferenceExpectedCashLabel(String amount) {
    return 'Dinheiro em Mãos Esperado: $amount';
  }

  @override
  String conferenceActualRepaidLabel(String amount) {
    return 'Repasses Realizados: $amount';
  }

  @override
  String conferencePendingCashLabel(String amount) {
    return 'Saldo a Repassar: $amount';
  }

  @override
  String conferenceCashSalesLabel(String amount) {
    return 'Vendas à Vista (Dinheiro): $amount';
  }

  @override
  String conferenceDirectCompanyLabel(String amount) {
    return 'Pix / Cartão Direto à Empresa: $amount';
  }

  @override
  String conferenceCreditSalesLabel(String amount) {
    return 'Vendas a Prazo (Fiado na rota): $amount';
  }

  @override
  String conferenceDebtCollectedLabel(String amount) {
    return 'Cobrança de Fiados em Rota: $amount';
  }

  @override
  String conferenceExpensesLabel(String amount) {
    return 'Despesas Autorizadas Abatidas: $amount';
  }

  @override
  String get conferenceFinancialDivergent =>
      'Divergência Financeira Detectada!';

  @override
  String get conferenceFinancialBalanced =>
      'Financeiro Bateu (Repasse integral)';

  @override
  String get conferenceDirectNotice =>
      '* Pix e cartões recebidos diretamente na conta da empresa NÃO são devidos pelo motorista/entregador.';

  @override
  String get conferenceExpenseExceedsNotice =>
      'As despesas autorizadas superaram as vendas em dinheiro da rota. Saldo credor ao entregador / ressarcimento pela empresa.';

  @override
  String get conferenceActionReturn => 'Devolução Intacta';

  @override
  String get conferenceActionLoss => 'Avaria / Perda';

  @override
  String get conferenceActionExpense => 'Despesa Autorizada';

  @override
  String get conferenceActionRepayment => 'Repasse de Dinheiro';

  @override
  String get conferenceActionSettle => 'Concluir Acerto / Fechamento';

  @override
  String get conferenceActionInvestigation => 'Documentar Investigação';

  @override
  String get conferenceSettledSuccess => 'Conferência registrada com sucesso.';

  @override
  String get conferenceInvestigationUpdatedSuccess =>
      'Notas de investigação atualizadas com sucesso.';

  @override
  String get conferenceReturnsListTitle => 'Devoluções de Cestas Intactas';

  @override
  String get conferenceLossesListTitle => 'Avarias e Perdas Físicas';

  @override
  String get conferenceExpensesListTitle => 'Despesas Autorizadas';

  @override
  String get conferenceRepaymentsListTitle =>
      'Repasses Financeiros Registrados';

  @override
  String get conferenceNoReturns => 'Nenhuma devolução intacta registrada.';

  @override
  String get conferenceNoLosses => 'Nenhuma avaria ou perda registrada.';

  @override
  String get conferenceNoExpenses => 'Nenhuma despesa autorizada registrada.';

  @override
  String get conferenceNoRepayments => 'Nenhum repasse de dinheiro registrado.';

  @override
  String get dialogReturnTitle => 'Registrar Devolução Intacta';

  @override
  String get dialogReturnQty => 'Quantidade Devolvida';

  @override
  String get dialogReturnNotes => 'Observações';

  @override
  String get dialogLossTitle => 'Registrar Avaria ou Perda';

  @override
  String get dialogLossQty => 'Quantidade Avariada/Perdida';

  @override
  String get dialogLossReason => 'Justificativa Obrigatória da Perda';

  @override
  String get dialogLossReasonRequired =>
      'A justificativa da perda é obrigatória (mínimo 3 caracteres).';

  @override
  String get dialogExpenseTitle => 'Registrar Despesa Autorizada';

  @override
  String get dialogExpenseAmount => 'Valor da Despesa';

  @override
  String get dialogExpenseDesc => 'Descrição (ex: Combustível, Borracharia)';

  @override
  String get dialogExpenseReceipt => 'Nº do Comprovante / Cupom';

  @override
  String get dialogExpenseAuthorizedBy => 'Autorizado por';

  @override
  String get dialogRepaymentTitle => 'Registrar Repasse Financeiro';

  @override
  String get dialogRepaymentAmount => 'Valor Repassado';

  @override
  String get dialogRepaymentMethod => 'Forma do Repasse';

  @override
  String get dialogRepaymentReceivedBy => 'Recebido na Empresa por';

  @override
  String get dialogRepaymentNotes => 'Observações';

  @override
  String get dialogSettleTitle => 'Fechamento Operacional / Acerto';

  @override
  String get dialogSettleAuditedBy => 'Auditor / Responsável pelo Fechamento';

  @override
  String get dialogSettleAuditedByRequired =>
      'Informe o nome do responsável pelo fechamento.';

  @override
  String get dialogSettleNotes => 'Observações do Fechamento';

  @override
  String get dialogSettleWarningDivergent =>
      'Atenção: Existem divergências físicas ou financeiras. O fechamento será registrado como SOB INVESTIGAÇÃO.';

  @override
  String get dialogSettleInvestigationNotes => 'Notas Iniciais da Investigação';

  @override
  String get dialogInvestigationTitle => 'Investigação de Divergências';

  @override
  String get dialogInvestigationNotes =>
      'Parecer da Investigação / Justificativas';

  @override
  String get dialogInvestigationMarkResolved =>
      'Marcar como Resolvido (Divergências apuradas/justificadas)';

  @override
  String get dialogInvestigationSave => 'Salvar Parecer';

  @override
  String get saleModeLabel => 'Modalidade da Venda';

  @override
  String get saleModeDirectStore => 'Balcão / Loja';

  @override
  String get saleModeCommercialRoute => 'Rota / Venda Externa';

  @override
  String get saleRouteSelectDispatch => 'Vincular à Saída / Rota Ativa';

  @override
  String get saleRouteNoDispatches =>
      'Nenhuma saída aberta disponível para este responsável.';

  @override
  String get saleRouteResponsibleLabel => 'Responsável pela Rota';

  @override
  String saleCustodyStockAvailable(int qty) {
    return 'Saldo sob custódia: $qty';
  }

  @override
  String get homePhase7Header => 'Fase 7: Gestão Financeira & Tesouraria';

  @override
  String get modulePayables => 'Contas a Pagar';

  @override
  String get homePayablesDescription =>
      'Boletos, cheques, empréstimos, fornecedores e parcelamentos';

  @override
  String get moduleTreasury => 'Tesouraria & Livro-Caixa';

  @override
  String get homeTreasuryDescription =>
      'Caixa físico, contas bancárias, transferências e conciliação';

  @override
  String get payablesTitle => 'Contas a Pagar';

  @override
  String get payablesNew => 'Nova Obrigação a Pagar';

  @override
  String get payableDescription => 'Descrição';

  @override
  String get payableBeneficiary => 'Favorecido / Fornecedor';

  @override
  String get payableCategory => 'Categoria';

  @override
  String get payableNature => 'Natureza';

  @override
  String get payableNatureBusiness => 'Operacional (Empresa)';

  @override
  String get payableNaturePersonal => 'Retirada Particular (Sócios)';

  @override
  String get payableOriginalAmount => 'Valor Nominal';

  @override
  String get payablePaidAmount => 'Valor Pago';

  @override
  String get payableBalance => 'Saldo Devedor';

  @override
  String get payableDueDate => 'Vencimento';

  @override
  String get payablePaymentMethod => 'Forma de Pagamento';

  @override
  String get payableStatus => 'Situação';

  @override
  String get payableStatusOpen => 'Em Aberto';

  @override
  String get payableStatusPartial => 'Parcialmente Pago';

  @override
  String get payableStatusPaid => 'Quitado';

  @override
  String get payableStatusCanceled => 'Cancelado';

  @override
  String get payableOverdue => 'Vencido';

  @override
  String payableInstallment(int current, int total) {
    return 'Parcela $current de $total';
  }

  @override
  String get payableRecurrent => 'Despesa Recorrente';

  @override
  String get payableRecurrenceMonthly => 'Mensal';

  @override
  String get payableRecurrenceWeekly => 'Semanal';

  @override
  String get payableRecurrenceYearly => 'Anual';

  @override
  String get payableTotalInstallments => 'Total de Parcelas';

  @override
  String get payablePaymentAction => 'Pagar / Amortizar';

  @override
  String get payableHistoryAction => 'Histórico de Pagamentos';

  @override
  String get payableCancelAction => 'Cancelar Obrigação';

  @override
  String get payableCancelReason => 'Motivo do cancelamento';

  @override
  String get payableCancelConfirm => 'Confirmar cancelamento do título';

  @override
  String get payablePaymentSuccess => 'Pagamento registrado com sucesso';

  @override
  String get payableCancelSuccess => 'Título cancelado com sucesso';

  @override
  String get payableReversePaymentSuccess => 'Pagamento estornado com sucesso';

  @override
  String get payablePaymentAmountExceedsBalance =>
      'O valor informado excede o saldo devedor.';

  @override
  String get payablePaymentAmountMustBePositive =>
      'O valor do pagamento deve ser maior que zero.';

  @override
  String get payableSelectAccount => 'Conta Financeira de Saída';

  @override
  String get payableNoPayables => 'Nenhuma obrigação a pagar encontrada.';

  @override
  String get payableFilterMonth => 'Mês';

  @override
  String get payableFilterYear => 'Ano';

  @override
  String get treasuryTitle => 'Tesouraria & Conciliação';

  @override
  String get treasuryTabAccounts => 'Saldos & Contas';

  @override
  String get treasuryTabLedger => 'Livro-Caixa (Extrato)';

  @override
  String get treasuryTabSummary => 'Visão Gerencial';

  @override
  String get treasuryTotalAvailable => 'Saldo Disponível (Caixa e Bancos)';

  @override
  String get treasuryCashBalance => 'Caixa Físico da Loja';

  @override
  String get treasuryBankBalance => 'Contas Bancárias';

  @override
  String get treasuryRouteCashPending => 'Dinheiro em Rota (em trânsito)';

  @override
  String get treasuryProjectedNet => 'Saldo Líquido Projetado';

  @override
  String get treasuryOpenReceivables => 'A Receber (Fiados Pendentes)';

  @override
  String get treasuryOverdueReceivables => 'A Receber Vencidos';

  @override
  String get treasuryOpenPayables => 'A Pagar (Obrigações Abertas)';

  @override
  String get treasuryOverduePayables => 'A Pagar Vencidos';

  @override
  String get treasuryBusinessExpenses => 'Despesas Operacionais (Mês)';

  @override
  String get treasuryPersonalWithdrawals => 'Retiradas de Sócios (Mês)';

  @override
  String get treasuryNewAccount => 'Nova Conta Financeira';

  @override
  String get treasuryEditAccount => 'Editar Conta Financeira';

  @override
  String get treasuryAccountName => 'Nome da Conta';

  @override
  String get treasuryAccountType => 'Tipo de Conta';

  @override
  String get treasuryTypeCash => 'Caixa Físico';

  @override
  String get treasuryTypeBank => 'Conta Bancária';

  @override
  String get treasuryTypeOther => 'Outra Conta / Cofre';

  @override
  String get treasuryBankName => 'Instituição Financeira / Banco';

  @override
  String get treasuryAccountNumber => 'Agência e Conta';

  @override
  String get treasuryInitialBalance => 'Saldo Inicial de Abertura';

  @override
  String get treasuryIsDefault => 'Conta Padrão';

  @override
  String get treasuryTransferTitle => 'Transferência entre Contas';

  @override
  String get treasurySourceAccount => 'Conta de Origem (Saída)';

  @override
  String get treasuryDestinationAccount => 'Conta de Destino (Entrada)';

  @override
  String get treasuryTransferAmount => 'Valor da Transferência';

  @override
  String get treasuryTransferSuccess => 'Transferência realizada com sucesso';

  @override
  String get treasuryManualEntryTitle => 'Lançamento no Livro-Caixa';

  @override
  String get treasuryEntryType => 'Tipo de Lançamento';

  @override
  String get treasuryEntryCredit => 'Crédito (Entrada)';

  @override
  String get treasuryEntryDebit => 'Débito (Saída)';

  @override
  String get treasuryEntryCategory => 'Categoria';

  @override
  String get treasuryEntryDescription => 'Descrição do Lançamento';

  @override
  String get treasuryEntryAmount => 'Valor';

  @override
  String get treasuryEntrySuccess => 'Lançamento registrado com sucesso';

  @override
  String get treasuryNoEntries =>
      'Nenhuma movimentação registrada no livro-caixa.';

  @override
  String get treasuryNoAccounts => 'Nenhuma conta financeira cadastrada.';

  @override
  String get treasuryReversalBadge => 'ESTORNO';

  @override
  String get treasuryImmutableNote =>
      'Livro-Caixa imutável: todas as operações são estritamente append-only.';

  @override
  String get receivableRepassDirect => 'Direto na Empresa / Loja';

  @override
  String get receivableRepassPending =>
      'Pendente de Repasse (Dinheiro em Rota)';

  @override
  String get receivableRepassDone => 'Repassado e Liquidado';

  @override
  String get receivableReversePayment => 'Estornar Recebimento';

  @override
  String get receivableReverseReason =>
      'Justificativa do estorno do recebimento';

  @override
  String get receivableReverseSuccess => 'Recebimento estornado com sucesso';

  @override
  String get payableGenerateNextRecurrence => 'Gerar Próxima Recorrência';

  @override
  String get payableRecurrenceSuccess =>
      'Nova parcela de recorrência gerada com sucesso!';

  @override
  String get payableFilterPeriod => 'Período de Vencimento';

  @override
  String get payableFilterPeriodAll => 'Todos os períodos';

  @override
  String get receivableFilterPeriod => 'Período da Venda';

  @override
  String get receivableFilterDuePeriod => 'Período do Vencimento';

  @override
  String get receivableFilterCustomer => 'Cliente';

  @override
  String get receivableFilterBasketType => 'Cesta';

  @override
  String get receivableFilterMinValue => 'Valor Mínimo';

  @override
  String get receivableFilterMaxValue => 'Valor Máximo';

  @override
  String get receivableFilterAdvanced => 'Filtros Avançados';

  @override
  String get receivableFilterHideAdvanced => 'Ocultar Filtros';

  @override
  String get receivableFilterClear => 'Limpar Filtros';

  @override
  String get receivableFilterApply => 'Aplicar Filtros';

  @override
  String get homePhase8Header =>
      'Fase 8: Dashboard, Relatórios, Planilhas e Impressão';

  @override
  String get moduleDashboard => 'Dashboard Geral';

  @override
  String get homeDashboardDescription =>
      'Visão consolidada operacional, faturamento e livro-caixa';

  @override
  String get moduleReports => 'Relatórios & Planilhas';

  @override
  String get homeReportsDescription =>
      'Consultas analíticas, exportação CSV/XLSX e impressão PDF';

  @override
  String get moduleBlankForms => 'Formulários A4 & Impressão';

  @override
  String get homeBlankFormsDescription =>
      'Modelos em branco para prancheta e folhas preenchidas para auditoria';

  @override
  String get dashboardTitle => 'Dashboard Operacional e Financeiro';

  @override
  String get dashboardFilterToday => 'Hoje';

  @override
  String get dashboardFilterDate => 'Data Específica';

  @override
  String get dashboardFilterRange => 'Intervalo';

  @override
  String get dashboardFilterMonth => 'Mês';

  @override
  String get dashboardFilterYear => 'Ano';

  @override
  String get dashboardFilterAll => 'Todos';

  @override
  String get dashboardSectionProduction => 'Produção & Montagem';

  @override
  String get dashboardAssembledBaskets => 'Cestas Montadas';

  @override
  String get dashboardSectionSales => 'Vendas & Faturamento';

  @override
  String get dashboardSoldBaskets => 'Cestas Vendidas';

  @override
  String get dashboardTotalSold => 'Valor Total Vendido';

  @override
  String get dashboardSectionDispatches => 'Expedição & Rotas';

  @override
  String get dashboardDispatchedBaskets => 'Cestas em Saída';

  @override
  String get dashboardUnremittedCash => 'Repasses de Rota Pendentes';

  @override
  String get dashboardPendingDivergences => 'Divergências Pendentes';

  @override
  String get dashboardSectionInventory => 'Estoque & Alertas';

  @override
  String get dashboardLowStockAlert => 'Itens Abaixo do Mínimo';

  @override
  String get dashboardStockNormal => 'Estoque em Nível Regular';

  @override
  String get dashboardSectionFinancial => 'Financeiro & Tesouraria';

  @override
  String get dashboardOpenReceivables => 'A Receber (Em Aberto)';

  @override
  String get dashboardOverdueReceivables => 'A Receber Vencidos';

  @override
  String get dashboardEffectiveReceived => 'Recebimentos Efetivos';

  @override
  String get dashboardOpenPayables => 'A Pagar (Em Aberto)';

  @override
  String get dashboardOverduePayables => 'A Pagar Vencidos';

  @override
  String get dashboardEffectivePaid => 'Pagamentos Efetuados';

  @override
  String get dashboardCashInflow => 'Entradas de Caixa';

  @override
  String get dashboardCashOutflow => 'Saídas de Caixa';

  @override
  String get dashboardTreasuryBalance => 'Saldo Disponível (Tesouraria)';

  @override
  String get dashboardProjectedCash => 'Saldo de Caixa Projetado';

  @override
  String get dashboardProjectionNotice =>
      'Atenção: Valores projetados são estimativas futuras e NÃO constituem dinheiro disponível em caixa.';

  @override
  String get reportsTitle => 'Relatórios Gerenciais e Planilhas';

  @override
  String get reportSalesDispatches => 'Vendas e Saídas de Cestas';

  @override
  String get reportAssembly => 'Montagem e Produção de Cestas';

  @override
  String get reportPurchasesMovements => 'Compras e Movimentações do Razão';

  @override
  String get reportReceivables => 'Contas a Receber, Pagamentos e Quitações';

  @override
  String get reportPayables => 'Contas a Pagar, Vencimentos e Pagamentos';

  @override
  String get reportDispatchSettlements =>
      'Conferência de Saídas e Repasses de Rota';

  @override
  String get reportPhysicalInventory => 'Estoque Atual e Contagem Física';

  @override
  String get reportFinancialSummary =>
      'DRE Gerencial e Demonstrativo Financeiro';

  @override
  String get reportExportCsv => 'Exportar CSV';

  @override
  String get reportExportXlsx => 'Exportar XLSX';

  @override
  String get reportPrintPdf => 'Imprimir / PDF A4';

  @override
  String get reportEmpty =>
      'Nenhum registro encontrado para os filtros selecionados.';

  @override
  String get reportTotals => 'Totais Consolidados';

  @override
  String get blankFormsTitle => 'Formulários A4 para Impressão';

  @override
  String get blankFormsSubtitle =>
      'Modelos em branco para preenchimento manual à caneta e folhas para auditoria física';

  @override
  String get formTypePayments =>
      'Tabela de Pagamentos de Cestas (Fiados / Quitações)';

  @override
  String get formTypePayables => 'Tabela de Contas a Pagar e Vencimentos';

  @override
  String get formTypeDispatch => 'Folha de Conferência de Saídas e Custódia';

  @override
  String get formTypeInventory =>
      'Folha de Contagem Física (Auditoria / Balanço)';

  @override
  String get formModeBlank => 'Formulário em Branco (Para Caneta)';

  @override
  String get formModeFilled => 'Documento Preenchido (Auditoria Física)';

  @override
  String get formActionPrint => 'Visualizar e Imprimir A4';

  @override
  String get formActionDownloadXlsx => 'Baixar Modelo XLSX Vazio';

  @override
  String get formBlankNotice =>
      'Modelos formatados com linhas amplas (mínimo de 8 a 10 mm) para escrita manual confortável em prancheta.';

  @override
  String formXlsxDownloadSuccess(String filename) {
    return 'Planilha XLSX baixada com sucesso: $filename';
  }

  @override
  String formXlsxDownloadError(String error) {
    return 'Erro ao baixar planilha: $error';
  }

  @override
  String get printerLocating => 'Localizando impressoras instaladas...';

  @override
  String get printerSystemDefault => 'Padrão do Sistema';

  @override
  String get printerAvailable => 'Disponível';

  @override
  String get printerActionPrint => 'Imprimir';

  @override
  String reportExportSuccess(String format) {
    return 'Planilha $format exportada com sucesso!';
  }

  @override
  String reportExportError(String format, String error) {
    return 'Erro ao exportar $format: $error';
  }

  @override
  String commonSelectedDateLabel(String date) {
    return 'Data: $date';
  }

  @override
  String get commonChange => 'Alterar';

  @override
  String commonPeriodLabel(String start, String end) {
    return 'Período: $start até $end';
  }

  @override
  String commonMonthNumber(int month) {
    return 'Mês $month';
  }

  @override
  String get commonYearLabel => 'Ano:';

  @override
  String get reportPhysicalBelowMinOnly =>
      'Exibir apenas itens abaixo do estoque mínimo';

  @override
  String dashboardSelectedDate(String date) {
    return 'Data selecionada: $date';
  }

  @override
  String dashboardBatchesCount(int count) {
    return 'Lotes ($count)';
  }

  @override
  String get dashboardNoBatches => 'Nenhum lote montado no período.';

  @override
  String dashboardSalesCount(int count) {
    return 'Vendas ($count)';
  }

  @override
  String get dashboardNoSales => 'Nenhuma venda registrada no período.';

  @override
  String dashboardDispatchesCount(int count) {
    return 'Saídas ($count)';
  }

  @override
  String dashboardExaminePendingDivergences(int count) {
    return 'Examinar Divergências Pendentes ($count)';
  }

  @override
  String get dashboardNoDispatches => 'Nenhuma saída registrada no período.';

  @override
  String dashboardDispatchItemSubtitle(String date, int baskets) {
    return 'Data: $date | Cestas: $baskets un.';
  }

  @override
  String get dashboardNoRetainedValues =>
      'Nenhum valor retido por responsável no momento.';

  @override
  String dashboardResponsiblePhone(String phone) {
    return 'Tel: $phone';
  }

  @override
  String dashboardResponsibleDate(String date) {
    return 'Data: $date';
  }

  @override
  String get dashboardNoDivergences => 'Nenhuma divergência pendente.';

  @override
  String dashboardSettledAt(String date) {
    return 'Acerto em: $date';
  }

  @override
  String commonNotesPrefix(String notes) {
    return 'Obs: $notes';
  }

  @override
  String get dashboardStockColBasket => 'Cesta';

  @override
  String get dashboardStockColStore => 'Loja';

  @override
  String get dashboardStockColTransit => 'Trânsito';

  @override
  String get dashboardStockColTotal => 'Total';

  @override
  String get dashboardAllAboveMinStock =>
      'Todos os itens estão acima do estoque mínimo.';

  @override
  String dashboardItemSku(String sku) {
    return 'SKU: $sku';
  }

  @override
  String dashboardCashRecordsCount(int count) {
    return 'Caixa ($count)';
  }

  @override
  String dashboardProjectedInflow(String amount) {
    return 'Entradas Previstas: $amount';
  }

  @override
  String dashboardProjectedOutflow(String amount) {
    return 'Saídas Previstas: $amount';
  }

  @override
  String get dashboardNoCashRecords => 'Nenhum lançamento no período.';

  @override
  String get dashboardNoOpenReceivables => 'Nenhum título a receber em aberto.';

  @override
  String get dashboardNoOpenPayables => 'Nenhuma conta a pagar em aberto.';

  @override
  String get conferenceMethodCashHand => 'Dinheiro em Mãos';

  @override
  String get conferenceMethodPixSettled => 'PIX Repassado';

  @override
  String get conferenceMethodBankTransfer => 'Transferência Bancária';

  @override
  String commonObservationsPrefix(String notes) {
    return 'Observações: $notes';
  }

  @override
  String get payableCategorySupplier => 'Fornecedor';

  @override
  String get payableCategoryElectricity => 'Energia Elétrica';

  @override
  String get payableCategoryRent => 'Aluguel';

  @override
  String get payableCategoryFreight => 'Frete / Logística';

  @override
  String get payableCategoryFreightShort => 'Frete';

  @override
  String get payableCategoryMaintenance => 'Manutenção';

  @override
  String get payableCategoryLoan => 'Empréstimo';

  @override
  String get payableCategoryCreditCard => 'Cartão de Crédito';

  @override
  String get payableCategoryPartnerWithdrawal => 'Retirada Sócios';

  @override
  String get payableCategoryTaxes => 'Impostos / Taxas';

  @override
  String get payableCategoryTaxesShort => 'Impostos';

  @override
  String get payableCategoryOthers => 'Outros';

  @override
  String get payablePaymentMethodBoleto => 'Boleto';

  @override
  String get payablePaymentMethodPix => 'PIX';

  @override
  String get payablePaymentMethodTransfer => 'Transferência';

  @override
  String get payablePaymentMethodCheck => 'Cheque';

  @override
  String get payablePaymentMethodCard => 'Cartão de Crédito';

  @override
  String get payablePaymentMethodCash => 'Dinheiro';

  @override
  String get payablePaymentMethodOther => 'Outro';

  @override
  String get payableRecurrenceFrequency => 'Periodicidade';

  @override
  String get payableNoPaymentsYet => 'Nenhum pagamento efetuado até o momento.';

  @override
  String get payableRevertPaymentTitle => 'Estornar Pagamento';

  @override
  String get payableRevertPaymentReason => 'Justificativa do Estorno';

  @override
  String get payableConfirmCancelObligation =>
      'Tem certeza que deseja cancelar a obrigação?';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Fev';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Abr';

  @override
  String get monthMay => 'Mai';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Ago';

  @override
  String get monthSep => 'Set';

  @override
  String get monthOct => 'Out';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dez';

  @override
  String get filterAllOption => 'Todos';

  @override
  String get treasuryNeedTwoAccountsForTransfer =>
      'São necessárias ao menos 2 contas para realizar transferências.';

  @override
  String get treasuryAccountLabel => 'Conta Financeira';

  @override
  String get treasuryAccountFilterLabel => 'Conta';

  @override
  String get treasuryLaunchEntry => 'Lançamento';

  @override
  String get treasuryConsolidatedPosition => 'Posição Consolidada da Empresa';

  @override
  String treasuryCashPhysicalLabel(String amount) {
    return 'Caixa Físico: $amount';
  }

  @override
  String treasuryBankLabel(String amount) {
    return 'Bancos: $amount';
  }

  @override
  String get treasuryFormulaExplanation =>
      'Fórmula: Disponível + A Receber - A Pagar';

  @override
  String get treasuryFutureCommitmentsTitle => 'Compromissos Futuros & Fiados';

  @override
  String get treasuryCustodyCouriers => 'Em custódia de entregadores';

  @override
  String get treasuryExpenseSegregationTitle => 'Segregação de Despesas (Mês)';

  @override
  String get treasuryBusinessExpensesDesc => 'Gastos operacionais da atividade';

  @override
  String get treasuryPersonalWithdrawalsDesc =>
      'Não misturar com contas da empresa';

  @override
  String get treasuryCatCapitalContribution => 'Aporte de Capital';

  @override
  String get treasuryCatSalesRevenue => 'Receita de Vendas';

  @override
  String get treasuryCatCustomerReceipt => 'Recebimento de Cliente';

  @override
  String get treasuryCatOtherCredits => 'Outros Créditos';

  @override
  String get treasuryCatPartnerWithdrawal => 'Retirada de Sócios / Pró-labore';

  @override
  String get treasuryCatSupplierPayment => 'Pagamento Fornecedor';

  @override
  String get treasuryCatElectricity => 'Energia Elétrica';

  @override
  String get treasuryCatRent => 'Aluguel';

  @override
  String get treasuryCatFreightFuel => 'Frete / Combustível';

  @override
  String get treasuryCatMaintenance => 'Manutenção';

  @override
  String get treasuryCatOtherExpenses => 'Outras Despesas';

  @override
  String get treasuryMethodPix => 'PIX';

  @override
  String get treasuryMethodCash => 'Dinheiro';

  @override
  String get treasuryMethodTransfer => 'Transferência';

  @override
  String get treasuryMethodCard => 'Cartão';

  @override
  String get treasuryMethodOther => 'Outro';

  @override
  String receivablesBasketsPrefix(String summary) {
    return 'Cestas: $summary';
  }

  @override
  String payableConfirmCancelObligationNamed(String description) {
    return 'Tem certeza que deseja cancelar a obrigação \"$description\"?';
  }

  @override
  String get tooltipPrintSelectPrinter =>
      'Imprimir / Selecionar Impressora (Epson Wi-Fi)';

  @override
  String get tooltipShareSavePdf => 'Compartilhar / Salvar PDF';

  @override
  String get payableInstallmentsHelper => 'Dividir em N parcelas mensais';

  @override
  String get payableRevertPaymentTooltip => 'Estornar este pagamento';

  @override
  String get dispatchPhysicalNotesHint =>
      'Observações da saída física (opcional)';

  @override
  String get dispatchCustomizationHint =>
      'Ex: Cesta personalizada, lote específico';

  @override
  String get conferenceLossReasonHint =>
      'Ex: Caixa molhou na chuva durante entrega';

  @override
  String get conferenceReceivedByHint => 'Colaborador que conferiu e recebeu';

  @override
  String get conferenceAuditorNameHint => 'Nome do conferente / auditor';

  @override
  String get conferenceInitialJustificationHint =>
      'Justificativa inicial das divergências';

  @override
  String get conferenceInvestigationHint =>
      'Descreva a apuração, se foi justificado, perdas aceitas ou ressarcimento';

  @override
  String get cameraStarting => 'Iniciando leitor de câmera...';

  @override
  String get settingsPairDeviceSection => 'Conexão com o Servidor Local';

  @override
  String get settingsPairDeviceDesc =>
      'Escaneie o QR Code gerado na tela de Configurações do computador ou informe o PIN manualmente para conectar este celular.';

  @override
  String get settingsPairDeviceButton =>
      'Parear Dispositivo (Escanear QR / PIN)';

  @override
  String get settingsServerNetworkSection => 'Rede e Conexão';

  @override
  String get settingsGenerateQrDesc =>
      'Gere um QR Code neste computador para que celulares Android possam escanear e parear automaticamente sem digitar IP, PIN ou Fingerprint.';

  @override
  String get settingsStatusConnectedPaired => 'Conectado e Pareado com Sucesso';

  @override
  String get settingsStatusConnectedWaiting =>
      'Conectado (Aguardando Pareamento)';

  @override
  String get settingsStatusDisconnected => 'Servidor Local Desconectado';

  @override
  String get settingsStatusPairedSubtitle =>
      'Operações comerciais autenticadas ativas.';

  @override
  String get settingsStatusWaitingSubtitle =>
      'Pareie este dispositivo com o servidor para habilitar operações.';

  @override
  String get settingsQrManualTitle => 'Ou conecte manualmente no celular:';

  @override
  String get settingsQrServerUrlLabel => 'URL do Servidor:';

  @override
  String get settingsQrFingerprintLabel =>
      'Fingerprint TLS (Impressão Digital):';

  @override
  String get settingsQrPinLabel => 'PIN de Pareamento:';

  @override
  String get settingsCopiedToClipboard =>
      'Copiado para a área de transferência!';

  @override
  String get settingsFingerprintExplanation =>
      'O Fingerprint TLS é o código de segurança criptográfico gerado pelo servidor para garantir que seu celular está conectando diretamente no seu computador com HTTPS confiável.';

  @override
  String get settingsNetworkSectionDescWindows =>
      'Endereço local onde o servidor está operando neste computador.';

  @override
  String get settingsNetworkSectionDescAndroid =>
      'Endereço do servidor e certificado seguro para comunicação em rede local.';

  @override
  String get pairingCameraInitializeHint =>
      'Toque no botão abaixo para inicializar a captura da câmera:';

  @override
  String get purchasePaymentConditionsHeader => 'Condições de Pagamento';

  @override
  String get purchasePaymentStatusLabel => 'Situação do Pagamento';

  @override
  String get purchasePaymentStatusPaid => 'Pago / Liquidado';

  @override
  String get purchasePaymentStatusPending => 'Pendente / Em Aberto';

  @override
  String get purchasePaymentMethodLabel => 'Forma de Pagamento';

  @override
  String get purchasePaymentAmountDueLabel => 'Valor Devido / Total Financeiro';

  @override
  String get purchasePaymentDueDateLabel => 'Data de Vencimento';

  @override
  String get purchasePaymentDueDateRequired =>
      'A data de vencimento é obrigatória para compras pendentes.';

  @override
  String get purchasePaymentFinancialAccountLabel =>
      'Conta Financeira de Liquidação';

  @override
  String purchasePaymentPendingNotice(String date) {
    return 'Esta compra gerará uma obrigação em aberto no módulo de Contas a Pagar com vencimento em $date.';
  }

  @override
  String get purchasePaymentPaidNotice =>
      'O valor da compra será baixado imediatamente no livro-caixa da empresa.';

  @override
  String purchasePaymentDetailMethod(String method, String status) {
    return 'Pagamento: $method ($status)';
  }

  @override
  String purchasePaymentDetailDueDate(String date) {
    return 'Vencimento: $date';
  }

  @override
  String get commonSelect => 'Selecionar';

  @override
  String get backupSectionTitle => 'Backup e Segurança do Banco de Dados';

  @override
  String get backupSectionDesc =>
      'Gere cópias de segurança consistentes e verificadas do banco de dados (SQLite) para prevenir perdas de dados comerciais.';

  @override
  String get backupCreateButton => 'Gerar Backup Agora';

  @override
  String get backupCreating => 'Gerando e verificando backup...';

  @override
  String backupSuccessMsg(String filename) {
    return 'Backup gerado com sucesso: $filename';
  }

  @override
  String backupErrorMsg(String error) {
    return 'Falha ao gerar backup: $error';
  }

  @override
  String get backupListTitle => 'Backups Disponíveis no Servidor';

  @override
  String get backupEmptyList => 'Nenhum backup encontrado no servidor.';

  @override
  String get backupIntegrityOk => 'Integridade Verificada';

  @override
  String get backupRestoreButton => 'Restaurar';

  @override
  String get backupRestoreConfirmTitle => 'Restaurar este backup?';

  @override
  String backupRestoreConfirmBody(String filename) {
    return 'O banco de dados atual será substituído por $filename. Tudo o que foi lançado depois deste backup será perdido. Um backup de segurança do estado atual será criado automaticamente antes da restauração.';
  }

  @override
  String get backupRestoreConfirmAction => 'Sim, restaurar';

  @override
  String get backupRestoreCancel => 'Cancelar';

  @override
  String backupRestoreSuccessMsg(String safety) {
    return 'Backup restaurado. Backup de segurança criado: $safety. Reinicie o aplicativo para recarregar os dados.';
  }

  @override
  String backupRestoreErrorMsg(String error) {
    return 'Falha ao restaurar backup: $error';
  }
}
