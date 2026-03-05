extends CharacterBody2D

@export var speed := 200
@export var lifetime := 10.0   # safety lifetime in seconds

var player: Node2D
var charge_direction := Vector2.ZERO
var is_active := true
var can_hit := false
var _life_timer := 0.0

func _ready():
	# Ensure collision setup — fish sits on layer 2 and looks for layer 1 (player)
	collision_layer = 2
	collision_mask = 1

	player = get_tree().get_first_node_in_group("player")
	if not player:
		push_warning("EnemyFish: No player found in group 'player' — fish will idle.")
		# Still don't immediately free — helpful when testing pre-placed enemies
		is_active = false
		return

	var to_player = player.global_position - global_position
	if to_player.length() > 0.01:
		charge_direction = to_player.normalized()
	else:
		charge_direction = Vector2.RIGHT # fallback

	# small safety delay to avoid initial overlapping collision
	await get_tree().physics_frame
	can_hit = true
	_life_timer = 0.0
	print_debug("EnemyFish ready at ", global_position, " heading to player at ", player.global_position)

func _physics_process(delta):
	# safety lifetime to avoid rogue stuck objects
	_life_timer += delta
	if _life_timer > lifetime:
		print_debug("EnemyFish: lifetime expired — freeing.")
		queue_free()
		return

	if not is_active:
		return

	# If we lost the player midgame, recalc direction if possibl

	velocity = charge_direction * speed
	move_and_slide()

	if not can_hit:
		return

	# debug the slide collisions so you can see who we hit
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		print_debug("EnemyFish collided with: ", collider, " (type=", typeof(collider), ", name=", (collider and collider.name))
		if collider and collider.is_in_group("player"):
			Global.hp -= 25
			explode()
			stop_movement()
			return

func stop_movement():
	is_active = false
	velocity = Vector2.ZERO
	# optional hit effect: visually flip or play animation here
	queue_free()
	
func explode():
	var particles = preload("res://scenes/explosion.tscn").instantiate()
	particles.global_position = global_position
	get_parent().add_child(particles)
	particles.emitting = true  # enable after adding to scene

	# Optional: shockwave ring
	var ring = Sprite2D.new()
	ring.texture = preload("res://IMGS/circle.png")  # white circle
	ring.global_position = global_position
	ring.modulate = Color(0.5, 0.8, 1, 0.8)

	# Create a CanvasItemMaterial for additive blending
	var mat = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	ring.material = mat

	get_parent().add_child(ring)

	# Animate scale and fade
	var tween = Tween.new()
	ring.add_child(tween)
	tween.tween_property(ring, "scale", Vector2(2,2), 0.6)
	tween.tween_property(ring, "modulate:a", 0.0, 0.6)
	tween.play()

	# cleanup after animation
	await get_tree().create_timer(1.2).timeout
	particles.queue_free()
	ring.queue_free()
