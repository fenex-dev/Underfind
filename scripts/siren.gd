extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D
var player
var is_active: bool = false
@onready var AttackTimer = $AttackTimer
@export var sound_attack: PackedScene
@onready var pose_timer = $PoseSwitchTimer

func _physics_process(_delta: float) -> void:
	if player and is_active:
		look_at_player()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_active = true
		player = get_tree().get_first_node_in_group("player")
		AttackTimer.start()
		


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_active = false
		player = null
func look_at_player():
	# Compare X positions using the sprite's global position as the siren's visual position
	if player.global_position.x < sprite.global_position.x:
		# Player is to the right
		sprite.flip_h = false 
	else:
		# Player is to the left
		sprite.flip_h = true


func _on_timer_timeout() -> void:
	if not player or not is_active:
		return
	sprite.play("scream")
	pose_timer.start()
	var attack = sound_attack.instantiate()
	# use the sprite's global position for the attack's origin
	var origin = sprite.global_position
	var to_player = player.global_position - origin
	var direction = to_player.normalized()
	
	# ensure the attack doesn't spawn past the player
	var spawn_distance = min(30, to_player.length()) * 0.5
	attack.global_position = origin + direction * spawn_distance
	get_parent().add_child(attack)
	print("we got somewhere")
	


func _on_pose_switch_timer_timeout() -> void:
	sprite.play("passive")
