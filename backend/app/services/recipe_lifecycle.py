"""Recipes stay protected only while operational dependencies remain."""
import uuid
from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from app.models.products import RecipeVersion, RecipeItem, Product, BasketType
from app.models.production import ProductionBatch
from app.services.basket_catalog import require_catalog_entry
from app.services.catalog_dependencies import recipe_blockers


def get_recipe(db, basket_id, number):
    recipe = db.execute(select(RecipeVersion).options(
        selectinload(RecipeVersion.items).selectinload(RecipeItem.product)
    ).where(RecipeVersion.basket_type_id == basket_id,
        RecipeVersion.version_number == number)).scalar_one_or_none()
    if not recipe:
        raise HTTPException(404, detail='Receita não encontrada.')
    return recipe


def check_recipe(db, recipe):
    blockers = recipe_blockers(db, recipe)
    return dict(can_modify=not blockers, blockers=blockers)


def require_editable(db, recipe):
    require_catalog_entry(db.get(BasketType, recipe.basket_type_id))
    check = check_recipe(db, recipe)
    if check['blockers']:
        raise HTTPException(409, detail=dict(error_code='RECIPE_IN_USE',
            message='Resolva as vendas ou montagens indicadas antes de alterar ou excluir esta receita.',
            **check))


def validate_items(db, data):
    seen = set()
    for item in data.items:
        product = db.get(Product, item.product_id)
        if not product or not product.is_active or product.removed_at is not None:
            raise HTTPException(409, detail='Escolha somente produtos disponíveis no catálogo.')
        if item.product_id in seen:
            raise HTTPException(422, detail='Um produto não pode aparecer duas vezes na mesma receita.')
        seen.add(item.product_id)


def mutate_recipe(db, basket_id, number, action, data=None):
    recipe = get_recipe(db, basket_id, number)
    if action == 'remove' and recipe.status == 'REMOVED':
        return dict(id=recipe.id, deleted=True)
    if recipe.status == 'REMOVED':
        raise HTTPException(409, detail='Esta receita foi excluída do catálogo.')
    if action in ('remove', 'edit'):
        require_editable(db, recipe)
    else:
        require_catalog_entry(db.get(BasketType, basket_id))
    if action == 'remove':
        # Historical batch links and frozen ingredient data stay addressable.
        recipe.status = 'REMOVED'
        db.flush()
        return dict(id=recipe.id, deleted=True)
    if action == 'activate':
        validate_items(db, type('Items', (), {'items': recipe.items})())
        for other in db.execute(select(RecipeVersion).where(
                RecipeVersion.basket_type_id == basket_id, RecipeVersion.status == 'ACTIVE')).scalars():
            other.status = 'ARCHIVED'
        recipe.status = 'ACTIVE'
    elif action == 'deactivate':
        recipe.status = 'ARCHIVED'
    elif action == 'edit':
        validate_items(db, data)
        if db.execute(select(ProductionBatch.id).where(ProductionBatch.recipe_version_id == recipe.id).limit(1)).first():
            # Even undone batches preserve their original recipe. Editing creates
            # a replacement version in the same type, and retires the old one.
            from sqlalchemy import func
            number = (db.scalar(select(func.max(RecipeVersion.version_number)).where(
                RecipeVersion.basket_type_id == basket_id)) or 0) + 1
            old_status = recipe.status
            recipe.status = 'REMOVED'
            recipe = RecipeVersion(id=str(uuid.uuid4()), basket_type_id=basket_id,
                version_number=number, status=old_status)
            db.add(recipe)
        else:
            recipe.items.clear()
            db.flush()
        recipe.notes = data.notes
        recipe.suggested_price_cents = data.suggested_price_cents
        for item in data.items:
            recipe.items.append(RecipeItem(id=str(uuid.uuid4()), **item.model_dump()))
    db.flush()
    return recipe
