extends StaticBody2D
class_name BadGuy

@export var character_sheet : Character
@export var hp : int
@export var ever_been_attacked : bool

func _ready() -> void:
	hp = character_sheet.base_hp
	if character_sheet.name.is_empty():
		character_sheet.name = name


func get_attack() -> int:
	var attack = character_sheet.base_attack
	
	if character_sheet.head != null:
		attack += character_sheet.head.attack
	if character_sheet.armor != null:
		attack += character_sheet.armor.attack
	if character_sheet.left != null:
		attack += character_sheet.left.attack
	if character_sheet.right != null:
		attack += character_sheet.right.attack
	
	if attack == 0:
		attack = 1
	return attack
	
func get_defense() -> int:
	var defense =  character_sheet.base_defense
	
	if character_sheet.head != null:
		defense += character_sheet.head.defense
	if character_sheet.armor != null:
		defense += character_sheet.armor.defense
	if character_sheet.left != null:
		defense += character_sheet.left.defense
	if character_sheet.right != null:
		defense += character_sheet.right.defense
	
	return defense
