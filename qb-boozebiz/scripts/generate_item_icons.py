#!/usr/bin/env python3
"""Generate qb-boozebiz item icons as PNG files without external dependencies."""

from pathlib import Path
import struct
import zlib

OUT_DIR = Path(__file__).resolve().parent.parent / 'assets' / 'items'
OUT_DIR.mkdir(parents=True, exist_ok=True)

ICONS = {
    'grape.png': (122, 46, 145),
    'barley.png': (181, 137, 0),
    'yeast.png': (133, 153, 0),
    'water.png': (38, 139, 210),
    'mash.png': (108, 113, 196),
    'spirit.png': (42, 161, 152),
    'empty_bottle.png': (147, 161, 161),
    'cardboard.png': (203, 75, 22),
    'liquor.png': (220, 50, 47),
    'crate.png': (88, 110, 117),
}

W = 128
H = 128


def _chunk(tag: bytes, data: bytes) -> bytes:
    return (
        struct.pack('!I', len(data))
        + tag
        + data
        + struct.pack('!I', zlib.crc32(tag + data) & 0xFFFFFFFF)
    )


def write_png(path: Path, rgb: tuple[int, int, int]) -> None:
    r, g, b = rgb
    rows = []
    for y in range(H):
        row = bytearray([0])
        for x in range(W):
            border = x < 6 or y < 6 or x > W - 7 or y > H - 7
            rr, gg, bb = (max(0, r - 50), max(0, g - 50), max(0, b - 50)) if border else (r, g, b)
            if not border and (x + y) % 23 == 0:
                rr, gg, bb = min(255, rr + 18), min(255, gg + 18), min(255, bb + 18)
            row.extend([rr, gg, bb, 255])
        rows.append(bytes(row))

    raw = b''.join(rows)
    png = b'\x89PNG\r\n\x1a\n'
    ihdr = struct.pack('!IIBBBBB', W, H, 8, 6, 0, 0, 0)
    png += _chunk(b'IHDR', ihdr)
    png += _chunk(b'IDAT', zlib.compress(raw, 9))
    png += _chunk(b'IEND', b'')
    path.write_bytes(png)


def main() -> None:
    for filename, color in ICONS.items():
        write_png(OUT_DIR / filename, color)
    print(f'Generated {len(ICONS)} icons in {OUT_DIR}')


if __name__ == '__main__':
    main()
