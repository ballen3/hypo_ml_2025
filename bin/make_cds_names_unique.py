#!/usr/bin/env python3
import sys
from collections import defaultdict

# Keep track of seen Name fields
seen_names = defaultdict(int)

for line in sys.stdin:
    if line.startswith("#") or line.strip() == "":
        print(line, end="")
        continue

    fields = line.rstrip("\n").split("\t")
    if len(fields) != 9:
        print(line, end="")
        continue

    feature_type = fields[2]
    attrs = fields[8]

    # Only check genes and mRNAs
    if feature_type not in ("gene", "mRNA"):
        print(line, end="")
        continue

    # Find the Name= attribute
    parts = attrs.split(";")
    new_parts = []
    for part in parts:
        if part.startswith("Name="):
            name_val = part.split("=", 1)[1]
            seen_names[name_val] += 1
            count = seen_names[name_val]
            if count > 1:
                # append _2, _3 etc
                name_val = f"{name_val}_{count}"
            part = f"Name={name_val}"
        new_parts.append(part)

    fields[8] = ";".join(new_parts)
    print("\t".join(fields))
