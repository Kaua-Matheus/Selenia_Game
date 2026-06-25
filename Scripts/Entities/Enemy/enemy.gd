class_name Enemy
extends CharacterBody2D

# -- Nodes --
## -- Aim --
@onready var attack_hit_box: Area2D = $AttackHitBox

## --- AttackHitBox ---
var hitbox_offset: Vector2

# --- Player Target ---
var target: Player = null

# -- Move --
var distance_from_target: Vector2
var direction_for_target: Vector2
var distance_length_for_target: float


const SPEED = 300.0


func _ready():
	hitbox_offset = attack_hit_box.position
	attack_hit_box.monitoring = false
	_resolve_target()

func _physics_process(_delta: float) -> void:
	walk()
	move_and_slide()


func walk() -> void:
	if target:
		distance_from_target = target.global_position - global_position
		direction_for_target = distance_from_target.normalized()
		#distance_length_for_target = distance_from_target.length()
		
		attack_hit_box.position = direction_for_target * hitbox_offset.x
		velocity = SPEED * direction_for_target

func _resolve_target() -> void:
	var nodes := get_tree().get_nodes_in_group("Player")
	if nodes.is_empty():
		push_error("PlayerHud: Can't find Player in the scene.")
		return
	target = nodes[0] as Player
