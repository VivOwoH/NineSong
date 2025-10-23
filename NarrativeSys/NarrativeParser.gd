extends Node
class_name NarrativeParser

## Parses dialogue text and extracts metadata from tags
## Handles character tags, active check tags (resource-based), and passive check tags

var character_database: CharacterDatabase
var global_access: Node  # Reference to GlobalAccess singleton

func _init(p_character_db: CharacterDatabase, p_global_access: Node):
	character_database = p_character_db
	global_access = p_global_access

## Parse a line of dialogue text with tags
## Tag formats:
##   # Character # CharacterName
##   # ActiveCheck # Stat Threshold Cost_Qi Cost_Jing Cost_Shen
##     Example: # ActiveCheck # Shen 8 3 0 2
##   # PassiveCheck # Pass/Fail Stat Threshold
##     Example: # PassiveCheck # Pass Jing 5
func parse_line(text: String, tags: Array, is_choice: bool = false) -> DialogueLine:
	var line = DialogueLine.new(text)
	
	if is_choice:
		line.line_type = DialogueLine.LineType.CHOICE
	
	# Parse tags
	for i in range(tags.size()):
		var tag = tags[i].strip_edges()
		
		# Character tag (format: # Character # Name)
		if tag == "Character" and i + 1 < tags.size():
			var character_name = tags[i + 1].strip_edges()
			line.character = character_database.get_character(character_name)
		
		# Active check tag (format: # ActiveCheck # Stat Threshold Qi_Cost Jing_Cost Shen_Cost)
		# Example: # ActiveCheck # Shen 8 3 0 2
		elif tag == "ActiveCheck" and i + 1 < tags.size():
			line.is_active_check = true
			line.line_type = DialogueLine.LineType.ACTIVE_CHECK
			
			var check_data = tags[i + 1].strip_edges().split(" ")
			
			if check_data.size() >= 5:
				line.check_stat = check_data[0]  # "Jing", "Shen", "Qi"
				line.check_threshold = int(check_data[1])
				line.check_cost_qi = int(check_data[2])
				line.check_cost_jing = int(check_data[3])
				line.check_cost_shen = int(check_data[4])
				
				# Check if player can afford this
				line.check_available = _can_afford_active_check(line)
		
		# Passive check tag (format: # PassiveCheck # Pass/Fail Stat Threshold)
		elif tag == "PassiveCheck" and i + 1 < tags.size():
			line.is_passive_check = true
			var check_data = tags[i + 1].strip_edges().split(" ")
			
			if check_data.size() >= 3:
				var pass_fail = check_data[0]  # "Pass" or "Fail"
				var stat_name = check_data[1]
				var threshold = int(check_data[2])
				
				var fail_mode = (pass_fail == "Fail")
				line.passive_check_visible = global_access.can_perform_action(
					threshold if stat_name == "Jing" else 0,
					threshold if stat_name == "Shen" else 0,
					threshold if stat_name == "Qi" else 0
				) if not fail_mode else not global_access.can_perform_action(
					threshold if stat_name == "Jing" else 0,
					threshold if stat_name == "Shen" else 0,
					threshold if stat_name == "Qi" else 0
				)
	
	return line

## Check if player can afford an active check
func _can_afford_active_check(line: DialogueLine) -> bool:
	var current_qi = global_access.get_var("Qi")
	var current_jing = global_access.get_var("Jing")
	var current_shen = global_access.get_var("Shen")
	
	# Check threshold requirement
	var stat_value = 0
	if line.check_stat == "Jing":
		stat_value = current_jing
	elif line.check_stat == "Shen":
		stat_value = current_shen
	elif line.check_stat == "Qi":
		stat_value = current_qi
	
	if stat_value < line.check_threshold:
		return false
	
	# Check costs
	if current_qi < line.check_cost_qi:
		return false
	if current_jing < line.check_cost_jing:
		return false
	if current_shen < line.check_cost_shen:
		return false
	
	return true

## Parse tags from a tag string
## Converts "# Character # Harry" to ["Character", "Harry"]
func parse_tags(tag_string: String) -> Array:
	if tag_string.is_empty():
		return []
	
	var tags = tag_string.split("#")
	var result: Array = []
	
	for tag in tags:
		var trimmed = tag.strip_edges()
		if not trimmed.is_empty():
			result.append(trimmed)
	
	return result

## Format a line for display
## Adds character name prefix, colors, and resource costs
func format_line_for_display(line: DialogueLine) -> String:
	var formatted = ""
	
	if line.character != null:
		formatted = "[color=#%s]%s[/color]: " % [
			line.character.character_color.to_html(false),
			line.character.character_name
		]
	
	formatted += line.text
	
	# Add active check indicator with costs
	if line.is_active_check:
		var cost_str = ""
		var costs = []
		
		if line.check_cost_qi > 0:
			costs.append("%dQi" % line.check_cost_qi)
		if line.check_cost_jing > 0:
			costs.append("%dJing" % line.check_cost_jing)
		if line.check_cost_shen > 0:
			costs.append("%dShen" % line.check_cost_shen)
		
		cost_str = ", ".join(costs)
		
		var color = "green" if line.check_available else "gray"
		var status = "✓" if line.check_available else "✗"
		
		formatted += " [color=%s][%s %s≥%d | Cost: %s][/color]" % [
			color, 
			status,
			line.check_stat, 
			line.check_threshold,
			cost_str if cost_str != "" else "Free"
		]
	
	return formatted
