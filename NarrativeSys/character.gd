extends Resource
class_name Character

## Used by narrative system to display character info

@export var character_name: String = ""
@export var character_color: Color = Color.WHITE
@export var portrait_texture: Texture2D = null

func _init(p_name: String ="", p_color: Color = Color.WHITE, p_portrait: Texture2D = null):
	character_name = p_name
	character_color = p_color
	portrait_texture = p_portrait
