extends Control

# Oletetaan, että käyttäjä on jo kirjautunut Firebaseen
# id_token on globalsissa
# Huom. Firestoren collection nimenä on tässä koodissa käytetty items. 

var idtoken: String
var project_id = "YOUR_FIREBASE_PROJECT_ID"

@onready var top_10 = %Top10Container


func _ready():
	# Haetaan idtoken
	if (Globals.id_token):
		idtoken = Globals.id_token
	else:
		print("Ei tallennettua authia")
	print("idToken: ", idtoken)


func write_to_firestore(nimi: String, pisteet: int, id_token: String) -> void:
	var url = "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/items" % project_id

	var json_data = {
		"fields": {
			"nimi": { "stringValue": nimi },
			"pisteet": { "integerValue": str(pisteet) }
		}
	}

	var http = HTTPRequest.new()
	add_child(http)
	http.connect("request_completed", Callable(self, "_on_firestore_completed"))

	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + id_token
	]

	var json_bytes = JSON.stringify(json_data)

	var err = http.request(
		url,
		headers,
		HTTPClient.METHOD_POST,
		json_bytes
	)

	if err != OK:
		print("Firestore POST failed:", err)


func _on_firestore_completed(_result, response_code, _headers, body):
	print("Firestore response:", response_code)
	print("Firestore response body:",body.get_string_from_utf8())
	# Haetaan top 10 pista Firestoresta
	get_scores()


func get_scores() -> void:
	var url = "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents:runQuery" % project_id

	
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer %s" % idtoken
	]

	var query = {
		"structuredQuery": {
			"from": [{ "collectionId": "items" }],
			"orderBy": [{
				"field": { "fieldPath": "pisteet" },
				"direction": "DESCENDING",
			}],
			"limit": 10
		}
	}

	var http := HTTPRequest.new()
	add_child(http)
	http.connect("request_completed", Callable(self, "_on_scores_received"))

	var err = http.request(
		url,
		headers,
		HTTPClient.METHOD_POST,
		JSON.stringify(query)
	)

	if err != OK:
		print("Request error:", err)


func _on_scores_received(_result, response_code, _headers, body):
	print("Firestore response code:", response_code)
	if response_code != 200:
		print("Error:", body.get_string_from_utf8())
		return

	# Tyhjennetään vanhat rivit
	var children = top_10.get_children()
	for child in children:
		child.queue_free()
	
	var data = JSON.parse_string(body.get_string_from_utf8())
	if typeof(data) != TYPE_ARRAY:
		print("Odottamaton data:", data)
		return

	for doc in data:
		if doc.has("document"):
			var fields = doc["document"]["fields"]
			var nimi = fields["nimi"]["stringValue"]
			var pisteet = int(fields["pisteet"]["integerValue"])

			# Luodaan HBoxContainer rivi
			var row = HBoxContainer.new()

			var name_label = Label.new()
			name_label.text = nimi
			name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(name_label)

			var score_label = Label.new()
			score_label.text = str(pisteet)
			score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(score_label)

			top_10.add_child(row)

func _on_save_button_button_down():
	# Lähetä POST pyyntö backendille
	var nimi = %NameLineEdit.text
	var pisteet = %ScoreLineEdit.text
	# Validointi: nimi ei saa olla tyhjä
	%TextLabel.text = ""
	if nimi.strip_edges() == "":
		%TextLabel.text = "Virhe: nimi ei voi olla tyhjä"
		return

	# Validointi: pisteet pitää olla kokonaisluku
	if not pisteet.is_valid_int():
		%TextLabel.text = "Virhe: pisteet pitää olla kokonaisluku"
		return
	write_to_firestore(nimi, int(pisteet), idtoken)


func _on_logout_button_button_down():
	Globals.id_token = ""

	# Vaihdetaan login-sceneen
	get_tree().change_scene_to_file("res://authentication.tscn")
