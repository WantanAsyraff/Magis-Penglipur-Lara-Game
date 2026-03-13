class_name subjectData extends Resource

@export var subject_name: String
@export var subject_icon: Texture2D
@export var subject_id: String

@export_enum("Life Sciences", "Physical Sciences", "Mathematics", "Computer Science", "Social Sciences", 
"Humanities", "Arts", "Engineering", "Technology", "Language")
var subject_archetype: String = "Life Sciences"

@export_multiline var field_of_study: String
@export_multiline var theoretical_foundation: String
@export_multiline var casters_notes: String

@export_enum ("Mana Manipulation", "Ilmiah", "Alnur", "Alzalam","Semesta")
var magis_archetype: String = "Mana Manipulation"

@export_enum("Novice", "Intermediate", "Advanced", "Expert")
var magis_comprehension = "Novice"

@export_range(1,5) var difficulty_level: int

@export var prerequisites: Array[String] = [] # e.g., ["basic_biology"]
@export var contained_spells: Array[SpellData] = []
