class_name CourseData extends Resource

@export var course_name: String
@export var course_id: String
@export var course_archetype: String
@export_multiline var course_description: String

@export_enum ("Mana Manipulation", "Elementalist", "Technical", "Alnur", "Alzalam","Celestial")
var magis_archetype: String = "Mana Manipulation"

@export_enum("Novice", "Intermediate", "Advanced", "Expert")
var magis_comprehension = "Novice"

@export_range(1,5) var difficulty_level: int
@export var prerequisites: Array[String]
@export var subjects: Array[subjectData]
