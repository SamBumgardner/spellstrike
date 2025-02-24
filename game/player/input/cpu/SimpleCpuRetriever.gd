class_name SimpleCpuRetriever extends InputRetriever

func retrieve_input() -> Dictionary:
    var result = EMPTY.duplicate()

    for key in result:
        if key in ["l", "r"]:
            result[key] = randi() % 2
        else:
            result[key] = 1 if randf() < .01 else 0
    
    return result
