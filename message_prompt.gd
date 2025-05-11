extends StaticBody2D
class_name MessagePropmt

@export var Type := Prompt_Type.NONE
@export var Propmt : StringName
@export var Destroy_After := true

enum Prompt_Type {NONE, VICTORY}
