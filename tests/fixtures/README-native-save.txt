Actual Godot save evidence fixtures, generated2026-10-26.
Engine:4.6.3.stable.official.7d41c59c4.
Generator:generate_native_save.gd.txt, copied to a disposable .gd and run with --headless --path native --script <generator> -- <temporary-output>.
The fixture uses the real SaveStore.reset/save_data and its checksum routine. GP315, Mud ownership/equipment, one completed course/star and decimal best time/tiny checkpoint yaw are explicitly seeded TOOLING fixtures, not legitimate gameplay or mobile evidence. No user profile/device/adb executable is accessed.
native-canonical-actual-godot.json contains actual Store._canonical outputs for zero, decimal, integer-valued, tiny/precision-boundary numeric probes. Tests compare them and a live native _read_record oracle to the Python read-only auditor; GODOT_BIN is honored before PATH. The live oracle is explicitly skipped if no Godot exists, while checked-in actual fixtures still run.
No keys, transport identifiers, personal data or online wallet are included.
native-schema3-actual-godot.json SHA256:68c8113dc96b8deccf5258346dd714836d280eecc4f4552833fed73539bd8b92
