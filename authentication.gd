# Authentikointi (ilman pluginia) suoraan Firebaseen
# Huom. turvallisempi olisi käyttää välissä backendia, joka piilottaisi api-avaimen.

extends Control

var api_key = "YOUR_FIREBASE_WEB_API_KEY"
var next_scene_path = "res://firebase_test.tscn"

func _on_login_button_pressed():
	var email = %EmailLineEdit.text
	var password = %PasswordLineEdit.text
	perform_login(email, password)

func perform_login(email: String, password: String) -> void:
	var url = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=%s" % api_key
	var body = {
		"email": email,
		"password": password,
		"returnSecureToken": true
	}
	var json_body = JSON.stringify(body)
	
	var http = HTTPRequest.new()
	add_child(http)
	http.connect("request_completed", Callable(self, "_on_login_request_completed"))
	http.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, json_body)


func _on_login_request_completed(_result, response_code, _headers, body):
	if response_code != 200:
		var err_data = JSON.parse_string(body.get_string_from_utf8())
		%StateLabel.text = "Login failed: %s" % err_data.get("error", {}).get("message", "Unknown")
		return
	
	var data = JSON.parse_string(body.get_string_from_utf8())
	var id_token = data.get("idToken", "")
	print("Login success! idToken:", id_token)
	
	# Tallennus Globalsiin
	Globals.id_token = data.get("idToken", "")
	
	%StateLabel.text = "Login success!"
	get_tree().change_scene_to_file(next_scene_path)


func _on_signup_button_button_down():
	var email = %EmailLineEdit.text
	var password = %PasswordLineEdit.text
	firebase_signup(email, password)


func firebase_signup(email: String, password: String) -> void:
	var url = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=%s" % api_key
	var body = {
		"email": email,
		"password": password,
		"returnSecureToken": true
	}
	var json_body = JSON.stringify(body)

	var http = HTTPRequest.new()
	add_child(http)
	http.connect("request_completed", Callable(self, "_on_signup_request_completed"))
	http.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, json_body)


func _on_signup_request_completed(_result, response_code, _headers, body):
	if response_code != 200:
		var err_data = JSON.parse_string(body.get_string_from_utf8())
		%StateLabel.text = "Sign up failed: %s" % err_data.get("error", {}).get("message", "Unknown")
		return

	var data = JSON.parse_string(body.get_string_from_utf8())
	Globals.id_token = data.get("idToken", "")

	%StateLabel.text = "Sign up success!"
	get_tree().change_scene_to_file(next_scene_path)
