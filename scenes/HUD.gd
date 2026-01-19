extends CanvasLayer

@onready var _score_label: Label = $ScoreLabel

func _ready() -> void:
	# Connect to the Score signal
	Score.score_changed.connect(_on_score_changed)
	# Initialize display
	_update_score_display(Score.get_score())

func _on_score_changed(new_score: int) -> void:
	_update_score_display(new_score)

func _update_score_display(score: int) -> void:
	if _score_label:
		_score_label.text = "%d" % score
