#!/usr/bin/env python3
"""Inspect an exported test APK using only the Python standard library.

This checks the binary manifest and packaged inventory, not installation or
runtime traffic. Verify the cryptographic APK signature separately with apksigner.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import sys
import zipfile


def manifest_elements(data):
    def u16(offset):
        return struct.unpack_from("<H", data, offset)[0]

    def u32(offset):
        return struct.unpack_from("<I", data, offset)[0]

    def length8(offset):
        value = data[offset]
        return (((value & 0x7f) << 8) | data[offset + 1], offset + 2) if value & 0x80 else (value, offset + 1)

    strings, elements = [], []
    if u16(0) != 3 or u32(4) != len(data):
        raise ValueError("Not a bounded Android binary XML document")
    offset = u16(2)
    while offset < len(data):
        kind, header, size = struct.unpack_from("<HHI", data, offset)
        if size < header or header < 8 or offset + size > len(data):
            raise ValueError("Invalid binary XML chunk bounds")
        if kind == 1:  # RES_STRING_POOL_TYPE
            count, flags, start = u32(offset + 8), u32(offset + 16), offset + u32(offset + 20)
            if count > len(data) // 4:
                raise ValueError("Invalid string count")
            for index in range(count):
                pos = start + u32(offset + header + index * 4)
                if flags & 0x100:
                    _, pos = length8(pos)
                    length, pos = length8(pos)
                    text = data[pos:pos + length].decode("utf-8")
                else:
                    length = u16(pos)
                    pos += 2
                    if length & 0x8000:
                        length = ((length & 0x7fff) << 16) | u16(pos)
                        pos += 2
                    text = data[pos:pos + length * 2].decode("utf-16le")
                strings.append(text)
        elif kind == 0x102:  # RES_XML_START_ELEMENT_TYPE
            name = strings[u32(offset + 20)]
            start, attribute_size, count = u16(offset + 24), u16(offset + 26), u16(offset + 28)
            attrs = {}
            if attribute_size < 20 or offset + 16 + start + count * attribute_size > offset + size:
                raise ValueError("Invalid XML attribute bounds")
            for index in range(count):
                pos = offset + 16 + start + index * attribute_size
                attr_name, raw, value_kind, value = strings[u32(pos + 4)], u32(pos + 8), data[pos + 15], u32(pos + 16)
                if raw != 0xffffffff:
                    value = strings[raw]
                elif value_kind == 3:
                    value = strings[value]
                elif value_kind == 0x12:
                    value = bool(value)
                attrs[attr_name] = value
            elements.append({"tag": name, "attributes": attrs})
        offset += size
    return elements


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("apk", type=Path)
    args = parser.parse_args()
    with zipfile.ZipFile(args.apk) as archive:
        elements = manifest_elements(archive.read("AndroidManifest.xml"))
        files = archive.namelist()
        library_alignment = {}
        for info in archive.infolist():
            if info.filename.startswith("lib/") and info.filename.endswith(".so"):
                binary = archive.read(info)
                if binary[:6] != b"\x7fELF\x02\x01":
                    raise ValueError("Expected little-endian 64-bit native library")
                program_offset = struct.unpack_from("<Q", binary, 32)[0]
                entry_size, count = struct.unpack_from("<HH", binary, 54)
                alignments = []
                for index in range(count):
                    offset = program_offset + index * entry_size
                    if struct.unpack_from("<I", binary, offset)[0] == 1:
                        alignments.append(struct.unpack_from("<Q", binary, offset + 48)[0])
                library_alignment[info.filename] = {"elf_load_alignments": alignments, "zip_compressed": info.compress_type != zipfile.ZIP_STORED}
    manifest = next(item["attributes"] for item in elements if item["tag"] == "manifest")
    application = next(item["attributes"] for item in elements if item["tag"] == "application")
    sdk = next(item["attributes"] for item in elements if item["tag"] == "uses-sdk")
    permissions = [item["attributes"].get("name") for item in elements if item["tag"].startswith("uses-permission")]
    forbidden_files = [name for name in files if name.startswith(("assets/tests/", "assets/shared/", "assets/server/", "assets/play/"))]
    licenses = [name for name in files if "/licenses/" in name]
    failures = []
    if permissions:
        failures.append(f"Unexpected requested permissions: {permissions}")
    if application.get("allowBackup") is not False:
        failures.append("Android allowBackup is not false")
    if application.get("debuggable") is not True:
        failures.append("Expected a debug test APK")
    if manifest.get("package") != "org.example.minigarage.test":
        failures.append("Unexpected test package identity")
    if forbidden_files:
        failures.append("Reference/test files shipped")
    expected_libraries = {f"lib/{architecture}/{name}" for architecture in ("arm64-v8a", "x86_64") for name in ("libgodot_android.so", "libc++_shared.so")}
    if set(library_alignment) != expected_libraries:
        failures.append("Unexpected or missing native libraries in test APK")
    if any(not item["elf_load_alignments"] or min(item["elf_load_alignments"]) < 16384 for item in library_alignment.values()):
        failures.append("Native library ELF LOAD alignment below 16KiB")
    if not any(name.endswith("GODOT_LICENSE.txt") for name in licenses) or not any(name.endswith("GODOT_COPYRIGHT.txt") for name in licenses):
        failures.append("Required engine/license notices missing")
    print(json.dumps({
        "artifact": str(args.apk), "bytes": args.apk.stat().st_size,
        "sha256": hashlib.file_digest(args.apk.open("rb"), "sha256").hexdigest(),
        "manifest": manifest, "application": application, "sdk": sdk,
        "requested_permissions": permissions,
        "native_libraries": [name for name in files if name.startswith("lib/")],
        "native_library_alignment": library_alignment,
        "license_files": licenses, "forbidden_files": forbidden_files,
        "failures": failures,
        "scope": "Static inspection only; debug signature, installation and device runtime are separate checks."
    }, indent=2))
    return bool(failures)


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, ValueError, KeyError, IndexError, struct.error, StopIteration, zipfile.BadZipFile) as error:
        print(f"APK INSPECTION FAILED: {error}", file=sys.stderr)
        sys.exit(1)
