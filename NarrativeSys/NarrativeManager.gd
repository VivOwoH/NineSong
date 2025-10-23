extends Node
class_name NarrativeManager

## Main narrative system manager
## Handles dialogue flow, choice selection, and resource-based active checks
## This acts as the interface between your game and the narrative system

signal dialogue_line_ready(line: DialogueLine)
signal choices_ready(choices: Array[DialogueLine])
signal dialogue_ended
signal resources_changed(qi: int, jing: int, shen: int)

var character_database: CharacterDatabase
var parser: NarrativeParser
var global_access: Node

# Current dialogue state
var current_lines: Array[DialogueLine] = []
var current_choices: Array[DialogueLine] = []
var current_line_index: int = 0

# Story script
var story_data: Array = []
var story_index: int = 0

func _ready():
	# Get reference to GlobalAccess singleton
	global_access = get_node("/root/GlobalAccess")
	
	# Load character database
	character_database = CharacterDatabase.new()
	
	# Setup parser
	parser = NarrativeParser.new(character_database, global_access)

## Initialize the narrative system with a character database
func setup(p_character_database: CharacterDatabase) -> void:
	character_database = p_character_database
	parser = NarrativeParser.new(character_database, global_access)

## Load story from a simple format
## Each entry is a dictionary with:
##   - text: the dialogue text
##   - tags: string of tags (e.g., "# Character # Harry")
##   - choices: array of choice dictionaries (optional)
func load_story(story: Array) -> void:
	story_data = story
	story_index = 0
	current_line_index = 0

## Start the dialogue
func start_dialogue() -> void:
	if story_data.is_empty():
		push_error("No story data loaded")
		return
	
	show_next_line()

## Show the next line of dialogue
func show_next_line() -> void:
	if story_index >= story_data.size():
		dialogue_ended.emit()
		return
	
	var entry = story_data[story_index]
	var text = entry.get("text", "")
	var tag_string = entry.get("tags", "")
	var choices = entry.get("choices", [])
	
	# Parse tags
	var tags = parser.parse_tags(tag_string)
	
	# Parse the line
	var line = parser.parse_line(text, tags, false)
	
	# Check if this is a passive check that shouldn't be visible
	if line.is_passive_check and not line.is_visible():
		# Skip this line
		story_index += 1
		show_next_line()
		return
	
	# Emit the dialogue line
	dialogue_line_ready.emit(line)
	
	# If there are choices, process them
	if choices.size() > 0:
		process_choices(choices)
	else:
		story_index += 1

## Process player choices
func process_choices(choices_data: Array) -> void:
	current_choices.clear()
	
	for i in range(choices_data.size()):
		var choice_data = choices_data[i]
		var text = choice_data.get("text", "")
		var tag_string = choice_data.get("tags", "")
		
		var tags = parser.parse_tags(tag_string)
		var choice_line = parser.parse_line(text, tags, true)
		choice_line.choice_index = i
		
		# Only add visible choices
		if choice_line.is_visible():
			current_choices.append(choice_line)
	
	if current_choices.size() > 0:
		choices_ready.emit(current_choices)
	else:
		# No visible choices, continue
		story_index += 1
		show_next_line()

## Select a choice
func select_choice(choice_index: int) -> void:
	if choice_index < 0 or choice_index >= current_choices.size():
		push_error("Invalid choice index: %d" % choice_index)
		return
	
	var choice = current_choices[choice_index]
	
	# If it's an active check, consume resources (always succeeds)
	if choice.is_active_check:
		if choice.check_available:
			_consume_resources(choice)
			# Emit the choice that was taken
			dialogue_line_ready.emit(choice)
		else:
			push_warning("Cannot afford this active check")
			# Don't advance, let player choose again
			return
	
	# Move to next story entry
	story_index += 1
	show_next_line()

## Consume resources for an active check
func _consume_resources(choice: DialogueLine) -> void:
	var current_qi = global_access.get_var("Qi")
	var current_jing = global_access.get_var("Jing")
	var current_shen = global_access.get_var("Shen")
	
	# Deduct costs
	global_access.set_var("Qi", current_qi - choice.check_cost_qi)
	global_access.set_var("Jing", current_jing - choice.check_cost_jing)
	global_access.set_var("Shen", current_shen - choice.check_cost_shen)
	
	# Update balance
	global_access.update_balance()
	
	# Emit resource change
	resources_changed.emit(
		global_access.get_var("Qi"),
		global_access.get_var("Jing"),
		global_access.get_var("Shen")
	)
	
	print("Resources consumed | Qi: -%d | Jing: -%d | Shen: -%d" % 
		[choice.check_cost_qi, choice.check_cost_jing, choice.check_cost_shen])

## Continue to next line (for non-choice dialogue)
func continue_dialogue() -> void:
	show_next_line()

## Format a line for display (with color and character name)
func format_line(line: DialogueLine) -> String:
	return parser.format_line_for_display(line)

## Get the current choices (formatted for display)
func get_formatted_choices() -> Array[String]:
	var formatted: Array[String] = []
	for choice in current_choices:
		formatted.append(parser.format_line_for_display(choice))
	return formatted

## Get current player resources
func get_current_resources() -> Dictionary:
	return {
		"qi": global_access.get_var("Qi"),
		"jing": global_access.get_var("Jing"),
		"shen": global_access.get_var("Shen"),
		"qi_max": global_access.get_var("Qi_max"),
		"jing_max": global_access.get_var("Jing_max"),
		"shen_max": global_access.get_var("Shen_max"),
	}
