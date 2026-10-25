extends RefCounted
## Original offline content. Values describe a forgiving arcade model, not real cars.

const VEHICLES := {
	"buggy": {"label": "Sunny Buggy", "description": "A balanced first ride. Light, springy and ready for little hills.", "speed": 245.0, "acceleration": 205.0, "grip": 1.0, "wheelbase": 82.0, "clearance": 18.0, "mass": 1.0, "unlock": 0},
	"rover": {"label": "Moon Rover", "description": "A tall six-wheel explorer. Steady on bumps, with a gentle top speed.", "speed": 220.0, "acceleration": 182.0, "grip": 1.25, "wheelbase": 100.0, "clearance": 29.0, "mass": 1.3, "unlock": 1},
	"rally": {"label": "Comet Rally", "description": "A low, lively coupe. Quick on straights; rough hills need a careful build.", "speed": 295.0, "acceleration": 235.0, "grip": 0.9, "wheelbase": 90.0, "clearance": 13.0, "mass": 0.95, "unlock": 2},
	"truck": {"label": "Parcel Truck", "description": "A sturdy delivery truck. A long body smooths hills, but takes time to get going.", "speed": 232.0, "acceleration": 155.0, "grip": 1.18, "wheelbase": 114.0, "clearance": 22.0, "mass": 1.65, "unlock": 3},
	"kart": {"label": "Firefly Kart", "description": "A tiny open racer. Fast starts and quick balance; bumpy landings slow it down.", "speed": 278.0, "acceleration": 275.0, "grip": 0.82, "wheelbase": 62.0, "clearance": 10.0, "mass": 0.7, "unlock": 4},
	"crawler": {"label": "Rock Crawler", "description": "A wide, big-wheeled climber. Great hill grip, trading speed for steady progress.", "speed": 205.0, "acceleration": 190.0, "grip": 1.6, "wheelbase": 104.0, "clearance": 34.0, "mass": 1.45, "unlock": 5}
}

const TIRES := {
	"road": {"label": "Road tires", "description": "MORE speed on smooth ground / LESS grip on hills", "radius": 21.0, "speed": 1.12, "grip": 0.74},
	"trail": {"label": "Trail tires", "description": "BALANCED speed and hill grip / MEDIUM wheels", "radius": 28.0, "speed": 1.0, "grip": 1.1},
	"giant": {"label": "Giant tires", "description": "MORE grip and softer bumps / LESS top speed", "radius": 36.0, "speed": 0.87, "grip": 1.48},
	"mud": {"label": "Mud tires", "description": "MORE mud traction / LESS pavement speed", "radius": 30.0, "speed": 0.90, "grip": 1.45},
	"sand": {"label": "Sand paddle tires", "description": "MORE soft-sand drive / LESS pavement corner grip", "radius": 32.0, "speed": 0.94, "grip": 1.35},
	"rock": {"label": "Rock tires", "description": "MORE rock control / LESS top speed", "radius": 34.0, "speed": 0.84, "grip": 1.65},
	"snow": {"label": "Snow tires", "description": "MORE snow grip / LESS dry-ground speed", "radius": 29.0, "speed": 0.88, "grip": 1.30}
}

const SUSPENSIONS := {
	"soft": {"label": "Soft springs", "description": "SOFTER landings / MORE body bounce", "damping": 8.0, "landing": 0.97, "stiffness": 62.0},
	"firm": {"label": "Firm springs", "description": "STEADIER body / MORE speed lost on hard landings", "damping": 15.0, "landing": 0.84, "stiffness": 115.0}
}

const PAINTS := {"orange": "#F6A44C", "cyan": "#69D2D2", "purple": "#B5A0E8", "lime": "#BBD875"}

const PIECES := {
	"flat": {"label": "Straight", "description": "A smooth rest between hills", "height": 0.0, "waves": 1.0},
	"ramp": {"label": "Big hill", "description": "One smooth climbing hill", "height": 88.0, "waves": 1.0},
	"bumps": {"label": "Bumpy patch", "description": "Three small bumps", "height": 27.0, "waves": 3.0},
	"dip": {"label": "Valley", "description": "Dip down, then climb out", "height": -70.0, "waves": 1.0},
	"bridge": {"label": "High bridge", "description": "Climb to a wide flat top", "height": 102.0, "waves": 1.0},
	"rollers": {"label": "Twin rollers", "description": "Two rolling hills", "height": 53.0, "waves": 2.0}
}

const COURSES := [
	{"id": "meadow", "label": "Meadow Hello", "description": "A first hill, a few bumps, and room to find your rhythm.", "pieces": ["flat", "ramp", "bumps", "flat"], "vehicle": "buggy", "unlock": 0, "palette": "meadow", "challenge": 14.0},
	{"id": "orchard", "label": "Orchard Roll", "description": "Twin rollers lead to a quiet valley.", "pieces": ["flat", "rollers", "flat", "dip", "flat"], "vehicle": "rover", "unlock": 1, "palette": "orchard", "challenge": 20.0},
	{"id": "coast", "label": "Coast Dash", "description": "Long smooth straights invite a faster tire build.", "pieces": ["flat", "flat", "ramp", "flat", "flat", "flat"], "vehicle": "rally", "unlock": 2, "palette": "coast", "challenge": 19.0},
	{"id": "parcel", "label": "Parcel Parkway", "description": "Two wide bridges and a bumpy delivery lane.", "pieces": ["flat", "bridge", "flat", "bumps", "bridge", "flat"], "vehicle": "truck", "unlock": 3, "palette": "town", "challenge": 26.0},
	{"id": "firefly", "label": "Firefly Sprint", "description": "Quick small hills on a compact sunset circuit.", "pieces": ["flat", "bumps", "rollers", "flat", "flat"], "vehicle": "kart", "unlock": 4, "palette": "sunset", "challenge": 19.0},
	{"id": "quarry", "label": "Pebble Peak", "description": "A tall climb, deep valley, and high bridge reward hill grip.", "pieces": ["flat", "ramp", "dip", "bridge", "rollers", "flat"], "vehicle": "crawler", "unlock": 5, "palette": "quarry", "challenge": 29.0},
	{"id": "dunes", "label": "Dune Ribbon", "description": "Wave after wave across the warm sand.", "pieces": ["flat", "rollers", "ramp", "rollers", "dip", "ramp", "flat"], "vehicle": "buggy", "unlock": 6, "palette": "dunes", "challenge": 30.0},
	{"id": "moon", "label": "Moon Garden", "description": "Long calm sections surround a crater and moon bumps.", "pieces": ["flat", "dip", "flat", "bumps", "dip", "flat", "bridge", "flat"], "vehicle": "rover", "unlock": 7, "palette": "moon", "challenge": 35.0},
	{"id": "river", "label": "River Bridges", "description": "Three different bridge approaches, with room to brake.", "pieces": ["flat", "bridge", "dip", "bridge", "flat", "ramp", "bridge", "flat"], "vehicle": "truck", "unlock": 8, "palette": "river", "challenge": 38.0},
	{"id": "switchback", "label": "Comet Climb", "description": "Fast straights alternate with climbs and a final roller pair.", "pieces": ["flat", "flat", "ramp", "dip", "flat", "ramp", "rollers", "flat"], "vehicle": "rally", "unlock": 9, "palette": "autumn", "challenge": 29.0},
	{"id": "lantern", "label": "Lantern Lane", "description": "A long bumpy evening ride with a gentle finish.", "pieces": ["flat", "bumps", "dip", "bumps", "flat", "rollers", "bumps", "ramp", "flat"], "vehicle": "kart", "unlock": 10, "palette": "night", "challenge": 36.0},
	{"id": "summit", "label": "Great Garage Tour", "description": "Every piece in one grand adventure. Finish at your own pace.", "pieces": ["flat", "bridge", "ramp", "dip", "rollers", "bumps", "bridge", "dip", "ramp", "flat"], "vehicle": "crawler", "unlock": 11, "palette": "summit", "challenge": 49.0}
]

static func course_by_id(id: String) -> Dictionary:
	for course in COURSES:
		if course.id == id:
			return course
	return COURSES[0]

static func normalize_build(build: Dictionary) -> Dictionary:
	return {
		"vehicle": build.get("vehicle", "buggy") if VEHICLES.has(build.get("vehicle", "buggy")) else "buggy",
		"tires": build.get("tires", "trail") if TIRES.has(build.get("tires", "trail")) else "trail",
		"suspension": build.get("suspension", "soft") if SUSPENSIONS.has(build.get("suspension", "soft")) else "soft",
		"paint": build.get("paint", "orange") if PAINTS.has(build.get("paint", "orange")) else "orange"
	}
