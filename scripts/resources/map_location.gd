extends Resource
class_name MapLocation

@export var location_name: String = "Nome do Distrito"
# Nota: Adapte o tipo do Array para o formato que você usa no TimeManager (String ou Enum)
@export var required_time_periods: Array[String] = ["MORNING", "AFTERNOON", "EVENING", "NIGHT"] 
@export var spawn_table: SpawnTable
