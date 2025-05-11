extends Area2D
class_name Hero

@export var max_hp := 10
@export var hp := 10
@export var head_armor : Equipment
@export var head_equipment_set : Array[Equipment] = []
@export var body_armor : Equipment
@export var body_equipment_set : Array[Equipment] = []
@export var left_weapon : Equipment
@export var right_weapon : Equipment
@export var weapons_set : Array[Equipment] = []

var sfx_walk_track := 1
var sfx_chest_track := 1
var sfx_attack_track := 0


signal bumped_into_loot(loot_box: LootBox)
signal bumped_into_bad_guy(bad_guy: BadGuy)
signal bumped_into_heart()
signal bumped_into_message_prompt(message_prompt: MessagePropmt)
signal moved() #any movement except into a wall

@onready var hero: Area2D = %Hero

@onready var timer: Timer = $"../MovementDebouncingTimer"
var hault_all_actions = false
var debounced_can_move = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	head_armor = head_equipment_set[0]
	body_armor = body_equipment_set[1]
	left_weapon = weapons_set[0]
	right_weapon = weapons_set[1]
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if hault_all_actions || hp <= 0: 
		return
		
	if debounced_can_move:
		if Input.is_action_pressed("Up"):
			player_move("Up", $UpRayCast2D, Vector2(0, -8))
		elif Input.is_action_pressed("Down"):
			player_move("Down", $DownRayCast2D, Vector2(0, 8))
		elif Input.is_action_pressed("Right"):
			player_move("Right", $RightRayCast2D, Vector2(8, 0))
		elif Input.is_action_pressed("Left"):
			player_move("Left", $LeftRayCast2D, Vector2(-8, 0))
	if Input.is_action_just_released("Down") || Input.is_action_just_released("Right") || Input.is_action_just_released("Up") || Input.is_action_just_released("Left"):
		debounced_can_move = true;

func player_move(direction_name: StringName, ray: RayCast2D, vector: Vector2):
	print("Moving " + direction_name)
	debounced_can_move = false
	timer.start()
	var obs = ray.get_collider()
	if obs == null:
		position += vector;
		play_walk_sfx()
		moved.emit()
	elif obs is Node:
		if obs.is_in_group("enemy"):
			print("FIGHT ")
			var bad = obs as BadGuy
			bumped_into_bad_guy.emit(bad)
			play_attack_sfx()
			moved.emit()
		elif obs is LootBox:
			print("Show loot")
			var loot = obs as LootBox
			bumped_into_loot.emit(loot)
			play_chest_sfx()
			moved.emit()
		elif obs is Heal:
			bumped_into_heart.emit()
			$SFX/BowPutAway1.play()
			obs.queue_free()
			moved.emit()
		elif obs is MessagePropmt:
			position += vector;
			play_walk_sfx()
			var p = obs as MessagePropmt
			bumped_into_message_prompt.emit(p)
			moved.emit()

func play_walk_sfx() -> void:
	if sfx_walk_track == 1:
		$SFX/StoneWalk1.play()
	if sfx_walk_track == 2:
		$SFX/StoneWalk2.play()
	if sfx_walk_track == 3:
		$SFX/StoneWalk3.play()
	if sfx_walk_track == 4:
		$SFX/StoneWalk4.play()
	if sfx_walk_track == 5:
		$SFX/StoneWalk5.play()
		sfx_walk_track = 0
	sfx_walk_track += 1
	
func play_chest_sfx() -> void:
	if sfx_chest_track == 1:
		$SFX/ChestOpen1.play()
	if sfx_chest_track == 2:
		$SFX/ChestOpen2.play()
		sfx_chest_track = 0
	sfx_chest_track += 1


func play_attack_sfx() -> void:
	var random_attack_track = randi_range(1, 9)
	while random_attack_track == sfx_attack_track:
		random_attack_track = randi_range(1, 9)
	sfx_attack_track = random_attack_track
	if sfx_attack_track == 1:
		$SFX/SwordBlocked1.play()
	if sfx_attack_track == 2:
		$SFX/SwordBlocked2.play()
	if sfx_attack_track == 3:
		$SFX/SwordBlocked3.play()
	
	if sfx_attack_track == 4:
		$SFX/SwordImpactHit1.play()
	if sfx_attack_track == 5:
		$SFX/SwordImpactHit2.play()
	if sfx_attack_track == 6:
		$SFX/SwordImpactHit3.play()	
	
	if sfx_attack_track == 7:
		$SFX/SwordParry1.play()
	if sfx_attack_track == 8:
		$SFX/SwordParry2.play()
	if sfx_attack_track == 9:
		$SFX/SwordParry3.play()

func get_nearby_enemy() -> BadGuy:
	var bg : BadGuy = null
	
	var obs = $UpRayCast2D.get_collider()	
	if obs is BadGuy:
		bg = obs as BadGuy
	
	obs = $RightRayCast2D.get_collider()
	if obs is BadGuy:
		bg = obs as BadGuy
	
	obs = $DownRayCast2D.get_collider()
	if obs is BadGuy:
		bg = obs as BadGuy
	
	obs = $LeftRayCast2D.get_collider()
	if obs is BadGuy:
		bg = obs as BadGuy
		
	return bg

func get_attack() -> int:
	var attack = 0
	
	if head_armor != null:
		attack += head_armor.attack
	if body_armor != null:
		attack += body_armor.attack
	if left_weapon != null:
		attack += left_weapon.attack
	if right_weapon != null:
		attack += right_weapon.attack
	
	if attack == 0:
		attack = 1
	return attack
	
func get_defense() -> int:
	var defense = 0
	
	if head_armor != null:
		defense += head_armor.defense
	if body_armor != null:
		defense += body_armor.defense
	if left_weapon != null:
		defense += left_weapon.defense
	if right_weapon != null:
		defense += right_weapon.defense
	
	return defense

func die() -> void:
	$AnimatedSprite2D.frame = 1

func _on_movement_debouncing_timer_timeout() -> void:
	debounced_can_move = true
