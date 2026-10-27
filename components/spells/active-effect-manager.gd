class_name ActiveEffectManager extends RefCounted
# Owned and ticked by a HitboxComponent; no free-standing timer callbacks.
enum StackPolicy { REFRESH, REPLACE, STACK, IGNORE }
signal changed(key: String)
signal applied(key: String)
signal expired(key: String)
signal periodic(key: String, data: Dictionary)
var entries: Array[Dictionary] = []

func apply(key: String, duration: float, data: Dictionary, source_id: String = "", policy: StackPolicy = StackPolicy.REFRESH, max_stacks: int = 1, beneficial: bool = false) -> bool:
	if key.is_empty() or not is_finite(duration) or duration <= 0:
		return false
	var matching: Array[Dictionary] = []
	for entry in entries:
		if entry.key == key:
			matching.append(entry)
	if not matching.is_empty():
		match policy:
			StackPolicy.IGNORE:
				return false
			StackPolicy.REFRESH:
				matching[0].remaining = maxf(matching[0].remaining, duration)
				matching[0].data = data.duplicate(true)
				matching[0].source = source_id
				changed.emit(key)
				applied.emit(key)
				return true
			StackPolicy.REPLACE:
				remove(key)
			StackPolicy.STACK:
				if matching.size() >= clampi(max_stacks, 1, 32):
					return false
	var interval: float = data.get("interval", 1.0)
	if not is_finite(interval):
		return false
	interval = clampf(interval, 0.05, 3600.0)
	entries.append({"key": key, "remaining": duration, "data": data.duplicate(true), "source": source_id, "beneficial": beneficial, "tick": interval, "interval": interval})
	changed.emit(key)
	applied.emit(key)
	return true

func tick(delta: float) -> void:
	for entry in entries.duplicate():
		if not entries.has(entry):
			continue
		var active_delta := minf(delta, entry.remaining)
		entry.remaining -= delta
		entry.tick -= active_delta
		var count := 0
		while entry.tick <= 0.00001 and count < 64 and entries.has(entry):
			entry.tick += entry.interval
			count += 1
			periodic.emit(entry.key, entry.data)
		if entry.remaining <= 0 and entries.has(entry):
			entries.erase(entry)
			changed.emit(entry.key)
			if not has(entry.key):
				expired.emit(entry.key)

func has(key: String) -> bool:
	for e in entries:
		if e.key == key:
			return true
	return false

func magnitude(key: String) -> float:
	var total := 0.0
	for e in entries:
		if e.key == key:
			total += float(e.data.get("amount", 0.0))
	return total

func remove(key: String) -> void:
	var existed := has(key)
	entries = entries.filter(func(e): return e.key != key)
	if existed:
		changed.emit(key)
		expired.emit(key)

func clear(beneficial: int = -1) -> void:
	for e in entries.duplicate():
		if beneficial == -1 or e.beneficial == bool(beneficial):
			remove(e.key)

func snapshot() -> Dictionary:
	var result := {}
	for e in entries:
		result[e.key] = {"timer": e.remaining, "data": e.data.duplicate(true), "source": e.source}
	return result

func remove_source(source_id: String) -> void:
	var keys: Array[String] = []
	for entry in entries.duplicate():
		if entry.source == source_id:
			entries.erase(entry)
			if not keys.has(entry.key):
				keys.append(entry.key)
	for key in keys:
		changed.emit(key)
		if not has(key):
			expired.emit(key)
