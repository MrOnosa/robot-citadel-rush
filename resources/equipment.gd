extends Resource
class_name Equipment

@export var name: StringName
@export var defense: int
@export var attack: int
@export var equipment_slot: Equpiment_Slots
	
enum Equpiment_Slots {HEAD, BODY, WEAPON}
