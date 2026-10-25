extends RefCounted
## A private linear course built from smooth, continuously joined terrain pieces.
const Content = preload("res://scripts/content.gd")
const SECTION_LENGTH := 360.0
const BASE_HEIGHT := 460.0
const MIN_PIECES := 4
const MAX_PIECES := 16
const DEFAULT_PIECES := ["flat", "ramp", "bumps", "flat"]

static func validate(pieces: Variant) -> String:
	if not pieces is Array:
		return "Choose a row of track pieces."
	if pieces.size() < MIN_PIECES:
		return "Add at least four pieces, including a straight start and finish."
	if pieces.size() > MAX_PIECES:
		return "A track can have up to sixteen pieces."
	for piece in pieces:
		if not piece is String or not Content.PIECES.has(piece):
			return "One piece is unknown. Replace it before driving."
	if pieces.front() != "flat" or pieces.back() != "flat":
		return "Start and finish with a straight piece so the course is reachable."
	return ""

static func length_for(pieces: Array) -> float:
	return maxf(SECTION_LENGTH * pieces.size(), SECTION_LENGTH * MIN_PIECES)

static func terrain(x: float, pieces: Array) -> float:
	if not is_finite(x) or pieces.is_empty():
		return BASE_HEIGHT
	var section := int(floor(x / SECTION_LENGTH))
	if section < 0 or section >= pieces.size():
		return BASE_HEIGHT
	var key: String = str(pieces[section])
	if not Content.PIECES.has(key):
		return BASE_HEIGHT
	# Each tile has a 32px flat shoulder. sin² has zero derivative at both joins.
	var progress := (fmod(x, SECTION_LENGTH) - 32.0) / (SECTION_LENGTH - 64.0)
	if progress <= 0.0 or progress >= 1.0:
		return BASE_HEIGHT
	var shape: Dictionary = Content.PIECES[key]
	if key == "bridge":
		var ramp_progress := clampf(minf(progress, 1.0 - progress) / 0.32, 0.0, 1.0)
		return BASE_HEIGHT - float(shape.height) * (0.5 - 0.5 * cos(PI * ramp_progress))
	return BASE_HEIGHT - float(shape.height) * pow(sin(PI * progress * float(shape.waves)), 2)

static func slope(x: float, pieces: Array, span: float = 12.0) -> float:
	return (terrain(x + span, pieces) - terrain(x - span, pieces)) / (2.0 * span)
