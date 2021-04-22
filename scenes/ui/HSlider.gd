extends HSlider

func _on_HSlider_value_changed(value):
	$Label.text = str(value)
