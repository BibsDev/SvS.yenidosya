"""Boş, geçerli bir Excel 97-2004 (.xls, BIFF8) dosyası üretir.
Kullanım: python3 -I Scripts/make_xls.py Resources/Templates/blank.xls"""
import struct, sys

def rec(rid, data=b""):
    return struct.pack("<HH", rid, len(data)) + data

def u16(v): return struct.pack("<H", v)

def short_str(s):                       # ShortXLUnicodeString (8-bit)
    b = s.encode("latin-1"); return struct.pack("<BB", len(b), 0) + b

def bof(kind):                          # 0x0005 = workbook globals, 0x0010 = worksheet
    return rec(0x0809, struct.pack("<4H2I", 0x0600, kind, 0x0DBB, 0x07CC, 0, 6))

def font():                             # Arial 10pt
    return rec(0x0031, struct.pack("<5H4B", 200, 0, 0x7FFF, 400, 0, 0, 0, 0, 0) + short_str("Arial"))

STYLE_XF0 = bytes.fromhex("00000000F5FF20000000000000000000 0000C020".replace(" ", ""))
STYLE_XFN = bytes.fromhex("00000000F5FF200000F4000000000000 0000C020".replace(" ", ""))
CELL_XF   = bytes.fromhex("000000000100200000000000000000000000C020")

def sheet_name_record(offset):
    return rec(0x0085, struct.pack("<IBB", offset, 0, 0) + short_str("Sayfa1"))

def globals_part(sheet_offset):
    wa = struct.pack("<HB", 3, 0) + b"SvS"
    wa += b" " * (112 - len(wa))
    out = [
        bof(0x0005),
        rec(0x00E1, u16(0x04B0)), rec(0x00C1, b"\0\0"), rec(0x00E2),
        rec(0x005C, wa), rec(0x0042, u16(0x04B0)), rec(0x0161, u16(0)),
        rec(0x013D, u16(1)), rec(0x009C, u16(0x0E)),
        rec(0x0019, u16(0)), rec(0x0012, u16(0)), rec(0x0063, u16(0)), rec(0x0013, u16(0)),
        rec(0x01AF, u16(0)), rec(0x01BC, u16(0)), rec(0x0040, u16(0)), rec(0x008D, u16(0)),
        rec(0x003D, struct.pack("<9H", 0x01E0, 0x005A, 0x3FCF, 0x2A4E, 0x0038, 0, 0, 1, 0x0258)),
        rec(0x0022, u16(0)), rec(0x000E, u16(1)), rec(0x01B7, u16(0)), rec(0x00DA, u16(0)),
        *[font() for _ in range(5)],
        rec(0x00E0, STYLE_XF0), *[rec(0x00E0, STYLE_XFN) for _ in range(14)], rec(0x00E0, CELL_XF),
        rec(0x0293, struct.pack("<HBB", 0x8000, 0, 0xFF)),
        rec(0x0160, u16(1)),
        sheet_name_record(sheet_offset),
        rec(0x008C, struct.pack("<HH", 90, 90)),
        rec(0x00FC, struct.pack("<II", 0, 0)),      # SST (boş)
        rec(0x00FF, u16(8)),                         # EXTSST
        rec(0x000A),
    ]
    return b"".join(out)

def sheet_part():
    return b"".join([
        bof(0x0010),
        rec(0x000D, u16(1)), rec(0x000C, u16(100)), rec(0x000F, u16(1)), rec(0x0011, u16(0)),
        rec(0x0010, struct.pack("<d", 0.001)), rec(0x005F, u16(1)),
        rec(0x002A, u16(0)), rec(0x002B, u16(0)), rec(0x0082, u16(1)),
        rec(0x0080, struct.pack("<4H", 0, 0, 0, 0)), rec(0x0225, struct.pack("<HH", 0, 255)),
        rec(0x0081, u16(0x04C1)), rec(0x0055, u16(8)),
        rec(0x0200, struct.pack("<IIHHH", 0, 0, 0, 0, 0)),
        rec(0x023E, struct.pack("<7HI", 0x06B6, 0, 0, 0x40, 0, 0, 0, 0)),
        rec(0x000A),
    ])

def workbook_stream():
    g = globals_part(0)
    g = globals_part(len(g))            # sayfa BOF'unun gerçek konumu
    s = g + sheet_part()
    if len(s) < 4096:                   # mini-stream'e düşmesin (Excel/xlwt gibi)
        s += b"\0" * (4096 - len(s))
    return s

# --- OLE2 / Compound File (v3, 512 bayt sektör) ---
ENDCHAIN, FREESECT, FATSECT, NOSTREAM = 0xFFFFFFFE, 0xFFFFFFFF, 0xFFFFFFFD, 0xFFFFFFFF

def dir_entry(name, typ, child, start, size):
    n = (name + "\0").encode("utf-16-le") if name else b""
    return (n.ljust(64, b"\0") + struct.pack("<HBB", len(n), typ, 1 if name else 0)
            + struct.pack("<III", NOSTREAM, NOSTREAM, child) + b"\0" * 16
            + struct.pack("<I", 0) + b"\0" * 16 + struct.pack("<IQ", start, size))

def cfb(stream):
    sec = 512
    data = stream + b"\0" * (-len(stream) % sec)
    n = len(data) // sec
    dir_sec, fat_sec = n, n + 1
    assert n + 2 <= 128
    fat = [i + 1 for i in range(n - 1)] + [ENDCHAIN, ENDCHAIN, FATSECT]
    fat += [FREESECT] * (128 - len(fat))
    directory = (dir_entry("Root Entry", 5, 1, ENDCHAIN, 0)
                 + dir_entry("Workbook", 2, NOSTREAM, 0, len(stream))
                 + dir_entry("", 0, NOSTREAM, 0, 0) * 2)
    header = (bytes.fromhex("D0CF11E0A1B11AE1") + b"\0" * 16
              + struct.pack("<HHHHH", 0x3E, 3, 0xFFFE, 9, 6) + b"\0" * 6
              + struct.pack("<IIIIIIIII", 0, 1, dir_sec, 0, 4096, ENDCHAIN, 0, ENDCHAIN, 0)
              + struct.pack("<I", fat_sec) + struct.pack("<I", FREESECT) * 108)
    assert len(header) == 512 and len(directory) == 512
    return header + data + directory + struct.pack("<128I", *fat)

open(sys.argv[1], "wb").write(cfb(workbook_stream()))
print("yazıldı:", sys.argv[1])
