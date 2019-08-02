import struct
import sys

print("""Tournament IDs - you can use them in your sider modules.
This information has been extracted from the game files.
Many thanks to digitalfoxx !!! - for showing which BINs to look into""")

for x in ["CompetitionRegulation.bin", "CompetitionRegulation4.bin"]:
    print("""

%s

""" % x)

    with open(x + ".unzlib","rb") as f:
        d = f.read()
        l = len(d)
        off = 0
        while off < l:
            t = d[off:off+0x30]
            tid = struct.unpack("<H", t[2:4])[0]
            name = t[0x10:].decode('utf-8').strip('\0')
            print("%s - %d" % (name, tid))
            off = off + 0x30

print("")
