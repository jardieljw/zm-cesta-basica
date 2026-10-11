class RecipeItem {
  final String id;
  final String recipeVersionId;
  final String productId;
  final String? productName;
  final String? productCategory;
  final String? productBaseUnit;
  final int quantityInBaseUnits;
  final String section;
  final bool isRequired;

  RecipeItem({
    required this.id,
    required this.recipeVersionId,
    required this.productId,
    this.productName,
    this.productCategory,
    this.productBaseUnit,
    required this.quantityInBaseUnits,
    required this.section,
    required this.isRequired,
  });

  factory RecipeItem.fromJson(Map<String, dynamic> json) {
    return RecipeItem(
      id: json['id'] as String,
      recipeVersionId: json['recipe_version_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String?,
      productCategory: json['product_category'] as String?,
      productBaseUnit: json['product_base_unit'] as String?,
      quantityInBaseUnits: json['quantity_in_base_units'] as int,
      section: json['section'] as String,
      isRequired: json['is_required'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity_in_base_units': quantityInBaseUnits,
      'section': section,
      'is_required': isRequired,
    };
  }
}

class RecipeVersion {
  final String id;
  final String basketTypeId;
  final int versionNumber;
  final String status;
  final DateTime createdAt;
  final String? notes;
  final List<RecipeItem> items;

  RecipeVersion({
    required this.id,
    required this.basketTypeId,
    required this.versionNumber,
    required this.status,
    required this.createdAt,
    this.notes,
    this.items = const [],
  });

  factory RecipeVersion.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List<dynamic>? ?? [];
    List<RecipeItem> itemsList = rawItems
        .map((it) => RecipeItem.fromJson(it as Map<String, dynamic>))
        .toList();

    return RecipeVersion(
      id: json['id'] as String,
      basketTypeId: json['basket_type_id'] as String,
      versionNumber: json['version_number'] as int,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      notes: json['notes'] as String?,
      items: itemsList,
    );
  }
}

class BasketType {
  final String id;
  final String code;
  final String name;
  final String? description;
  final String category;
  final int defaultPriceCents;
  final bool allowsCustomization;
  final bool tracksFinishedStock;
  final bool isActive;
  final RecipeVersion? activeRecipe;

  BasketType({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.category,
    required this.defaultPriceCents,
    required this.allowsCustomization,
    required this.tracksFinishedStock,
    required this.isActive,
    this.activeRecipe,
  });

  factory BasketType.fromJson(Map<String, dynamic> json) {
    RecipeVersion? recipe;
    if (json['active_recipe'] != null && json['active_recipe'] is Map<String, dynamic>) {
      recipe = RecipeVersion.fromJson(json['active_recipe'] as Map<String, dynamic>);
    }

    return BasketType(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String? ?? 'PADRAO',
      defaultPriceCents: json['default_price_cents'] as int? ?? 0,
      allowsCustomization: json['allows_customization'] as bool? ?? false,
      tracksFinishedStock: json['tracks_finished_stock'] as bool? ?? true,
      isActive: json['is_active'] as bool? ?? true,
      activeRecipe: recipe,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'description': description,
      'category': category,
      'default_price_cents': defaultPriceCents,
      'allows_customization': allowsCustomization,
      'tracks_finished_stock': tracksFinishedStock,
      'is_active': isActive,
    };
  }

  double get defaultPriceReais => defaultPriceCents / 100.0;
}
