class_name Player
extends CharacterBody2D


# -- Nodes --
## --- Animation ---
@onready var attack_animation: AnimatedSprite2D = $AttackHitBox/AttackAnimation
@onready var player_animation: AnimatedSprite2D = $PlayerAnimation

## --- HitBox ---
@onready var attack_hit_box: Area2D = $AttackHitBox
@onready var body_hit_box_shape: CollisionShape2D = $BodyHitBox/BodyHitBoxShape

## --- Collision Box ---
@onready var body_collision_shape: CollisionShape2D = $BodyCollisionShape


# -- Movement --
## -- Direction Vars --
var move_direction: Vector2
var mouse_direction: Vector2
var mouse_position: Vector2

# -- Attack --
## --- AttackHitBox ---
var hitbox_offset: Vector2

# -- Movement --
## --- Move Consts ---
const BASE_MOVE_SPEED: float = 600
const BASE_STAMINA: float = 100
const ACCELERATION: float = 300

## --- Move Vars ---
var move_speed: float = BASE_MOVE_SPEED


# -- Status --
## --- Const Status ---
const BASE_HEALTH: float = 100

## --- Var Status ---
var stamina: float = BASE_STAMINA
var health: float = BASE_HEALTH


# -- State Machine Declaration --
enum PlayerState { idle, walk, sprint, crouch, dash, attack, attacked, dead }
var current_state: PlayerState

# -- Dash --
var dash_timer: float = DASH_TIMER_BASE
var dash_speed: int = 700


# -- Cooldowns --
## --- Const Cooldowns ---
const DASH_COOLDOWN_BASE: float = 3.0
const DASH_TIMER_BASE: float = 0.2
#const INVENCIBILITY_COOLDOWN_BASE = 1

## --- Var Cooldowns ---
var dash_cooldown: float = 0.0


# -- Invencibility --
## --- Vars Invencibility ---
var is_invincible: bool = false


func _ready() -> void:
	# Idle State in Ready
	enter_idle_state()
	
	hitbox_offset = attack_hit_box.position


func _physics_process(delta: float) -> void:
	read_input()
	update_state(delta)
	update_cooldown(delta)
	move_and_slide()


# - State Machine -
## -- Enter State --
func enter_idle_state():
	current_state = PlayerState.idle
	attack_hit_box.monitoring = false
	switch_animation_attack()

func enter_walk_state():
	current_state = PlayerState.walk
	attack_hit_box.monitoring = false
	switch_animation_attack()

func enter_sprint_state():
	current_state = PlayerState.sprint
	attack_hit_box.monitoring = false
	switch_animation_attack()

func enter_dash_state():
	current_state = PlayerState.dash
	attack_hit_box.monitoring = false
	is_invincible = true
	switch_animation_attack()

func enter_crouch_state():
	current_state = PlayerState.crouch
	attack_hit_box.monitoring = false
	switch_animation_attack()

func enter_attack_state():
	current_state = PlayerState.attack
	attack_hit_box.monitoring = false
	switch_animation_attack()

func enter_attacked_state():
	current_state = PlayerState.attacked
	attack_hit_box.monitoring = false
	switch_animation_attack()

func enter_dead_state():
	current_state = PlayerState.dead
	attack_hit_box.monitoring = false
	switch_animation_attack()


## --- States ---
func idle_state(delta: float) -> void:
	move(delta)
	if stamina < BASE_STAMINA:
		stamina += delta * 20
	
	if Input.is_action_just_pressed("Crouch"):
		enter_crouch_state(); return
	if Input.is_action_just_pressed("Sprint"):
		enter_sprint_state(); return
	if velocity != Vector2.ZERO:
		enter_walk_state(); return
	if Input.get_action_strength("Dash") and dash_cooldown <= 0.0:
		enter_dash_state(); return
	if Input.is_action_just_pressed("Attack"):
		enter_attack_state();

func walk_state(delta: float) -> void:
	move(delta)
	if stamina < BASE_STAMINA:
		stamina += delta * 20
	
	if Input.is_action_just_pressed("Crouch"):
		enter_crouch_state(); return
	if Input.is_action_just_pressed("Sprint"):
		enter_sprint_state(); return
	if velocity == Vector2.ZERO:
		enter_idle_state(); return
	if Input.get_action_strength("Dash") and dash_cooldown <= 0.0:
		enter_dash_state(); return
	if Input.is_action_just_pressed("Attack"):
		enter_attack_state();

func sprint_state(delta: float):
	move(delta)
	move_speed = BASE_MOVE_SPEED * 1.5
	stamina -= delta * 20
	
	if Input.is_action_just_pressed("Attack"):
		move_speed = BASE_MOVE_SPEED
		enter_attack_state(); return
		
	if Input.is_action_just_released("Sprint") or stamina <= 0:
		move_speed = BASE_MOVE_SPEED
		if velocity == Vector2.ZERO:
			enter_idle_state(); return
		else:
			enter_walk_state(); return

func crouch_state(delta: float):
	move(delta)
	
	body_collision_shape.shape.size = Vector2(20, 20)
	body_hit_box_shape.shape.size = Vector2(20, 20)
	
	move_speed = BASE_MOVE_SPEED / 2
	
	if stamina < BASE_STAMINA:
		stamina += delta * 25

	if Input.is_action_just_pressed("Crouch"):
		body_collision_shape.shape.size = Vector2(20, 28)
		body_hit_box_shape.shape.size = Vector2(20, 28)
		move_speed = BASE_MOVE_SPEED
		body_collision_shape.shape.size = Vector2(20, 28)
		body_hit_box_shape.shape.size = Vector2(20, 28)
		if velocity == Vector2.ZERO:
			enter_idle_state(); return
		else:
			enter_walk_state(); return

func dash_state(delta: float) -> void:
	move(delta)
	velocity = mouse_direction * dash_speed
	dash_timer -= delta * 1
	
	if dash_timer <= 0:
		dash_timer = DASH_TIMER_BASE
		dash_cooldown = DASH_COOLDOWN_BASE
		is_invincible = false
		if move_direction == Vector2.ZERO:
			enter_idle_state(); return
		else:
			enter_walk_state(); return

func attack_state(delta: float) -> void:
	move(delta)
	update_hitbox_offset()
	if attack_animation.animation == "attack" and not attack_animation.is_playing():
		if velocity != Vector2.ZERO:
			if Input.is_action_pressed("Sprint"):
				enter_sprint_state(); return
			else:
				enter_walk_state(); return
		else:
			enter_idle_state(); return

func attacked_state(delta: float, amount: float) -> void:
	move(delta)
	if current_state == PlayerState.dead:
		return
	if is_invincible:
		return
		
	health = max(health - amount, 0)
	if health <= 0:
		enter_dead_state()

func dead_state() -> void:
	if player_animation.animation == "death" and not player_animation.is_playing():
		#get_tree().change_scene_to_file.call_deferred(GAME_OVER_SCENE)
		pass


## --- Update State Machine ---
func update_state(delta: float) -> void:
	match current_state:
		PlayerState.idle:    idle_state(delta);
		PlayerState.walk:    walk_state(delta);
		PlayerState.sprint:  sprint_state(delta);
		PlayerState.dash:    dash_state(delta);
		PlayerState.crouch:  crouch_state(delta);
		PlayerState.attack:  attack_state(delta);
		PlayerState.dead:    dead_state();


# --- Movement ---
func move(delta: float):
	velocity = velocity.move_toward(move_direction * ACCELERATION, move_speed * delta)

func read_input() -> void:
	update_direction()
	move_direction = Input.get_vector("Left", "Right", "Up", "Down")

func update_direction() -> void:
	update_hitbox_offset()
	#animation.flip_h = mouse_position.x < global_position.x
	return

func update_hitbox_offset() -> void:
	mouse_position = get_global_mouse_position()
	mouse_direction = (mouse_position - global_position).normalized()
	attack_hit_box.position = mouse_direction * hitbox_offset.x
	return

func update_cooldown(delta: float) -> void:
	match current_state:
		PlayerState.dash:
			return
		_:
			if dash_cooldown > 0:
				dash_cooldown -= delta * 1


# --- Attack ---
func switch_animation_attack() -> void:
	match current_state:
		PlayerState.attack:
			attack_animation.play("attack")
			attack_animation.look_at(mouse_position)
		_:
			attack_animation.play("aim")
			attack_animation.rotation = 0.0
