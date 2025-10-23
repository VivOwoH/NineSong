extends Resource
class_name CharacterDatabase

## Database of all characters, accessed by name

@export var characters: Array[Character] = []

func get_character(character_name: String) -> Character:
	for character in characters:
		if character.character_name == character_name:
			return character
	push_warning("Character '%s' not found in database" % character_name)
	return null

func add_character(character: Character) -> void:
	characters.append(character)
	
func remove_character(character_name: String) -> void:
	for i in range(characters.size()):
		if characters[i].character_name == character_name:
			characters.remove_at(i)
			return
