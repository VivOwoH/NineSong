extends RefCounted
class_name DialogueLine

## Represents a single line of dialogue with all its metadata
## Includes character info, text, tags, and resource-based choices

enum LineType {
	NORMAL,      # Regular dialogue line
	CHOICE,      # Player choice
	ACTIVE_CHECK,  # Resource-based active check (costs Qi/Jing/Shen)
	NARRATION    # Narration/description
}

var text: String = ""
var line_type: LineType = LineType.NORMAL
var character: Character = null
var tags: Array[String] = []

# Active checks (resource-based)
var is_active_check: bool = false
var check_stat: String = ""  # "Jing", "Shen", "Qi"
var check_threshold: int = 0  # Minimum required to access the option
var check_cost_qi: int = 0
var check_cost_jing: int = 0
var check_cost_shen: int = 0
var check_available: bool = false  # Can player afford/access this?

# Passive check data (conditional visibility based on stats)
var is_passive_check: bool = false
var passive_check_visible: bool = true

# Choice index (for player choices)
var choice_index: int = -1

func _init(p_text: String = "", p_type: LineType = LineType.NORMAL):
	text = p_text
	line_type = p_type

func is_choice() -> bool:
	return line_type == LineType.CHOICE or line_type == LineType.ACTIVE_CHECK

func is_visible() -> bool:
	# Passive checks may not be visible
	if is_passive_check:
		return passive_check_visible
	return true
