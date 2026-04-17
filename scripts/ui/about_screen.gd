extends Control

const GITHUB_AUTHOR_URL: String = "https://github.com/ZhiH2333"
const GITHUB_REPO_URL: String = "https://github.com/ZhiH2333/Wild-Pig-Gun"


func _ready() -> void:
	%AuthorLinkBtn.pressed.connect(_on_author_link_pressed)
	%RepoLinkBtn.pressed.connect(_on_repo_link_pressed)
	%BackButton.pressed.connect(_on_back_pressed)


func _on_author_link_pressed() -> void:
	OS.shell_open(GITHUB_AUTHOR_URL)


func _on_repo_link_pressed() -> void:
	OS.shell_open(GITHUB_REPO_URL)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
