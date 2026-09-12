# SPDX-License-Identifier: GPL-3.0-or-later
"""Release gate for the community APK (spec Section 12.3 and the Phase 9
checklist): the binary must define no Google Play services, Firebase, Play
Billing, or RevenueCat classes (F-Droid rejects proprietary libraries by
scanning the binary, not the source), and carry no key-shaped strings.

Classes are read from each dex file's class_defs table, so only classes the
APK actually ships count. A plugin may still name an absent Google class
(geolocator keeps a fused-provider client it never instantiates once the Play
artifacts are excluded); those dangling references are reported but do not
fail the check.

Usage: python3 tool/check_apk_clean.py <path to apk>
Exit status 0 when clean, 1 when anything is found, 2 on a usage error.
"""
import re
import struct
import sys
import zipfile

# Class prefixes (dex descriptors) that must not be defined in a community build.
FORBIDDEN_PREFIXES = [
    "Lcom/google/android/gms/",
    "Lcom/google/firebase/",
    "Lcom/android/billingclient/",
    "Lcom/revenuecat/",
]

# Secret shapes, checked across every file in the archive (dex, native
# libraries, assets). The app has no keys by design (CLAUDE.md), so any hit
# is a leak.
SECRET_PATTERNS = [
    ("Google API key", re.compile(rb"AIza[0-9A-Za-z_\-]{35}")),
    ("Stripe live key", re.compile(rb"sk_live_[0-9A-Za-z]{10,}")),
    ("private key block", re.compile(rb"-----BEGIN [A-Z ]*PRIVATE KEY-----")),
    ("RevenueCat key", re.compile(rb"(goog|appl)_[0-9A-Za-z]{20,}")),
    ("AWS access key", re.compile(rb"AKIA[0-9A-Z]{16}")),
]


def _uleb128(data, off):
    """Decode a ULEB128 at off; returns (value, next offset)."""
    value = 0
    shift = 0
    while True:
        byte = data[off]
        off += 1
        value |= (byte & 0x7F) << shift
        if not byte & 0x80:
            return value, off
        shift += 7


def dex_classes(data):
    """The descriptors of every class a dex file defines, plus every type it
    names (dex format: header, string_ids, type_ids, class_defs)."""
    (string_ids_size, string_ids_off, type_ids_size, type_ids_off) = struct.unpack_from(
        "<IIII", data, 0x38
    )
    (class_defs_size, class_defs_off) = struct.unpack_from("<II", data, 0x60)

    def string_at(idx):
        (data_off,) = struct.unpack_from("<I", data, string_ids_off + 4 * idx)
        _utf16_len, start = _uleb128(data, data_off)
        end = data.index(b"\x00", start)
        return data[start:end].decode("utf-8", "replace")

    types = []
    for i in range(type_ids_size):
        (descriptor_idx,) = struct.unpack_from("<I", data, type_ids_off + 4 * i)
        types.append(string_at(descriptor_idx))
    defined = []
    for i in range(class_defs_size):
        (class_idx,) = struct.unpack_from("<I", data, class_defs_off + 32 * i)
        defined.append(types[class_idx])
    return defined, types


def main(argv):
    if len(argv) != 2:
        print(__doc__)
        return 2
    path = argv[1]
    problems = []
    notes = []
    with zipfile.ZipFile(path) as apk:
        names = apk.namelist()
        dex_names = [n for n in names if re.fullmatch(r"classes\d*\.dex", n)]
        if not dex_names:
            problems.append("no classes.dex in the archive")
        for name in dex_names:
            defined, referenced = dex_classes(apk.read(name))
            for prefix in FORBIDDEN_PREFIXES:
                bad = [c for c in defined if c.startswith(prefix)]
                if bad:
                    problems.append(
                        f"{name}: {len(bad)} class(es) defined under {prefix}, "
                        f"for example {bad[0]}"
                    )
                dangling = [
                    c for c in referenced if c.startswith(prefix) and c not in defined
                ]
                if dangling:
                    notes.append(
                        f"{name}: {len(dangling)} dangling reference(s) to {prefix} "
                        f"(named, not shipped)"
                    )
        for name in names:
            data = apk.read(name)
            for label, pattern in SECRET_PATTERNS:
                match = pattern.search(data)
                if match:
                    shown = match.group(0)[:12].decode("ascii", "replace")
                    problems.append(f"{name}: {label} ({shown}...)")
    for note in notes:
        print(f"note: {note}")
    if problems:
        print(f"FAIL {path}")
        for p in problems:
            print(f"  {p}")
        return 1
    print(
        f"OK {path}: no Google, Firebase, billing, or RevenueCat classes defined; "
        f"no key-shaped strings ({len(dex_names)} dex, {len(names)} entries)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
