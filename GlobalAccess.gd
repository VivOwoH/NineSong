extends Node

## Global singleton for player stats, ritual resources, and divine confrontation state
## Accessible from anywhere and from Dialogic scripts

# Player resources and state
var player_stats_flags: Dictionary = {
	# core stats
	"Jing": 10,		# 精 - Essence/Humanity
	"Qi": 20,		# 氣 - Energy/Action points (regen)
	"Shen": 10,		# 神 - Spirit/Divinity
	"Jing_max": 50,
	"Qi_max": 100,
	"Shen_max": 50,
	
	# Balance state (calculated from Jing/Shen)
	"humanity_level": 0,	# -10 to +10 (neg = more divine, pos = more human)
	"divinity_level": 0,	# -10 to +10 (neg = more human, pos = more divine)
	
	# Nine deity relationships (信 - faith/trust)
	"Relationships": {
		"Donghuan_Taiyi": 50,		# 东皇太一 - Eastern Sovereign
		"Yunzhong_Jun": 50,			# 云中君 - Cloud Sovereign
		"Xiang_Jun": 50,			# 湘君 - Lord of Xiang
		"Xiang_Furen": 50,			# 湘夫人 - Lady of Xiang
		"Da_Siming": 50,			# 大司命 - Greater Destiny
		"Shao_Siming": 50,			# 少司命 - Lesser Destiny
		"Dong_Jun": 50,				# 东君 - Sun God
		"He_Bo": 50,				# 河伯 - River Earl
		"Shan_Gui": 50,				# 山鬼 - Mountain Spirit
		"Guo_Shang": 50,			# 国殇 - Fallen Warriors
	},
	
	# Unlocked deity domain/abilities
	"Unlocked_Skills": {
		"Isolation": false,			# 山鬼 - tracking, survival
		"Illumination": false,		# 东君 - reveal lies
		"Destiny_Sight": false,		# 大司命 - see death
		"Cloud_Secrets": false,		# 云中君 - hidden knowledge
		"River_Empathy": false,		# 河伯/湘夫人 - emotional insight
		"Supreme_Authority": false,	# 东皇太一 - command truth
	},
	
	# Investigation progress
	"discovered_clues": [],
	"solved_murders": [],
	"current_chapter": 1,
	
	# World state flags
	"first_transformation_complete": false,
	"accused_of_first_murder": true,
	"gods_met": [],
	"offerings_collected": 0,
}

# Ritual confrontation actions
# Each deity will have different costs/effects for the same action
var confrontation_actions: Dictionary = {
	# 問 - Question (basic, safe probing)
	"Question": {
		"BASE_COST_QI": 1,
		"BASE_TRUST_GAIN": 10,
		"BASE_PRESSURE_RISK": 0,
		"DESCRIPTION": "Ask a question",
	},
	# 以人察神 - Human Insight (empathy, reading emotions)
	"Human_Insight": {
		"BASE_COST_QI": 2,
		"BASE_COST_JING": 1,
		"BASE_TRUST_GAIN": 15,
		"BASE_PRESSURE_RISK": 20,
		"REQUIRES_JING_MIN": 3,
		"DESCRIPTION": "See as a human",
	},
	# 以神問神 - Divine Authority (command truth)
	"Divine_Authority": {
		"BASE_COST_QI": 3,
		"BASE_COST_SHEN": 2,
		"BASE_TRUST_GAIN": 20,
		"BASE_PRESSURE_RISK": 40,
		"REQUIRES_SHEN_MIN": 8,
		"DESCRIPTION": "Demand as a god",
	},
	# 獻祭 - Offering (sacrifise)
	"Offering": {
		"BASE_COST_QI": 0,
		"BASE_TRUST_GAIN": 30,
		"BASE_PRESSURE_REDUCE": 40,
		"REQUIRES_JING_MIN": 20,
		"REQUIRES_SHEN_MIN": 20,
		"DESCRIPTION": "Sacrifice a part of your being",
		"VARIANTS": ["Jing", "Shen"],	# humanity/divinity to sacrifice
	},
}

# Per-deity modifiers to confrontation actions
var deity_responses: Dictionary = {
	"ShanGui": {  # 山鬼 - Mountain Spirit (wild, emotional, outsider)
		"Question": {
			"trust_multiplier": 1.0,
			"pressure_multiplier": 0.5,  # She's not easily offended
		},
		"Human_Insight": {
			"trust_multiplier": 1.5,  # Responds well to empathy
			"pressure_multiplier": 0.5,
			"jing_cost_modifier": -1,  # Costs less Jing (she's relatable)
		},
		"Divine_Authority": {
			"trust_multiplier": 0.3,  # Hates authority
			"pressure_multiplier": 3.0,  # Gets very hostile
		},
		"Offering": {
			"trust_multiplier": 1.2,
			"prefers": "Jing",  # Prefers human vulnerability
		},
	},
	"XiangFuRen": {  # 湘夫人 - Lady of Xiang (melancholic, graceful)
		"Question": {
			"trust_multiplier": 1.0,
			"pressure_multiplier": 1.0,
		},
		"Human_Insight": {
			"trust_multiplier": 1.3,  # Appreciates emotional understanding
			"pressure_multiplier": 1.5,  # Can be offended if you misjudge
		},
		"Divine_Authority": {
			"trust_multiplier": 0.8,
			"pressure_multiplier": 2.0,  # Doesn't like being commanded
		},
		"Offering": {
			"trust_multiplier": 1.5,  # Very moved by sacrifice
			"prefers": "Jing",
		},
	},
	"DongJun": {  # 东君 - Sun God (proud, radiant, hierarchical)
		"Question": {
			"trust_multiplier": 0.8,  # Finds basic questions tedious
			"pressure_multiplier": 1.2,
		},
		"Human_Insight": {
			"trust_multiplier": 0.5,  # Insulted by human perspective
			"pressure_multiplier": 2.5,
			"jing_cost_modifier": 1,  # Costs MORE Jing (harder to read)
		},
		"Divine_Authority": {
			"trust_multiplier": 1.5,  # Respects divine hierarchy
			"pressure_multiplier": 0.5,  # Less risky with high Shen
			"shen_requirement_modifier": 2,  # Needs even higher Shen (10 instead of 8)
		},
		"Offering": {
			"trust_multiplier": 1.0,
			"prefers": "Shen",  # Prefers divine sacrifice
		},
	},
	"HeBo": {  # 河伯 - River Earl (volatile, passionate)
		"Question": {
			"trust_multiplier": 0.7,
			"pressure_multiplier": 1.5,  # Gets impatient
		},
		"Human_Insight": {
			"trust_multiplier": 1.2,
			"pressure_multiplier": 1.8,  # Volatile - can go either way
		},
		"Divine_Authority": {
			"trust_multiplier": 0.6,
			"pressure_multiplier": 3.0,  # Very hostile to commands
		},
		"Offering": {
			"trust_multiplier": 2.0,  # Deeply moved by sacrifice
			"pressure_reduce_bonus": 20,
			"prefers": "Jing",
		},
	},
	"YunZhongJun": {  # 云中君 - Cloud Sovereign (distant, secretive)
		"Question": {
			"trust_multiplier": 1.2,  # Prefers indirect approach
			"pressure_multiplier": 0.8,
		},
		"Human_Insight": {
			"trust_multiplier": 0.8,
			"pressure_multiplier": 1.0,
			"jing_cost_modifier": 2,  # Very hard to read
		},
		"Divine_Authority": {
			"trust_multiplier": 1.0,
			"pressure_multiplier": 1.5,
		},
		"Offering": {
			"trust_multiplier": 0.9,  # Not very moved by emotion
			"prefers": "Shen",
		},
	},
	"XiangJun": {  # 湘君 - Lord of Xiang (separated lover, tragic)
		"Question": {
			"trust_multiplier": 1.0,
			"pressure_multiplier": 1.0,
		},
		"Human_Insight": {
			"trust_multiplier": 1.4,
			"pressure_multiplier": 1.2,
		},
		"Divine_Authority": {
			"trust_multiplier": 0.9,
			"pressure_multiplier": 1.8,
		},
		"Offering": {
			"trust_multiplier": 1.6,
			"prefers": "Jing",
		},
	},
	"DaSiMing": {  # 大司命 - Greater Destiny (death, fate)
		"Question": {
			"trust_multiplier": 0.9,
			"pressure_multiplier": 1.0,
		},
		"Human_Insight": {
			"trust_multiplier": 0.6,  # Unmoved by human emotion
			"pressure_multiplier": 1.5,
		},
		"Divine_Authority": {
			"trust_multiplier": 1.3,  # Respects divine will
			"pressure_multiplier": 1.0,
		},
		"Offering": {
			"trust_multiplier": 1.1,
			"prefers": "Shen",
		},
	},
	"ShaoSiMing": {  # 少司命 - Lesser Destiny (life, youth)
		"Question": {
			"trust_multiplier": 1.1,
			"pressure_multiplier": 0.9,
		},
		"Human_Insight": {
			"trust_multiplier": 1.3,
			"pressure_multiplier": 1.0,
		},
		"Divine_Authority": {
			"trust_multiplier": 1.0,
			"pressure_multiplier": 1.5,
		},
		"Offering": {
			"trust_multiplier": 1.4,
			"prefers": "Jing",
		},
	},
	"DongHuanTaiYi": {  # 东皇太一 - Supreme Sovereign (mysterious, ultimate)
		"Question": {
			"trust_multiplier": 0.5,  # Too trivial for the supreme god
			"pressure_multiplier": 2.0,
		},
		"Human_Insight": {
			"trust_multiplier": 0.3,  # Deeply insulted
			"pressure_multiplier": 4.0,
		},
		"Divine_Authority": {
			"trust_multiplier": 1.8,  # Only way to reach them
			"pressure_multiplier": 0.8,
			"shen_requirement_modifier": 5,  # Needs Shen 13+!
		},
		"Offering": {
			"trust_multiplier": 1.2,
			"prefers": "Shen",
		},
	},
	"GuoShang": {  # 国殇 - Fallen Warriors (vengeful, honor-bound)
		"Question": {
			"trust_multiplier": 0.8,
			"pressure_multiplier": 1.3,
		},
		"Human_Insight": {
			"trust_multiplier": 1.1,
			"pressure_multiplier": 1.5,
		},
		"Divine_Authority": {
			"trust_multiplier": 0.7,
			"pressure_multiplier": 2.5,
		},
		"Offering": {
			"trust_multiplier": 2.5,  # Honor demands respect for sacrifice
			"pressure_reduce_bonus": 30,
			"prefers": "Jing",  # Blood sacrifice theme
		},
	},
}

# Current confrontation state
var active_confrontation: Dictionary = {
	"deity": "",
	"trust": 0,        # current trust level (0-100)
	"pressure": 0,        # current pressure level (0-100)
	"turn": 0,
	"active": false,
}

# Last action result (for dialogue feedback)
var last_action_result: Dictionary = {
	"success": false,
	"trust_change": 0,
	"pressure_change": 0,
	"info_gained": "",
}

## Get a variable from the stats dictionary
## Supports nested access with dot notation (e.g., "Relationships.ShanGui")
func get_var(var_name: String):
	var keys = var_name.split(".")
	var current = player_stats_flags
	
	for key in keys:
		if current is Dictionary and current.has(key):
			current = current[key]
		else:
			push_warning("Variable '%s' not found" % var_name)
			return null
	
	return current

## Set a variable in the stats dictionary
func set_var(var_name: String, value) -> void:
	var keys = var_name.split(".")
	
	if keys.size() == 1:
		player_stats_flags[var_name] = value
		return
	
	var current = player_stats_flags
	for i in range(keys.size() - 1):
		var key = keys[i]
		if not current.has(key):
			current[key] = {}
		current = current[key]
	
	current[keys[-1]] = value

## Calculate balance state from Jing/Shen
func update_balance() -> void:
	var jing = player_stats_flags["Jing"]
	var shen = player_stats_flags["Shen"]
	# Humanity level: positive = more human
	player_stats_flags["humanity_level"] = jing - 10
	# Divinity level: positive = more divine
	player_stats_flags["divinity_level"] = shen - 10

## Start a ritual confrontation with a deity
func start_confrontation(deity_name: String) -> void:
	active_confrontation["deity"] = deity_name
	active_confrontation["trust"] = player_stats_flags["Relationships"][deity_name]
	active_confrontation["pressure"] = 0
	active_confrontation["turn"] = 0
	active_confrontation["active"] = true
	
	print("Started confrontation with %s | Starting Trust: %d" % [deity_name, active_confrontation["trust"]])

## End the current confrontation
func end_confrontation(success: bool) -> void:
	if not active_confrontation["active"]:
		return
	
	var deity = active_confrontation["deity"]
	
	# Save final trust level back to relationships
	player_stats_flags["Relationships"][deity] = active_confrontation["Trust"]
	
	print("Ended confrontation with %s | Final Trust: %d | Success: %s" % 
		[deity, active_confrontation["trust"], success])
	
	active_confrontation["active"] = false

## Perform a confrontation action
func do_confrontation_action(action_type: String, deity_name: String, offering_variant: String = "") -> bool:
	if not confrontation_actions.has(action_type):
		push_error("Action type '%s' not found" % action_type)
		return false
	
	if not deity_responses.has(deity_name):
		push_error("Deity '%s' not found" % deity_name)
		return false
	
	var action = confrontation_actions[action_type]
	var deity_mods = deity_responses[deity_name][action_type]
	
	# Handle Offering variant
	var jing_cost = action.get("BASE_COST_JING", 0)
	var shen_cost = action.get("BASE_COST_SHEN", 0)
	var jing_permanent_cost = 0
	var shen_permanent_cost = 0
	
	if action_type == "Offering":
		if offering_variant == "":
			# Default to deity's preferred offering
			offering_variant = deity_mods.get("prefers", "Jing")
		if offering_variant == "Jing":
			jing_permanent_cost = 10
		elif offering_variant == "Shen":
			shen_permanent_cost = 10
		else:
			push_error("Invalid offering variant: %s" % offering_variant)
			return false
		
		# Check if this matches deity's preference
		var preference_bonus = 1.0
		if offering_variant == deity_mods.get("prefers", ""):
			preference_bonus = 1.5  # 50% bonus if it's what they prefer
		# Apply preference bonus to trust gain
		deity_mods["trust_multiplier"] = deity_mods.get("trust_multiplier", 1.0) * preference_bonus
	
	# Add deity modifiers to costs
	jing_cost += deity_mods.get("jing_cost_modifier", 0)
	shen_cost += deity_mods.get("shen_cost_modifier", 0)
	
	# Calculate actual costs
	var qi_cost = action.get("BASE_COST_QI", 0)
	
	# Check requirements
	var min_jing = action.get("REQUIRES_JING_MIN", 0)
	var min_shen = action.get("REQUIRES_SHEN_MIN", 0) + deity_mods.get("shen_requirement_modifier", 0)
	
	var current_qi = player_stats_flags["Qi"]
	var current_jing = player_stats_flags["Jing"]
	var current_shen = player_stats_flags["Shen"]
	
	# Validate resources (including permanent costs)
	if current_qi < qi_cost:
		print("Not enough Qi! Need %d, have %d" % [qi_cost, current_qi])
		return false
	if current_jing < jing_cost + jing_permanent_cost or current_jing < min_jing:
		print("Not enough Jing! Need %d, have %d" % [max(jing_cost + jing_permanent_cost, min_jing), current_jing])
		return false
	if current_shen < shen_cost + shen_permanent_cost or current_shen < min_shen:
		print("Not enough Shen! Need %d, have %d" % [max(shen_cost + shen_permanent_cost, min_shen), current_shen])
		return false
	
	# Consume resources
	player_stats_flags["Qi"] -= qi_cost
	player_stats_flags["Jing"] -= (jing_cost + jing_permanent_cost)
	player_stats_flags["Shen"] -= (shen_cost + shen_permanent_cost)
	
	# Calculate effects with deity multipliers
	var trust_gain = int(action.get("BASE_TRUST_GAIN", 0) * deity_mods.get("trust_multiplier", 1.0))
	var pressure_risk = int(action.get("BASE_PRESSURE_RISK", 0) * deity_mods.get("pressure_multiplier", 1.0))
	var pressure_reduce = action.get("BASE_PRESSURE_REDUCE", 0) + deity_mods.get("pressure_reduce_bonus", 0)
	
	# Determine success
	var success = true
	
	var trust_change = trust_gain if success else 0
	var pressure_change = -pressure_reduce if success else pressure_risk
	
	# Apply to active confrontation
	if active_confrontation["active"] and active_confrontation["deity"] == deity_name:
		active_confrontation["xin"] = clamp(active_confrontation["xin"] + trust_change, 0, 100)
		active_confrontation["wei"] = clamp(active_confrontation["wei"] + pressure_change, 0, 100)
		active_confrontation["turn"] += 1
	
	# Store result
	last_action_result = {
		"success": success,
		"trust_change": trust_change,
		"pressure_change": pressure_change,
		"deity": deity_name,
		"action": action_type,
		"offering_variant": offering_variant if action_type == "Offering" else "",
		"permanent_cost": jing_permanent_cost if offering_variant == "Jing" else shen_permanent_cost,
	}
	
	update_balance()
	
	var cost_msg = ""
	if jing_permanent_cost > 0:
		cost_msg = " [PERMANENT: -%dJing]" % jing_permanent_cost
	elif shen_permanent_cost > 0:
		cost_msg = " [PERMANENT: -%dShen]" % shen_permanent_cost
	
	print("%s → %s%s | Qi:%d→%d | Trust:%+d | Pressure:%+d | %s" % 
		[action_type, deity_name, cost_msg, current_qi, player_stats_flags["Qi"], 
		trust_change, pressure_change, "SUCCESS" if success else "FAILED"])
	
	return success

## Passive check for showing/hiding dialogue options
## Examples: show 以神問神 if Shen >= 8
func can_perform_action(min_jing: int = 0, min_shen: int = 0, min_qi: int = 0) -> bool:
	var jing = player_stats_flags["Jing"]
	var shen = player_stats_flags["Shen"]
	var qi = player_stats_flags["Qi"]
	
	return jing >= min_jing and shen >= min_shen and qi >= min_qi

## Check relationship level
func get_relationship(deity: String) -> int:
	return player_stats_flags["Relationships"].get(deity, 50)

## Add offering (when player handles human offerings)
func add_offering(offering_type: String, amount: int = 1) -> void:
	player_stats_flags["offerings_collected"] += amount
	print("Collected %d %s offering(s)" % [amount, offering_type])

## Convert offerings to resources at shrine
func convert_offerings(jing_amount: int, shen_amount: int, qi_amount: int) -> void:
	player_stats_flags["Jing"] = clamp(player_stats_flags["Jing"] + jing_amount, 0, player_stats_flags["Jing_max"])
	player_stats_flags["Shen"] = clamp(player_stats_flags["Shen"] + shen_amount, 0, player_stats_flags["Shen_max"])
	player_stats_flags["Qi"] = clamp(player_stats_flags["Qi"] + qi_amount, 0, player_stats_flags["Qi_max"])
	
	update_balance()
	
	print("Converted offerings | Jing: %d | Shen: %d | Qi: %d" % 
		[player_stats_flags["Jing"], player_stats_flags["Shen"], player_stats_flags["Qi"]])
