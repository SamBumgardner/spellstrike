# Singleton for defining player input mappings across the whole game
class_name InputMappingManager extends RefCounted

static var p1_input_mapping = InputRetriever.DEFAULT_P1
static var p2_input_mapping = InputRetriever.DEFAULT_P2