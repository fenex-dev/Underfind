extends Area2D



var player_is_in_area: bool = false
var popup
@onready var shop_items = $CanvasLayer/ItemList
var is_shopping = false
var heal_cost: int = 200
var boost_cost: int = 500

func _ready() -> void:
	popup = $Label
	popup.visible = false
	# Initialize the ItemList text with the initial prices
	shop_items.set_item_text(0, "HP - $" + str(Global.hp_upgrade_cost))
	shop_items.set_item_text(1, "Pipe range - $" + str(Global.pipe_upgrade_cost))
	shop_items.set_item_text(2, "Heal - $" + str(heal_cost))
	shop_items.set_item_text(3, "Speed - $" + str(Global.speed_upgrade_cost))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if player_is_in_area and Input.is_action_just_pressed("Interact"):
		if !is_shopping:
			# Open the shop
			shop_items.visible = true
			is_shopping = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			# Close the shop
			shop_items.visible = false
			is_shopping = false
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN) # Or MOUSE_MODE_CAPTURED if the game needs it
	
	# Since ItemList is now in a CanvasLayer and has anchors_preset = 8 (Center),
	# it will be automatically centered on the screen by Godot.
	# We no longer need manual world-to-screen coordinate math.
	


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		popup.visible = true
		player_is_in_area = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		popup.visible = false
		player_is_in_area = false
		if is_shopping:
			shop_items.visible = false
			is_shopping = false
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func _on_item_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	if index == 0:
		if Global.money >= Global.hp_upgrade_cost:
			Global.money -= Global.hp_upgrade_cost
			Global.max_hp += 20
			# Increase the cost for the next upgrade
			Global.hp_upgrade_cost += 500
			# Update the UI text
			shop_items.set_item_text(0, "HP - $" + str(Global.hp_upgrade_cost))
			print(Global.max_hp)
		else:
			print("Not enough money!")
	elif index == 1:
		if Global.money >= Global.pipe_upgrade_cost:
			Global.money -= Global.pipe_upgrade_cost
			Global.rope_length += 400
			# Increase the cost for the next upgrade
			Global.pipe_upgrade_cost += 500
			# Update the UI text
			shop_items.set_item_text(1, "Pipe range - $" + str(Global.pipe_upgrade_cost))
			print(Global.rope_length)
		else:
			print("Not enough money!")
	elif index == 2:
		if Global.money >= heal_cost:
			if Global.hp < Global.max_hp:
				Global.money -= heal_cost
				Global.hp += 20
				print("Healed to max!")
			else:
				print("Already at full health!")
		else:
			print("Not enough money!")
	elif index == 3:
		if Global.money >= Global.speed_upgrade_cost:
			Global.money -= Global.speed_upgrade_cost
			Global.speed += 50
			# Increase the cost for the next upgrade
			Global.speed_upgrade_cost += 500
			# Update the UI text
			shop_items.set_item_text(3, "Speed - $" + str(Global.speed_upgrade_cost))
			print(Global.speed)
		else:
			print("Not enough money!")
	elif index == 4:
		if Global.money >= boost_cost:
			if Global.has_speed_boost:
				print("Speed boost already active!")
				return
			else:
				Global.money -= boost_cost
				Global.has_speed_boost = true
				print("Speed boost activated!")
		else:
			print("Not enough money!")
		
	
