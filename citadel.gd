extends Node2D

#Packed Scenes
@export var loot_box_scene : PackedScene
@export var shaking_enabled := true
@export var sfx_enabled := true
@export var music_enabled := true

@onready var hero: Hero = %Hero

@onready var inventory: Node2D = %Inventory
@onready var loot: Node2D = %Loot
@onready var head_item_list: ItemList = $"HUD/HUD/Inventory/Sprite-0001/GridContainer/VBoxContainer/HeadItemList"
@onready var left_item_list: ItemList = $"HUD/HUD/Inventory/Sprite-0001/GridContainer/VBoxContainer2/LeftItemList"
@onready var body_item_list: ItemList = $"HUD/HUD/Inventory/Sprite-0001/GridContainer/VBoxContainer3/BodyItemList"
@onready var right_item_list: ItemList = $"HUD/HUD/Inventory/Sprite-0001/GridContainer/VBoxContainer4/RightItemList"
@onready var loot_list: ItemList = $HUD/HUD/Loot/VBoxContainer/LootList
@onready var output: VBoxContainer = %Output
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var hp_label: Label = %HPLabel
@onready var restart_button: Button = %RestartButton
@onready var skull: TextureRect = %Skull
@onready var inventory_descriptions_rich_text: RichTextLabel = %InventoryDescriptionsRichText
@onready var winning_label: Label = %WinningLabel
@onready var enemy_details: Control = %EnemyDetails
@onready var how_to_play_panel: Panel = %HowToPlayPanel
@onready var shaker_component_2d: ShakerComponent2D = $Hero/Camera2D/ShakerComponent2D
@onready var shaker_component_2d2: ShakerComponent2D = $Hero/Camera2D/ShakerComponent2D2

@onready var music_interlude_timer: Timer = $Music/MusicInterludeTimer
var total_moves = 0
var global_timer := 0.0
var music_track = 1
var current_loot_box: LootBox
var oger_defeated := false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_inventory_descriptions_rich_text()
	
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err != OK:
		# Try creating one instead
		config = ConfigFile.new()
		config.set_value("Options", "shaking_enabled", shaking_enabled)
		config.set_value("Options", "sfx_enabled", sfx_enabled)
		config.set_value("Options", "music_enabled", music_enabled)
		config.set_value("Options", "music_track", music_track)
		config.save("user://settings.cfg")
	else:
		shaking_enabled = config.get_value("Options", "shaking_enabled")
		sfx_enabled = config.get_value("Options", "sfx_enabled")
		music_enabled = config.get_value("Options", "music_enabled")
		music_track = config.get_value("Options", "music_track")
	
	var sfx_bus_index = AudioServer.get_bus_index("sfx")
	AudioServer.set_bus_mute(sfx_bus_index, !sfx_enabled)
	var music_bus_index = AudioServer.get_bus_index("music")
	AudioServer.set_bus_mute(music_bus_index, !music_enabled)
	_on_music_interlude_timer_timeout()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if total_moves != 0:
		global_timer += delta
	var nearby_bad_guy = hero.get_nearby_enemy()
	if nearby_bad_guy != null:
		enemy_details.show()
		%EnemyDetails/Panel/RichTextLabel.text = "[color=#BF40BF]"+nearby_bad_guy.character_sheet.name+"[/color]\n"+\
"HP: [color=#ff0000]"+str(nearby_bad_guy.hp)+"[/color]\n"+\
"ATK: "+str(nearby_bad_guy.get_attack())+"\n"+\
"DEF: "+str(nearby_bad_guy.get_defense())+""
	else:
		enemy_details.hide()
	

func _on_inventory_button_pressed() -> void:
	if loot.visible || hero.hp <= 0:
		return
	inventory.visible = !inventory.visible
	hero.hault_all_actions = inventory.visible
	if inventory.visible:		
		head_item_list.clear()
		var index = 0
		for a in hero.head_equipment_set:
			head_item_list.add_item(a.name)
			if a == hero.head_armor:
				head_item_list.select(index)
			index += 1
		index = 0
		body_item_list.clear()
		for a in hero.body_equipment_set:
			body_item_list.add_item(a.name)
			if a == hero.body_armor:
				body_item_list.select(index)
			index += 1
		left_item_list.clear()
		right_item_list.clear()
		
		var left_selected := false
		var right_selected := false
		index = 0
		for a in hero.weapons_set:
			left_item_list.add_item(a.name)
			right_item_list.add_item(a.name)
			if a == hero.left_weapon && !left_selected:
				left_selected = true
				left_item_list.select(index)
				right_item_list.set_item_disabled(index, true)
			elif a == hero.right_weapon && !right_selected:
				right_selected = true
				right_item_list.select(index)
				left_item_list.set_item_disabled(index, true)
			index += 1

func _on_head_item_list_item_selected(index: int) -> void:
	var text = head_item_list.get_item_text(index)
	print("Selected "+text)
	# Find matching armor
	for a in hero.head_equipment_set:
		if a.name == text:
			hero.head_armor = a
	update_inventory_descriptions_rich_text()

func _on_body_item_list_item_selected(index: int) -> void:
	var text = body_item_list.get_item_text(index)
	print("Selected "+text)
	# Find matching armor
	for a in hero.body_equipment_set:
		if a.name == text:
			hero.body_armor = a
	update_inventory_descriptions_rich_text()

func _on_left_item_list_item_selected(index: int) -> void:
	var text = left_item_list.get_item_text(index)
	print("Selected "+text)
	# Find matching armor
	for a in hero.weapons_set:
		if a.name == text:
			hero.left_weapon = a
	update_inventory_descriptions_rich_text()
		
	for i in range(right_item_list.item_count):
		right_item_list.set_item_disabled(i, i == index)

func _on_right_item_list_item_selected(index: int) -> void:
	var text = right_item_list.get_item_text(index)
	print("Selected "+text)
	# Find matching armor
	for a in hero.weapons_set:
		if a.name == text:
			hero.right_weapon = a
	update_inventory_descriptions_rich_text()
	
	for i in range(left_item_list.item_count):
		left_item_list.set_item_disabled(i, i == index)

func _on_hero_bumped_into_loot(loot_box: LootBox) -> void:
	loot.visible = true
	hero.hault_all_actions = true
	current_loot_box = loot_box
	loot_list.clear()
	for a in loot_box.items:
		loot_list.add_item(a.name)
	
func _on_close_loot_button_pressed() -> void:
	if current_loot_box != null && current_loot_box.items.is_empty():
		current_loot_box.queue_free()
	else:
		current_loot_box = null
	loot.visible = false
	hero.hault_all_actions = false
	hero.debounced_can_move = false
	hero.timer.start()

func _on_take_all_loot_button_pressed() -> void:
	if current_loot_box == null: 
		return
	while !current_loot_box.items.is_empty():
		_on_loot_list_item_selected(0)
	_on_close_loot_button_pressed()
	
func _on_loot_list_item_selected(index: int) -> void:
	var text = loot_list.get_item_text(index)
	loot_list.remove_item(index)
	var found_item_in_loot_box_index := 0
	for a in current_loot_box.items:
		if a.name == text:
			if a.equipment_slot == Equipment.Equpiment_Slots.HEAD:
				hero.head_equipment_set.push_back(a)
			elif a.equipment_slot == Equipment.Equpiment_Slots.BODY:
				hero.body_equipment_set.push_back(a)
			elif a.equipment_slot == Equipment.Equpiment_Slots.WEAPON:
				hero.weapons_set.push_back(a)
			else:
				push_error("What the hay")
			break
		found_item_in_loot_box_index += 1
			
	current_loot_box.items.remove_at(found_item_in_loot_box_index)

func _on_hero_bumped_into_bad_guy(bad_guy: BadGuy) -> void:
	if shaking_enabled:
		if randi() % 2 == 0:
			shaker_component_2d.shake_speed = randf_range(0.8,1.0)
			shaker_component_2d.play_shake()
		else:
			shaker_component_2d2.shake_speed = randf_range(0.8,1.0)
			shaker_component_2d2.play_shake()
			
	if !bad_guy.ever_been_attacked && !bad_guy.character_sheet.attack_phrase.is_empty():
		bad_guy.ever_been_attacked = true
		sent_output("[color=#BF40BF]"+bad_guy.character_sheet.name+"[/color] says [color=#00FF00]\""+ bad_guy.character_sheet.attack_phrase+"\"[/color]")
	var output_text := ""
	# First calculate your hit
	var attack = hero.get_attack()
	var defense = bad_guy.get_defense()
	if attack > defense:
		attack = attack - defense
	else:
		attack = 1
	
	bad_guy.hp -= attack
	if bad_guy.hp < 0:
		bad_guy.hp = 0
	output_text = "You hit [color=#BF40BF]"+bad_guy.character_sheet.name+"[/color] for [color=#FF0000]"+str(attack)+"[/color]. ("+str(bad_guy.hp)+" HP left)"
	sent_output(output_text)
	#bad guy attacks
	if bad_guy.hp > 0:
		attack = bad_guy.get_attack()
		defense = hero.get_defense()
		if attack > defense:
			attack = attack - defense
		else:
			attack = 1
		
		hero.hp -= attack		
		output_text = "[color=#BF40BF]"+bad_guy.character_sheet.name+"[/color] hit you for [color=#FF0000]"+str(attack)+"[/color]"
		
		hp_label.text = "HP: " + str(hero.hp) + "\n"
		sent_output(output_text)
		if hero.hp <= 0:
			hp_label.text = "HP: \n"
			if !bad_guy.character_sheet.victory_phrase.is_empty():
				sent_output("[color=#BF40BF]"+bad_guy.character_sheet.name+"[/color] says [color=#00FF00]\""+ bad_guy.character_sheet.victory_phrase+"\"[/color]")
			hero.die()
			restart_button.show()
			skull.show()
			sent_output("[b]GAME OVER[b]")
	else:
		# Victory
		if bad_guy.character_sheet.name == "Oger":
			oger_defeated = true
		print("Victory against "+bad_guy.character_sheet.name)
		if !bad_guy.character_sheet.death_phrase.is_empty():
			sent_output("[color=#BF40BF]"+bad_guy.character_sheet.name+"[/color] says [color=#00FF00]\""+ bad_guy.character_sheet.death_phrase+"\"[/color] and stopped moving.")
		else:
			sent_output("[color=#BF40BF]"+bad_guy.character_sheet.name+"[/color] stopped moving.")
		var s = loot_box_scene.instantiate() as LootBox
		s.global_position = bad_guy.global_position
		if bad_guy.character_sheet.head != null:
			if !hero.head_equipment_set.has(bad_guy.character_sheet.head):
				s.items.push_back(bad_guy.character_sheet.head)
		if bad_guy.character_sheet.armor != null:
			if !hero.body_equipment_set.has(bad_guy.character_sheet.armor):
				s.items.push_back(bad_guy.character_sheet.armor)		
		if bad_guy.character_sheet.left != null:
			var c = hero.weapons_set.count(bad_guy.character_sheet.left)
			if c < 2:
				s.items.push_back(bad_guy.character_sheet.left)
		if bad_guy.character_sheet.right != null:
			var c = hero.weapons_set.count(bad_guy.character_sheet.right)
			if bad_guy.character_sheet.left == bad_guy.character_sheet.right:
				c += 1
			if c < 2:
				s.items.push_back(bad_guy.character_sheet.right)
			
		if !s.items.is_empty():
			add_child(s)
		bad_guy.queue_free()
	
func sent_output(message) -> void:
	var chat_message : RichTextLabel = RichTextLabel.new()
	chat_message.bbcode_enabled = true # Enable BBCode for color and sprites etc.
	chat_message.fit_content = true # Message should stretch to its content
	chat_message.text = " • " + message
	output.add_child(chat_message)
	output.move_child(chat_message, 0)
	scroll_container.scroll_vertical = 0

func _on_restart_button_pressed() -> void:
	# Restart with a new song each reset
	if music_track == 3:
		music_track = 0
	music_track += 1
	
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		config.set_value("Options", "music_track", music_track)
		config.save("user://settings.cfg")
		
	get_tree().reload_current_scene()

func update_inventory_descriptions_rich_text() -> void:	
	inventory_descriptions_rich_text.text = "Head: ("+str(hero.head_armor.attack)+" ATK / "+str(hero.head_armor.defense)+" DEF)\n"+\
"Body: ("+str(hero.body_armor.attack)+" ATK / "+str(hero.body_armor.defense)+" DEF)\n"+ \
"Left  : ("+str(hero.left_weapon.attack)+" ATK / "+str(hero.left_weapon.defense)+" DEF)\n"+\
"Right: ("+str(hero.right_weapon.attack)+" ATK / "+str(hero.right_weapon.defense)+" DEF)\n\n"+\
"Total: "+str(hero.get_attack())+" ATK / "+str(hero.get_defense()) + " DEF"


func _on_hero_bumped_into_heart() -> void:
	hero.hp = hero.max_hp
	hp_label.text = "HP: " + str(hero.hp) + "\n"


func _on_hero_bumped_into_message_prompt(message_prompt: MessagePropmt) -> void:
	if !message_prompt.Propmt.is_empty():
		sent_output(message_prompt.Propmt)
	if message_prompt.Type == MessagePropmt.Prompt_Type.VICTORY:
		var victory_prompt = "[bgcolor=#000000][b]Objective Complete![/b][/bgcolor]\n"		
		var time = "You completed the game in %s seconds " % str("%.2f" % global_timer)
		time += "and making " + str(total_moves) + " moves.\n"
		victory_prompt += time
		if oger_defeated:
			victory_prompt += "Defeating the [color=#BF40BF]Oger[/color] weighs heavy on your robot consciousness.\n"
		else:
			victory_prompt += "A solution was found without destroying the [color=#BF40BF]Oger[/color]! Nicely done.\n"
		victory_prompt += "Created by MrOnosa using Godot.\nArt by https://kenney.nl/\nSFX by https://tommusic.itch.io/\nMusic by https://alkakrab.itch.io/\nCreated for the SoloDevelopment 72-hour Jam #7\nSpecial thanks to everyone who cheered me on while I stayed up way too late creating this experiance. The indie gaming community rocks!"
		sent_output(victory_prompt)
		winning_label.show()
		# I made it! Mission complete. I am so happy! Created by MrOnosa using Godot. Art by https://kenney.nl/ SFX by https://tommusic.itch.io/ Music by https://alkakrab.itch.io/
	if message_prompt.Destroy_After:
		message_prompt.queue_free()


func _on_how_to_play_button_pressed() -> void:
	how_to_play_panel.visible = !how_to_play_panel.visible


func _on_shake_option_button_pressed() -> void:
	if shaking_enabled:
		shaking_enabled = false
		sent_output("Camera Shake has been disabled")
	else:
		shaking_enabled = true
		sent_output("Camera Shake has been enabled")
	
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		config.set_value("Options", "shaking_enabled", shaking_enabled)
		config.save("user://settings.cfg")


func _on_sfx_option_button_pressed() -> void:
	if sfx_enabled:
		sfx_enabled = false
		sent_output("Sound effects muted")
	else:
		sfx_enabled = true
		sent_output("Sound effects unmuted")	
	
	var sfx_bus_index = AudioServer.get_bus_index("sfx")
	AudioServer.set_bus_mute(sfx_bus_index, !sfx_enabled)
	
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		config.set_value("Options", "sfx_enabled", sfx_enabled)
		config.save("user://settings.cfg")


func _on_music_option_button_pressed() -> void:
	if music_enabled:
		music_enabled = false
		sent_output("Music muted")
	else:
		music_enabled = true
		sent_output("Music unmuted")
		
	var music_bus_index = AudioServer.get_bus_index("music")
	AudioServer.set_bus_mute(music_bus_index, !music_enabled)
	
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		config.set_value("Options", "music_enabled", music_enabled)
		config.save("user://settings.cfg")


func _on_music_interlude_timer_timeout() -> void:
	if music_track == null || music_track < 1 || music_track > 3:
		music_track = 1
	
	if music_track == 1:
		$Music/Pixel5.play()
	if music_track == 2:
		$Music/Pixel11.play()
	if music_track == 3:
		$Music/Pixel12.play()
		music_track = 0
	music_track += 1

func _on_music_finished() -> void:
	$Music/Pixel5.stop()
	$Music/Pixel11.stop()
	$Music/Pixel12.stop()
	$Music/MusicInterludeTimer.start()


func _on_hero_moved() -> void:
	total_moves += 1
