extends TextureRect

func _ready() -> void:
	var money_notif = get_node_or_null(^"Label")
	var time_notif = get_node_or_null(^"TimerLabel")
	var boost_notif = get_node_or_null(^"Label2")
	Global.money_changed.connect(_on_money_changed)
	Global.time_changed.connect(_on_time_changed)
	Global.speed_boost_changed.connect(_on_speed_boost_changed)
	Global.banner_position_changed.connect(_on_banner_position_changed)
	$Label.item_rect_changed.connect(_update_layout)
	$Label.text = "$" + str(Global.money)
	_update_timer_label(Global.game_time)
	if get_node_or_null(^"Label2"):
		$Label2.visible = Global.has_speed_boost
	
	# Initial position set
	_on_banner_position_changed(Global.banner_positions["Money_label"], Global.banner_positions["Timer_label"], Global.banner_positions["Boost_label"])

func _on_money_changed(new_money: int) -> void:
	$Label.text = "$" + str(new_money)
	_update_layout()

func _on_time_changed(new_time: float) -> void:
	_update_timer_label(new_time)
	_update_layout()

func _on_speed_boost_changed(speed_boost: bool) -> void:
	if get_node_or_null(^"Label2"):
		$Label2.visible = Global.has_speed_boost
		_update_layout()

func _on_banner_position_changed(money_x: float, timer_x: float, boost_x: float) -> void:
	if get_node_or_null(^"Label"):
		$Label.position.x = money_x
	if get_node_or_null(^"TimerLabel"):
		$TimerLabel.position.x = timer_x
	if get_node_or_null(^"Label2"):
		$Label2.position.x = boost_x

func _update_timer_label(time: float) -> void:
	var minutes: int = int(time) / 60
	var seconds: int = int(time) % 60
	if get_node_or_null(^"TimerLabel"):
		$TimerLabel.text = "%02d:%02d" % [minutes, seconds]
func _update_layout() -> void:
	var time_x = $TimerLabel.get_minimum_size().x
	var money_x = $Label.get_minimum_size().x
	var boost_x = $Label2.get_minimum_size().x
	
	var total_width = 179.0 # Approximate total available width in the banner
	
	if $Label2.visible:
		var info_gap = (total_width - (time_x + money_x + boost_x)) / 4
		var timer_pos = 35 + (info_gap)
		var money_pos = timer_pos + time_x + info_gap
		var boost_pos = money_pos + money_x + info_gap
		Global.update_banner_positions(money_pos, timer_pos, boost_pos)
		print(money_pos)
	else:
		var info_gap = ((total_width - (time_x + money_x))/3)
		var timer_pos = (35 + info_gap)
		var money_pos = (214 - info_gap) - (money_x)
		Global.update_banner_positions(money_pos, timer_pos, Global.banner_positions["Boost_label"])
		print(money_pos)
		
		
		

