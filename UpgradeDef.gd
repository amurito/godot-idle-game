extends Resource
class_name UpgradeDef

# Definición estática de una mejora — guardada como .tres
# No cambia en runtime, solo la lees una vez.

## ID único (e.g. "click", "auto", "trueque")
@export var id: String = ""

## Texto del botón
@export var label: String = ""

## Costo inicial
@export var base_cost: float = 10.0

## Factor de escala del costo por compra (e.g. 1.45)
@export var cost_scale: float = 1.45

## Valor que se agrega por compra (o que multiplica si is_multiplicative)
@export var gain: float = 1.0

## Si true, el efecto es multiplicativo sobre el valor base; si false, aditivo
@export var is_multiplicative: bool = false

## Valor inicial antes de cualquier compra
@export var base_value: float = 0.0

## ID de otra mejora que debe comprarse primero (vacío = siempre disponible)
@export var unlock_requires: String = ""

## Si true, solo se puede comprar una vez
@export var one_shot: bool = false
