extends Node

var _total_score_label: Label = null
var _factor_one_label: Label = null
var _factor_two_label: Label = null

func set_score_labels(total_label: Label, factor1_label: Label, factor2_label: Label) -> void:
	_total_score_label = total_label
	_factor_one_label = factor1_label
	_factor_two_label = factor2_label

func reset_score_panel() -> void:
	if _total_score_label and _factor_one_label and _factor_two_label:
		_total_score_label.text = "0"
		_factor_one_label.text = "0"
		_factor_two_label.text = "0"

	else:
		printerr("ScoreManager: Labels are not set")
