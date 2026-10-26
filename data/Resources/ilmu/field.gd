class_name FieldData extends Resource

@export var field_id: StringName
@export var display_name: String
@export_multiline var description: String
@export var related_fields: Array[FieldData] = []
