import re
import sys

if len(sys.argv) != 3:
    print("Usage: python convert_hex_layer.py input.dts output.dts", file=sys.stderr)
    sys.exit(1)

file_in, file_out = sys.argv[1], sys.argv[2]
with open(file_in) as f:
    txt = f.read()

txt = re.sub(r'0x([0-9a-fA-F]+)', lambda m: str(int(m.group(1), 16)), txt)

with open(file_out, 'w') as f:
    f.write(txt)
