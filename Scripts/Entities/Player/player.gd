class_name Player
extends CharacterBody2D


# -- Nodes --
@onready var attack_hit_box: Area2D = $AttackHitBox
@onready var attack_animation: AnimatedSprite2D = $AttackHitBox/AttackAnimation
@onready var player_animation: AnimatedSprite2D = $PlayerAnimation

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
const BASE_MOVE_SPEED: float = 400
const BASE_STAMINA: float = 100

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
var dash_timer: float = 0.2
var dash_direction: Vector2 = Vector2.ZERO
var dash_speed: int = 700


# -- Cooldowns --
## --- Const Cooldowns ---
const DASH_COOLDOWN: float = 3.0

## --- Var Cooldowns ---
var dash_cooldown: float = 0.0


# -- Invencibility --
var is_invincible: bool = false


func _ready() -> void:
	# Idle State in Ready
	enter_idle_state()
	
	hitbox_offset = attack_hit_box.position


func _physics_process(delta: float) -> void:
	read_input()
	update_state(delta)
	move_and_slide()


# - State Machine -
## -- Enter State --
func enter_idle_state():
	switch_animation_attack()
	current_state = PlayerState.idle
	attack_hit_box.monitoring = false

func enter_walk_state():
	switch_animation_attack()
	current_state = PlayerState.walk
	attack_hit_box.monitoring = false

func enter_sprint_state():
	switch_animation_attack()
	current_state = PlayerState.sprint
	attack_hit_box.monitoring = false

func enter_dash_state():
	switch_animation_attack()
	current_state = PlayerState.dash
	attack_hit_box.monitoring = false

func enter_crouch_state():
	switch_animation_attack()
	current_state = PlayerState.crouch
	attack_hit_box.monitoring = false

func enter_attack_state():
	switch_animation_attack()
	current_state = PlayerState.attack
	attack_hit_box.monitoring = false

func enter_attacked_state():
	switch_animation_attack()
	current_state = PlayerState.attacked
	attack_hit_box.monitoring = false

func enter_dead_state():
	switch_animation_attack()
	current_state = PlayerState.dead
	attack_hit_box.monitoring = false


#func _input(event: InputEvent) -> void:
	#if event.get_action_strength("Crouch"):
		#print("Crouch button just pressed")

## --- States ---
func idle_state(delta: float) -> void:
	move()
	if stamina < BASE_STAMINA:
		stamina += delta * 20
	
	if Input.is_action_just_pressed("Crouch"):
		print("Apertado agachar Idle");
		enter_crouch_state(); return
	if Input.is_action_just_pressed("Sprint"):
		print("Correr no Walk");
		enter_sprint_state(); return
	if velocity != Vector2.ZERO:
		enter_walk_state(); return
	if Input.get_action_strength("Dash") and dash_cooldown <= 0.0:
		enter_dash_state(); return
	if Input.get_action_strength("Attack"):
		enter_attack_state();

func walk_state(delta: float) -> void:
	move()
	if stamina < BASE_STAMINA:
		stamina += delta * 20
	
	if Input.is_action_just_pressed("Crouch"):
		print("Apertado agachar Walk");
		enter_crouch_state(); return
	if Input.is_action_just_pressed("Sprint"):
		print("Correr no Walk");
		enter_sprint_state(); return
	if velocity == Vector2.ZERO:
		enter_idle_state(); return
	if Input.get_action_strength("Dash") and dash_cooldown <= 0.0:
		enter_dash_state(); return
	if Input.get_action_strength("Attack"):
		enter_attack_state();

func sprint_state(delta: float):
	move()
	move_speed = BASE_MOVE_SPEED * 1.5
	stamina -= delta * 20
	if Input.is_action_just_released("Sprint") or stamina <= 0:
		move_speed = BASE_MOVE_SPEED
		if velocity == Vector2.ZERO:
			enter_idle_state(); return
		else:
			enter_walk_state(); return

func crouch_state(delta: float):
	move()
	move_speed = BASE_MOVE_SPEED / 2
	if stamina < BASE_STAMINA:
		stamina += delta * 25

	if Input.is_action_just_pressed("Crouch"):
		move_speed = BASE_MOVE_SPEED
		if velocity == Vector2.ZERO:
			enter_idle_state(); return
		else:
			enter_walk_state(); return

func dash_state(delta: float) -> void:
	move()
	velocity = dash_direction * dash_speed
	dash_timer -= delta
	if dash_timer <= 0:
		dash_cooldown = DASH_COOLDOWN
		is_invincible = false
		if move_direction == Vector2.ZERO:
			enter_idle_state(); return
		else:
			enter_walk_state(); return

func attack_state() -> void:
	move()
	update_hitbox_offset()
	if player_animation.animation == "attack" and not player_animation.is_playing():
		if velocity != Vector2.ZERO:
			enter_walk_state(); return
		else:
			enter_idle_state(); return

func attacked_state() -> void:
	move()
	pass

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
		PlayerState.attack:  attack_state();
		PlayerState.dead:    dead_state();

# --- Movement ---
func move():
	velocity = move_direction * move_speed

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

# --- Attack ---
func switch_animation_attack() -> void:
	match current_state:
		PlayerState.attack:
			attack_animation.play("attack")
			attack_animation.look_at(mouse_position)
		_:
			attack_animation.play("aim")
			attack_animation.rotation = 0.0
