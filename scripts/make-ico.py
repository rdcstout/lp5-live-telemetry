#!/usr/bin/env python3
import struct
import sys
from pathlib import Path

output = Path(sys.argv[1])
images = [(Path(value), int(Path(value).stem.split("x")[-1])) for value in sys.argv[2:]]
payloads = [(path.read_bytes(), size) for path, size in images]

header = struct.pack("<HHH", 0, 1, len(payloads))
offset = 6 + 16 * len(payloads)
entries = []
for payload, size in payloads:
    dimension = 0 if size >= 256 else size
    entries.append(struct.pack("<BBBBHHII", dimension, dimension, 0, 0, 1, 32, len(payload), offset))
    offset += len(payload)

output.write_bytes(header + b"".join(entries) + b"".join(payload for payload, _ in payloads))
