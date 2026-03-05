extends CharacterBody2D


@export var speed := 150
@export var lifetime := 3   # safety lifetime in seconds

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
			Global.hp -= 10
			stop_movement()
			return

func stop_movement():
	is_active = false
	velocity = Vector2.ZERO
	# optional hit effect: visually flip or play animation here
	queue_free()
	
