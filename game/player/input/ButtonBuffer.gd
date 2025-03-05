class_name ButtonBuffer extends RefCounted

const QUEUE_LENGTH: int = 8

var circular_queue: Array
var head: int = 0
var tail: int = 0

func _init():
    circular_queue = []
    circular_queue.resize(QUEUE_LENGTH)
    circular_queue.fill(0)

func push(new_input: Dictionary) -> void:
    var int_input = InputHelper.to_int(new_input)

    circular_queue[head] = int_input
    head = (head + 1) % QUEUE_LENGTH

func clear() -> void:
    tail = head

func get_buffered_input(retrieve_last_n: int) -> Dictionary:
    var start_index := head - retrieve_last_n
    if start_index < 0:
        start_index += QUEUE_LENGTH
    
    if start_index < head and tail < head:
        start_index = max(tail, start_index)
    elif start_index < head and tail > head:
        pass
    elif start_index > head and tail < head:
        start_index = tail
    elif start_index > head and tail > head:
        start_index = max(tail, start_index)
    
    var i = start_index
    var result: int = 0
    while i != head:
        result = result & 0b001111 # remove directional inputs
        result = result | circular_queue[i]
        i = (i + 1) % QUEUE_LENGTH
    
    # directional inputs from current frame are preserved
    return InputHelper.to_dict(result)
