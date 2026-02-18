#!/usr/bin/env python3
"""Generate stylized qb-boozebiz item icons as PNG files without external dependencies."""

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


def _new_canvas(color: tuple[int, int, int]) -> list[list[list[int]]]:
    r, g, b = color
    canvas = []
    for y in range(H):
        row = []
        for x in range(W):
            border = x < 6 or y < 6 or x > W - 7 or y > H - 7
            rr, gg, bb = (max(0, r - 45), max(0, g - 45), max(0, b - 45)) if border else (r, g, b)
            if not border and (x + y) % 21 == 0:
                rr, gg, bb = min(255, rr + 12), min(255, gg + 12), min(255, bb + 12)
            row.append([rr, gg, bb, 255])
        canvas.append(row)
    return canvas


def _set_px(canvas, x: int, y: int, rgba: tuple[int, int, int, int]):
    if 0 <= x < W and 0 <= y < H:
        canvas[y][x] = [rgba[0], rgba[1], rgba[2], rgba[3]]


def _rect(canvas, x1, y1, x2, y2, rgba):
    for y in range(y1, y2 + 1):
        for x in range(x1, x2 + 1):
            _set_px(canvas, x, y, rgba)


def _circle(canvas, cx, cy, radius, rgba):
    rr = radius * radius
    for y in range(cy - radius, cy + radius + 1):
        for x in range(cx - radius, cx + radius + 1):
            if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= rr:
                _set_px(canvas, x, y, rgba)


def _line(canvas, x1, y1, x2, y2, thickness, rgba):
    dx = x2 - x1
    dy = y2 - y1
    steps = max(abs(dx), abs(dy), 1)
    for i in range(steps + 1):
        x = round(x1 + dx * i / steps)
        y = round(y1 + dy * i / steps)
        _circle(canvas, x, y, max(1, thickness // 2), rgba)


def _draw_symbol(canvas, filename: str):
    white = (245, 245, 245, 255)
    dark = (35, 35, 35, 255)

    if filename == 'grape.png':
        for px, py in [(56, 48), (72, 48), (48, 62), (64, 62), (80, 62), (56, 76), (72, 76), (64, 90)]:
            _circle(canvas, px, py, 8, white)
        _line(canvas, 64, 34, 76, 24, 3, white)
    elif filename == 'barley.png':
        _line(canvas, 64, 98, 64, 30, 3, white)
        for i in range(7):
            y = 86 - i * 8
            _line(canvas, 64, y, 76, y - 5, 2, white)
            _line(canvas, 64, y - 2, 52, y - 7, 2, white)
    elif filename == 'yeast.png':
        _circle(canvas, 64, 64, 20, white)
        _circle(canvas, 50, 66, 9, dark)
        _circle(canvas, 78, 62, 7, dark)
    elif filename == 'water.png':
        _line(canvas, 64, 30, 42, 68, 3, white)
        _line(canvas, 64, 30, 86, 68, 3, white)
        _line(canvas, 42, 68, 64, 96, 3, white)
        _line(canvas, 86, 68, 64, 96, 3, white)
        _rect(canvas, 56, 58, 72, 90, white)
    elif filename == 'mash.png':
        _rect(canvas, 36, 44, 92, 88, white)
        _rect(canvas, 28, 36, 100, 46, white)
        _line(canvas, 42, 54, 86, 78, 3, dark)
        _line(canvas, 50, 82, 88, 58, 3, dark)
    elif filename == 'spirit.png':
        _rect(canvas, 54, 36, 74, 96, white)
        _rect(canvas, 58, 28, 70, 36, white)
        _circle(canvas, 64, 70, 7, dark)
    elif filename == 'empty_bottle.png':
        _rect(canvas, 54, 34, 74, 96, white)
        _rect(canvas, 58, 24, 70, 34, white)
        _rect(canvas, 58, 50, 70, 90, dark)
    elif filename == 'cardboard.png':
        _rect(canvas, 36, 42, 92, 88, white)
        _line(canvas, 36, 42, 64, 28, 2, white)
        _line(canvas, 92, 42, 64, 28, 2, white)
        _line(canvas, 64, 28, 64, 42, 2, white)
    elif filename == 'liquor.png':
        _rect(canvas, 52, 32, 76, 98, white)
        _rect(canvas, 58, 22, 70, 32, white)
        _rect(canvas, 56, 56, 72, 88, dark)
    elif filename == 'crate.png':
        _rect(canvas, 30, 34, 98, 94, white)
        _line(canvas, 30, 50, 98, 50, 2, dark)
        _line(canvas, 30, 66, 98, 66, 2, dark)
        _line(canvas, 46, 34, 46, 94, 2, dark)
        _line(canvas, 66, 34, 66, 94, 2, dark)
        _line(canvas, 84, 34, 84, 94, 2, dark)


def write_png(path: Path, rgb: tuple[int, int, int]) -> None:
    canvas = _new_canvas(rgb)
    _draw_symbol(canvas, path.name)

    rows = []
    for y in range(H):
        row = bytearray([0])
        for x in range(W):
            row.extend(canvas[y][x])
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
