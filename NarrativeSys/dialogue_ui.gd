extends Control

## Simple dialogue UI that displays narrative content with resource tracking
## Connects to NarrativeManager to show dialogue and choices

@onready var dialogue_label: RichTextLabel = $VBoxContainer/DialogueLabel
@onready var choices_container: VBoxContainer = $VBoxContainer/ChoicesContainer
@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var resources_label: Label = $VBoxContainer/ResourceLabel

var narrative_manager: NarrativeManager

func _ready():
	# Create and setup narrative manager
	narrative_manager = NarrativeManager.new()
	add_child(narrative_manager)
	
	# Connect signals
	narrative_manager.dialogue_line_ready.connect(_on_dialogue_line_ready)
	narrative_manager.choices_ready.connect(_on_choices_ready)
	narrative_manager.dialogue_ended.connect(_on_dialogue_ended)
	narrative_manager.resources_changed.connect(_on_resources_changed)
	
	continue_button.pressed.connect(_on_continue_pressed)
	
	# Setup example story
	setup_example_story()
	
	# Show initial resources
	_update_resources_display()

func setup_example_story():
	# Create example characters
	var char_db = CharacterDatabase.new()
	
	var narrator = Character.new()
	narrator.character_name = "Narrator"
	narrator.character_color = Color(0.7, 0.7, 0.7)
	char_db.add_character(narrator)
	
	var shan_gui = Character.new()
	shan_gui.character_name = "Mountain Spirit"
	shan_gui.character_color = Color(0.4, 0.8, 0.5)
	char_db.add_character(shan_gui)
	
	var inner_voice = Character.new()
	inner_voice.character_name = "Inner Voice"
	inner_voice.character_color = Color(0.9, 0.7, 0.4)
	char_db.add_character(inner_voice)
	
	narrative_manager.setup(char_db)
	
	# Create example story with resource-based checks
	var story = [
		{
			"text": "You stand before the ancient shrine deep in the mountain forest.",
			"tags": "# Character # Narrator",
		},
		{
			"text": "A presence stirs in the mist. The Mountain Spirit appears before you.",
			"tags": "# Character # Narrator",
		},
		{
			"text": "Why have you come to my domain, mortal?",
			"tags": "# Character # Mountain Spirit",
		},
		{
			"text": "You feel the pull between your human essence and divine power.",
			"tags": "# Character # Inner Voice # PassiveCheck # Pass Jing 3",
		},
		{
			"text": "Your divine nature resonates with this place.",
			"tags": "# Character # Inner Voice # PassiveCheck # Pass Shen 8",
		},
		{
			"text": "How do you respond?",
			"tags": "",
			"choices": [
				{
					"text": "Speak with humble honesty (uses Jing - humanity)",
					"tags": "# ActiveCheck # Jing 3 2 1 0",
				},
				{
					"text": "Command with divine authority (uses Shen - divinity)",
					"tags": "# ActiveCheck # Shen 8 3 0 2",
				},
				{
					"text": "Simply observe and listen (cheap option)",
					"tags": "# ActiveCheck # Qi 1 1 0 0",
				},
				{
					"text": "Say nothing and leave.",
					"tags": "",
				},
			]
		},
		{
			"text": "The spirit regards you with ancient eyes.",
			"tags": "# Character # Mountain Spirit",
		},
		{
			"text": "Your choice has been noted by the gods.",
			"tags": "# Character # Narrator",
		},
	]
	
	narrative_manager.load_story(story)
	narrative_manager.start_dialogue()

func _on_dialogue_line_ready(line: DialogueLine):
	# Format and display the line
	var formatted_text = narrative_manager.format_line(line)
	
	# Append to existing dialogue (scroll log style)
	if dialogue_label.text != "":
		dialogue_label.text += "\n\n"
	dialogue_label.text += formatted_text
	
	# Show continue button if no choices
	continue_button.visible = not line.is_choice()

func _on_choices_ready(choices: Array[DialogueLine]):
	# Clear existing choice buttons
	for child in choices_container.get_children():
		child.queue_free()
	
	# Create button for each choice
	for i in range(choices.size()):
		var choice = choices[i]
		var button = Button.new()
		button.text = narrative_manager.format_line(choice)
		
		# Disable if can't afford active check
		if choice.is_active_check and not choice.check_available:
			button.disabled = true
		
		button.pressed.connect(_on_choice_selected.bind(i))
		choices_container.add_child(button)
	
	# Hide continue button when showing choices
	continue_button.visible = false

func _on_choice_selected(choice_index: int):
	narrative_manager.select_choice(choice_index)
	
	# Clear choices
	for child in choices_container.get_children():
		child.queue_free()

func _on_continue_pressed():
	narrative_manager.continue_dialogue()

func _on_dialogue_ended():
	dialogue_label.text += "\n\n[THE END]"
	continue_button.visible = false

func _on_resources_changed():
	_update_resources_display()

func _update_resources_display():
	var resources = narrative_manager.get_current_resources()
	resources_label.text = "Qi (氣): %d/%d | Jing (精): %d/%d | Shen (神): %d/%d" % [
		resources.qi, resources.qi_max,
		resources.jing, resources.jing_max,
		resources.shen, resources.shen_max
	]
