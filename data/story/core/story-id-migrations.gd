class_name StoryIdMigrations extends Resource
## Explicit, reviewed aliases for story-owned IDs. World flags stay under QuestManager.
@export var arcs: Dictionary[String, String] = {}
@export var chapters: Dictionary[String, String] = {}
@export var stages: Dictionary[String, String] = {}
@export var variables: Dictionary[String, String] = {}
@export var choices: Dictionary[String, String] = {}
@export var options: Dictionary[String, String] = {}
@export var transitions: Dictionary[String, String] = {}
@export var actions: Dictionary[String, String] = {}
@export var dialogues: Dictionary[String, String] = {}
func mapped(kind: String, id: String) -> String:
 var table: Dictionary = get(kind)
 return String(table.get(id, id))
