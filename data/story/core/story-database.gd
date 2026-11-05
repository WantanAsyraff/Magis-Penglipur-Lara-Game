class_name StoryDatabase extends Resource
@export var arcs: Array[StoryArcData] = []
@export var flags: Array[StoryFlagDefinition] = []
@export var choices: Array[StoryChoiceData] = []
@export var migrations: StoryIdMigrations
