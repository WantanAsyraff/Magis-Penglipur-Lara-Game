class_name AcademicValidator extends RefCounted

static func validate_course(course: CourseData) -> PackedStringArray:
	var errors := PackedStringArray()
	if course == null or course.course_id.is_empty():
		return PackedStringArray(["Missing course or ID"])
	var subjects := {}
	for subject in course.subjects:
		if subject == null or subject.subject_id.is_empty():
			errors.append("Missing subject or ID")
		elif subjects.has(subject.subject_id):
			errors.append("Duplicate subject ID: " + subject.subject_id)
		else:
			subjects[subject.subject_id] = subject
	for id in subjects:
		_visit(id, subjects, [], [], errors)
	return errors

static func _visit(id: String, subjects: Dictionary, visiting: Array, visited: Array, errors: PackedStringArray) -> void:
	if id in visiting:
		errors.append("Circular prerequisite: " + id)
		return
	if id in visited:
		return
	visiting.append(id)
	for required in subjects[id].prerequisites:
		# Cross-course prerequisites are resolved by explicit completed-subject IDs.
		if subjects.has(required):
			_visit(required, subjects, visiting, visited, errors)
	visiting.erase(id)
	visited.append(id)
