class_name PlayerHud
extends CanvasLayer

# --- Player Target ---
var target: Player = null

# --- Nodes ---
@onready var health_bar: ProgressBar = $HBoxContainer/Status/HealthBar
@onready var stamina_bar: ProgressBar = $HBoxContainer/Status/StaminaBar
@onready var dash_cooldown_bar: ProgressBar = $HBoxContainer/Skills/Dash


func _ready() -> void:
	_resolve_target()


func _process(_delta: float) -> void:
	health_bar.value = target.health
	stamina_bar.value = target.stamina
	dash_cooldown_bar.value = target.dash_cooldown


func _resolve_target() -> void:
	var nodes := get_tree().get_nodes_in_group("Player")
	if nodes.is_empty():
		push_error("PlayerHud: Can't find Player in the scene.")
		return
	target = nodes[0] as Player
