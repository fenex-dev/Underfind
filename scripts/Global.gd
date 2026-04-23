extends Node
var pipe_upgrade_cost: int = 500
var hp_upgrade_cost: int = 500
var speed_upgrade_cost: int = 500
signal banner_position_changed(Money_x, Timer_x, Boost_x)
var banner_positions = {
	"Money_label": 104.5,
	"Timer_label": 36,
	"Boost_label": 144
}
func update_banner_positions(money_x: float, timer_x: float, boost_x: float) -> void:
	banner_positions["Money_label"] = money_x
	banner_positions["Timer_label"] = timer_x
	banner_positions["Boost_label"] = boost_x
	banner_position_changed.emit(money_x, timer_x, boost_x)

signal speed_boost_changed(new_value)
var has_speed_boost: bool = true :
	set(value):
		if has_speed_boost != value:
			has_speed_boost = value
			speed_boost_changed.emit(value)
signal money_changed(new_amount)
var money: int = 0 :
	set(value):
		if value > money:
			total_money += (value - money)
		money = value
		money_changed.emit(money)
		
signal hp_changed(new_amount)

var hp: int = 100 :
	set(value):
		hp = value
		hp_changed.emit(value)
		
var total_money: int = 0
var rope_length: int = 1050 :
	set(value):
		rope_length = value
		rope_length_changed.emit(value)

signal rope_length_changed(new_amount)
signal max_hp_changed(new_amount)
signal speed_changed(new_amount)

var speed: float = 300.0 :
	set(value):
		speed = value
		speed_changed.emit(value)

var max_hp: int = 100 :
	set(value):
		max_hp = value
		max_hp_changed.emit(value)

var game_time: float = 600.0
signal time_changed(new_time)

var show_leaderboard := false

var save_path := "user://leaderboard.save"

func reset_game():
	money = 0
	hp = 100
	total_money = 0
	rope_length = 1050
	speed = 300.0
	max_hp = 100
	pipe_upgrade_cost = 500
	hp_upgrade_cost = 500
	speed_upgrade_cost = 500
	game_time = 600.0
	has_speed_boost = true

func _process(delta: float):
	if game_time > 0:
		game_time -= delta
		time_changed.emit(game_time)
		if game_time <= 0:
			game_time = 0.0
			hp = 0

func save_run():
	var scores: Array = []
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		if file:
			scores = file.get_var()
			file.close()

	scores.append(total_money)
	scores.sort_custom(func(a, b): return a > b)

	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_var(scores)
		file.close()
