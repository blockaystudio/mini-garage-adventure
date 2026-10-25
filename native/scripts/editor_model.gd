extends RefCounted
const Content = preload("res://scripts/content.gd")
const TrackModel = preload("res://scripts/track_model.gd")
const MIN_PIECES := 4
const MAX_PIECES := 16
const MAX_UNDO := 64
var pieces: Array
var history: Array = []

func _init(source: Array = ["flat", "ramp", "bumps", "flat"]) -> void:
	pieces = source.duplicate(true)
	if not TrackModel.validate(pieces).is_empty():
		pieces = ["flat", "ramp", "bumps", "flat"]

func _remember() -> void:
	history.append(pieces.duplicate(true))
	if history.size() > MAX_UNDO:
		history.pop_front()

func change(index: int, piece: String) -> bool:
	if index < 0 or index >= pieces.size() or not Content.PIECES.has(piece) or pieces[index] == piece:
		return false
	_remember()
	pieces[index] = piece
	return true

func select(index: int, piece: String) -> bool:
	return change(index, piece)

func append(piece: String) -> bool:
	if pieces.size() >= MAX_PIECES or not Content.PIECES.has(piece):
		return false
	_remember()
	pieces.append(piece)
	return true

func remove(index: int) -> bool:
	if pieces.size() <= MIN_PIECES or index < 0 or index >= pieces.size():
		return false
	_remember()
	pieces.remove_at(index)
	return true

func undo() -> bool:
	if history.is_empty():
		return false
	pieces = history.pop_back()
	return true

func validate() -> String:
	if pieces.size() < MIN_PIECES:
		return "Add at least four pieces."
	if pieces.size() > MAX_PIECES:
		return "A track can have up to sixteen pieces."
	return TrackModel.validate(pieces)
