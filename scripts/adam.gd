extends CharacterBody2D

# --- EXPORT VARIABLES ---
@export var speed: float = 400
var rope_length_org: float = 1050
var rope_length_2: float = rope_length_org - 1600
@export var hp: Array[AtlasTexture]

# --- CONSTANTS ---
var GRAVITY: float = 1200.0
const JUMP_VELOCITY: float = -600
@onready var is_underwater: bool = !get_tree().current_scene.scene_file_path == "res://scenes/base.tscn"
@onready var is_in_base: bool = !is_underwater


# --- NODE REFERENCES ---
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var bubbles_node = get_parent().get_node_or_null("Bubbles")
@onready var rope_line = get_parent().get_node_or_null("PinJoint2D/Line2D")
@onready var hook = get_parent().get_node_or_null("oxygen_tank")

# --- INTERNAL VARIABLES ---
var current_max_hp: int = 100
var rope_active: bool = false
var hook_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	current_max_hp = Global.max_hp
	Global.money_changed.connect(change_money)
	Global.hp_changed.connect(change_hp)
	Global.max_hp_changed.connect(change_max_hp)
	Global.rope_length_changed.connect(change_rope_length)
	Global.speed_changed.connect(change_speed)

	rope_length_org = Global.rope_length
	rope_length_2 = rope_length_org - 1600

	if hook:
		hook_position = hook.global_position
		rope_active = true

	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play("Idle")

	change_hp(Global.hp)
	change_money(Global.money)

	if is_underwater:
		GRAVITY /= 2
		speed = Global.speed / 2
	else:
		speed = Global.speed


func change_speed(new_speed: float):
	if is_underwater:
		speed = new_speed / 2
	else:
		speed = new_speed


func change_hp(new_hp: int):
	new_hp = clamp(new_hp, 0, current_max_hp)

	if new_hp == 0:
		$AudioStreamPlayer2D.play()
		Global.save_run()
		Global.show_leaderboard = true
		change_scenes("res://scenes/main_menu.tscn")

	if hp.is_empty():
		return

	var range_size: float = float(current_max_hp) / hp.size()
	if range_size <= 0:
		range_size = 1.0

	var index: int = int(floor((current_max_hp - new_hp) / range_size))
	index = clamp(index, 0, hp.size() - 1)

	$TextureRect.texture = hp[index]


func change_max_hp(new_max_hp: int):
	var old_max = current_max_hp
	if old_max == 0:
		old_max = 100

	var gain = new_max_hp - old_max
	var new_hp = Global.hp + gain

	current_max_hp = new_max_hp
	Global.hp = new_hp


func change_rope_length(new_length: int):
	rope_length_org = float(new_length)
	rope_length_2 = rope_length_org - 1600


func change_money(money):
	if get_node_or_null("Camera2D"):
		$Camera2D.get_node("Banner/Label").text = "$" + str(money)
	else:
		get_parent().get_node("Banner/Label").text = "$" + str(money)


func _physics_process(delta: float) -> void:
	var direction = Input.get_axis("move_left", "move_right")

	if hook:
		hook_position = hook.global_position


	# --- GRAVITY ---
	if is_in_base:
		if not is_on_floor():
			velocity.y += GRAVITY * delta
		else:
			velocity.y = 0

	if Input.is_key_pressed(Key.KEY_ESCAPE):
		change_scenes("res://scenes/main_menu.tscn")

	# --- JUMP ---
	if Input.is_key_pressed(Key.KEY_SPACE) and is_on_floor():
		velocity.y = JUMP_VELOCITY
		sprite.play("Jump")

	# --- MOVEMENT LOGIC ---
	if is_underwater:
		var move_dir = Vector2.ZERO
		move_dir.x = direction
		move_dir.y = Input.get_axis("move_up", "move_down")
		
		if move_dir != Vector2.ZERO:
			velocity = move_dir.normalized() * speed
			
			# Animation
			if is_on_floor():
				sprite.play("Walk_Helmet")
			else:
				sprite.play("Swim")
		else:
			velocity = velocity.move_toward(Vector2.ZERO, speed * 0.2)
			sprite.play("Idle")
			
		if Input.is_key_pressed(Key.KEY_R):
			change_scenes("res://scenes/base.tscn")
	else:
		# BASE/LAND MOVEMENT
		if direction != 0:
			velocity.x = direction * speed
			sprite.flip_h = direction < 0
			sprite.play("Walk")
		else:
			velocity.x = lerp(velocity.x, 0.0, 0.1)
			sprite.play("Idle")

	# --- ROPE CONSTRAINT ---
	if rope_active:
		var to_player = global_position - hook_position
		var dist = to_player.length()

		var max_length = rope_length_org
		if get_parent().name == "World2":
			max_length = rope_length_2

		if dist > max_length and dist != 0:
			var dir = to_player / dist
			var excess = dist - max_length
			global_position -= dir * excess

			var tangent = Vector2(-dir.y, dir.x)
			velocity = velocity.project(tangent)

	move_and_slide()

	# --- SWIM ROTATION (CLEAN + STABLE) ---
	if is_underwater:
		if velocity.length() > 10:  # Only turn if the fish is moving fast enough
			var target_angle = velocity.angle()  # Figure out where the fish should face
			if abs(target_angle) < 0.1 or abs(target_angle - PI) < 0.1:  # If moving left or right
				target_angle = 0.0 if velocity.x > 0 else PI  # Face directly left or right
			sprite.rotation = lerp_angle(sprite.rotation, target_angle, 0.3)  # Turn faster
			
			# Prevent upside down when facing left
			var is_facing_left = abs(sprite.rotation) > PI / 2
			sprite.flip_v = is_facing_left
			sprite.flip_h = false # Ensure flip_h is off when underwater
		else:
			sprite.rotation = 0  # Stay still if not moving
			sprite.flip_v = false
			sprite.flip_h = direction < 0 if direction != 0 else sprite.flip_h
		

	# --- ROPE VISUAL ---
	if rope_active and rope_line:
		var visual_length = rope_length_org
		if get_parent().name == "World2":
			visual_length = rope_length_2
		update_rope_visuals(visual_length)


# ---------------- HELPERS ----------------

func update_rope_visuals(length: float) -> void:
	var segments = clamp(int(length / 5), 2, 500)
	var points = []

	for i in range(segments + 1):
		var t = float(i) / segments
		var point = hook_position.lerp(global_position, t)
		points.append(rope_line.to_local(point))

	rope_line.points = points


func _on_animation_finished() -> void:
	sprite.stop()
	sprite.animation = &"None"


# --- WATER TRANSITIONS ---

func on_enter_water(body: Node2D) -> void:
	if body == self and bubbles_node:
		change_scenes("res://scenes/mapa_pls.tscn")


func change_scenes(new_scene: String, _after_change: Callable = Callable()):
	bubbles_node.visible = true
	var mat = bubbles_node.get_node("ColorRect").material
	get_parent().get_node("BubbleSFX").play()

	var tween = create_tween()
	tween.tween_property(mat, "shader_parameter/transition_fill", 1.5, 0.6)
	tween.tween_interval(1.0)
	tween.tween_property(mat, "shader_parameter/transition_fill", 0.0, 0.6)

	tween.tween_callback(func():
		bubbles_node.visible = false
		get_tree().change_scene_to_file(new_scene)
	)


func go_next_level(body: Node2D) -> void:
	if body == self and bubbles_node:
		change_scenes("res://scenes/hell_underwater.tscn")


func go_back(body: Node2D) -> void:
	if body == self and bubbles_node:
		change_scenes("res://scenes/mapa_pls.tscn")
