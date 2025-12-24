extends HBoxContainer

@onready var name_label = $NameLabel
@onready var level_label = $LevelLabel
@onready var bar = $ProgressBar
@onready var buy_button = $BuyButton

var producer_data
var buy_callback

func setup(data, callback):
	producer_data = data
	buy_callback = callback
	update_ui()

func update_ui():
	name_label.text = producer_data["name"]
	level_label.text = "x" + str(producer_data["level"])

	bar.max_value = max(1, producer_data["level"] * producer_data["base_income"])
	bar.value = producer_data["level"] * producer_data["base_income"]

	buy_button.text = "+ ($" + str(round(producer_data["cost"])) + ")"

func _on_BuyButton_pressed():
	buy_callback.call(producer_data)
	update_ui()
