"""Read-only native save evidence validation; never migrate or repair device data.

This checks envelope integrity and bounded core schema-3 invariants. It does not
prove that the main scene restored the data, that a run was legitimate, or that
every gameplay/progression rule holds. The caller preserves raw bytes first.
"""
from __future__ import annotations

import hashlib
import hmac
import json
import math
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
CURRENT_SCHEMA = 3
MAX_BYTES = 262144
MAX_GP = 1000000000
SAFE_ID = re.compile(r"[a-z0-9_:-]{1,128}\Z")


def _unique_object(pairs):
    value = {}
    for key, item in pairs:
        if key in value:
            raise ValueError("Duplicate JSON object key")
        value[key] = item
    return value


def _reject_constant(_value):
    raise ValueError("Non-finite JSON constant")


def _godot_string(value):
    # Pinned4.6.3 String::json_escape. Current profile IDs contain no controls;
    # retaining the runtime's exact escaping also covers Unicode fixture data.
    escaped = value.replace("\\", "\\\\")
    for source, target in (("\b", "\\b"), ("\f", "\\f"), ("\n", "\\n"),
                           ("\r", "\\r"), ("\t", "\\t"), ("\v", "\\v"), ('"', '\\"')):
        escaped = escaped.replace(source, target)
    return '"' + escaped + '"'


def _godot_json(value):
    # Godot4.6.3 JSON::_stringify(full_precision=false) uses fixed decimals,
    # precision=max(1,14-floor(log10(abs(number)))), capped at32. String::num
    # trims trailing zeros but keeps one after the decimal point. Python repr
    # and raw-token hashing are NOT equivalent (notably1e-7 and1.000...001).
    # Source read2026-10-26, free official HTTPS (no paid retrieval):
    # https://github.com/godotengine/godot/blob/4.6.3-stable/core/io/json.cpp
    # https://github.com/godotengine/godot/blob/4.6.3-stable/core/string/ustring.cpp
    if type(value) in (int, float):
        number = float(value)
        if not math.isfinite(number):
            raise ValueError("Non-finite number")
        if number == 0:
            return "0.0"
        precision = min(32, max(1, 14 - math.floor(math.log10(abs(number)))))
        rendered = format(number, f".{precision}f").rstrip("0")
        return rendered + "0" if rendered.endswith(".") else rendered
    if isinstance(value, dict):
        return "{" + ",".join(_godot_string(key) + ":" + _godot_json(value[key]) for key in sorted(value)) + "}"
    if isinstance(value, list):
        return "[" + ",".join(_godot_json(item) for item in value) + "]"
    if isinstance(value, str):
        return _godot_string(value)
    return json.dumps(value, ensure_ascii=False, allow_nan=False, separators=(",", ":"))


def canonical_payload(payload: dict) -> str:
    """Match SaveStore's serialize/parse/serialize, including number rounding."""
    normalized = json.loads(_godot_json(payload), parse_constant=_reject_constant,
                            object_pairs_hook=_unique_object)
    return _godot_json(normalized)


def _checksum_matches(payload: dict, checksum: str) -> bool:
    return hmac.compare_digest(hashlib.sha256(canonical_payload(payload).encode()).hexdigest(), checksum)


def _integer(value, lower=0, upper=MAX_GP):
    return type(value) in (int, float) and math.isfinite(value) and lower <= value <= upper and value == int(value)


def _finite(value, lower, upper):
    return type(value) in (int, float) and math.isfinite(value) and lower <= value <= upper


def _ids(value, allowed=None, maximum=512):
    return (isinstance(value, list) and len(value) <= maximum and
            all(isinstance(item, str) and SAFE_ID.fullmatch(item) and
                (allowed is None or item in allowed) for item in value) and
            len(set(value)) == len(value))


def _schema3_errors(payload):
    errors = []
    economy_definition = json.loads((ROOT / "native/data/economy.json").read_text())
    region_definition = json.loads((ROOT / "native/data/regions.json").read_text())
    foundational = set(economy_definition["foundational_items"])
    items = {item["id"]: item["category"] for item in economy_definition["items"]}
    vehicles = set(economy_definition["vehicle_mastery_thresholds_for_new_profiles"])
    regions = {region["id"] for region in region_definition["regions"]}
    categories = {"tires", "suspension_upgrade", "gearing", "drivetrain", "engine"}
    item_categories = dict(items, road="tires", trail="tires", giant="tires")
    build = payload.get("build")
    owned = payload.get("owned")
    equipped = payload.get("equipped")
    owned_vehicles = payload.get("owned_vehicles")
    if not _integer(payload.get("gp")):
        errors.append("GP must be a finite whole number from0 to1000000000.")
    valid_owned = _ids(owned, foundational | items.keys()) and foundational.issubset(owned)
    if not valid_owned:
        errors.append("Owned equipment must contain unique known items and the free foundational inventory.")
    valid_vehicles = _ids(owned_vehicles, vehicles) and "buggy" in owned_vehicles
    if not valid_vehicles:
        errors.append("Owned vehicles must be unique known identities including the starting buggy.")
    if not isinstance(build, dict) or not all(isinstance(build.get(key), str) for key in ("vehicle", "tires", "suspension", "paint")):
        errors.append("Build choices are missing or malformed.")
    else:
        if not valid_vehicles or build["vehicle"] not in owned_vehicles:
            errors.append("The selected vehicle must be owned.")
        if not valid_owned or build["tires"] not in owned or item_categories.get(build["tires"]) != "tires":
            errors.append("Selected tires must be known and owned.")
        if build["suspension"] not in {"soft", "firm"} or build["paint"] not in {"orange", "cyan", "purple", "lime"}:
            errors.append("Foundation suspension/paint choices are unknown.")
    if not isinstance(equipped, dict) or not categories.issubset(equipped):
        errors.append("Equipped upgrade categories are missing or malformed.")
    else:
        for category in categories:
            item = equipped[category]
            if not isinstance(item, str) or (item and (not valid_owned or item not in owned or item_categories.get(item) != category)) or (category == "tires" and not item):
                errors.append("Equipped parts must be owned and match their equipment category.")
                break
        if isinstance(build, dict) and equipped.get("tires") != build.get("tires"):
            errors.append("Build and equipped tire choices must agree.")
    stars = payload.get("stars")
    if not _ids(stars, maximum=128) or any(len(item.split(":")) != 2 or item.split(":")[1] not in {"completion", "event_skill", "suitable_build_route"} for item in stars):
        errors.append("Mastery must contain unique bounded event/objective claims.")
    admitted = payload.get("regions")
    if not _ids(admitted, regions) or not {"garage_valley", "festival_circuit"}.issubset(admitted):
        errors.append("Destination admissions must be known and retain the starting regions.")
    if not _ids(payload.get("completed"), maximum=12) or not _ids(payload.get("discoveries"), maximum=64):
        errors.append("Completed courses/discoveries must be bounded unique identifiers.")
    custom = payload.get("custom")
    if not isinstance(custom, list) or not 4 <= len(custom) <= 16 or not all(item in {"flat", "ramp", "bumps", "dip", "bridge", "rollers"} for item in custom) or custom[0] != "flat" or custom[-1] != "flat":
        errors.append("Private track must retain4–16 known pieces and flat endpoints.")
    best = payload.get("best")
    if not isinstance(best, dict) or any(not isinstance(key, str) or not SAFE_ID.fullmatch(key) or not _finite(value, 0, 86400) or not 0 < value < 86400 for key, value in best.items()):
        errors.append("Best times must be finite positive local-course values below one day.")
    settings = payload.get("settings")
    if not isinstance(settings, dict) or any(type(settings.get(key)) is not bool for key in ("muted", "reduced_motion", "one_touch")) or not _finite(settings.get("volume"), 0, 1) or not _finite(settings.get("steering_sensitivity"), 0.5, 1.5):
        errors.append("Audio/accessibility/control settings are malformed.")
    claims = payload.get("claims")
    if not isinstance(claims, dict) or len(claims) > 512 or any(not isinstance(key, str) or not SAFE_ID.fullmatch(key) or not (type(value) is bool or isinstance(value, str) and len(value) <= 80 and SAFE_ID.fullmatch(value)) for key, value in claims.items()):
        errors.append("Permanent reward/purchase claims are malformed or exceed the bounded ledger.")
    ledger = payload.get("economy")
    if not isinstance(ledger, dict) or not _integer(ledger.get("last_settled")) or not _integer(ledger.get("next_run"), 1, MAX_GP + 1) or ledger.get("next_run", 0) <= ledger.get("last_settled", 0) or not isinstance(ledger.get("active"), dict) or not isinstance(ledger.get("recent"), list) or len(ledger.get("recent", [])) > 64:
        errors.append("Run reservation/recent-ledger structure is malformed.")
    else:
        active = ledger["active"]
        if active and (not _integer(active.get("id"), 1) or not ledger["last_settled"] < active["id"] < ledger["next_run"] or not isinstance(active.get("event"), str) or not SAFE_ID.fullmatch(active["event"]) or active.get("kind") not in {"tutorial", "short_2d_clear", "trail_3d_clear", "delivery_clear", "custom_track", "sandbox"}):
            errors.append("Active run must be a valid reserved monotonic run.")
        for entry in ledger["recent"]:
            if not isinstance(entry, dict) or not _integer(entry.get("gp")) or not _integer(entry.get("balance")) or not _integer(entry.get("run")):
                errors.append("Recent wallet entries contain malformed amounts/run identifiers.")
                break
    explore = payload.get("explore")
    if not isinstance(explore, dict) or not isinstance(admitted, list) or explore.get("region") not in admitted or not isinstance(explore.get("checkpoint"), list) or len(explore["checkpoint"]) != 3 or not all(_finite(v, -3000, 3000) for v in explore["checkpoint"]) or not _finite(explore["checkpoint"][1], -20, 100) or not _finite(explore.get("yaw"), -math.pi, math.pi):
        errors.append("Explore checkpoint must be finite and inside an admitted destination's supported coordinate bounds.")
    if payload.get("goal") not in items:
        errors.append("Pinned upgrade goal is unknown.")
    return errors


def validate_save_bytes(data: bytes) -> dict:
    """Classify preserved bytes without rewriting/migrating the evidence."""
    result = {"status": "invalid", "current_schema": CURRENT_SCHEMA, "errors": [],
              "checksum": "not_checked", "scope": "Envelope integrity and bounded core profile invariants; not main-scene restoration or legitimate-play proof."}
    try:
        if len(data) > MAX_BYTES:
            raise ValueError("Native save exceeds the runtime262144-byte bound.")
        # Native FileAccess writes/reads UTF-8. json.loads(bytes) would also
        # auto-detect UTF-16/32, accepting encodings the game does not write.
        record = json.loads(data.decode("utf-8"), parse_constant=_reject_constant, object_pairs_hook=_unique_object)
        if not isinstance(record, dict):
            raise ValueError("Native save root must be an object.")
        schema = record.get("schema", record.get("version"))
        if not _integer(schema, 1, math.inf):
            raise ValueError("Envelope schema must be a positive whole number.")
        result["schema"] = int(schema)
        payload = record.get("payload", record)
        # As in SaveStore, a future schema is protected before assuming that
        # its payload still uses today's object representation.
        if schema > CURRENT_SCHEMA:
            result.update(status="unsupported_future", checksum="not_checked_future")
            return result
        if not isinstance(payload, dict):
            raise ValueError("Native payload must be an object.")
        version = payload.get("version", schema if schema < CURRENT_SCHEMA else None)
        result["payload_version"] = version
        if _integer(version, CURRENT_SCHEMA + 1, math.inf):
            result.update(status="unsupported_future", checksum="not_checked_future")
            return result
        if not _integer(version, 1) or version != schema:
            raise ValueError("Envelope schema and payload version must agree.")
        if schema >= 2:
            checksum = record.get("checksum")
            if not isinstance(checksum, str) or not re.fullmatch(r"[0-9a-f]{64}", checksum):
                result["checksum"] = "missing_or_malformed"
                raise ValueError("Schema2/3 requires a lowercaseSHA256 checksum.")
            if not _checksum_matches(payload, checksum):
                result["checksum"] = "mismatch"
                raise ValueError("Native payload checksum does not match.")
            result["checksum"] = "verified"
        else:
            result["checksum"] = "not_required_legacy"
        if schema < CURRENT_SCHEMA:
            if not (isinstance(payload.get("build"), dict) or schema == 1 and isinstance(payload.get("vehicle"), str)):
                raise ValueError("Legacy build fields are missing.")
            result["status"] = "legacy"
            result["note"] = "Recognized legacy evidence; migration/current-game restoration still requires device verification. No bytes were migrated."
            return result
        result["errors"] = _schema3_errors(payload)
        if not result["errors"]:
            result["status"] = "valid"
        return result
    except (ValueError, UnicodeError, TypeError, OverflowError, RecursionError) as error:
        result["errors"].append(str(error))
        return result
