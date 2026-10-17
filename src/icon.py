import math, struct, zlib, os

SIZES = [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]
BASE = 'ccheker_live'

def chunk(t, d):
    return struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)

def dseg(px, py, ax, ay, bx, by):
    vx, vy = bx - ax, by - ay
    wx, wy = px - ax, py - ay
    L = vx * vx + vy * vy
    t = 0.0 if L == 0 else max(0.0, min(1.0, (wx * vx + wy * vy) / L))
    return math.hypot(px - (ax + vx * t), py - (ay + vy * t))

def make(path, s):
    raw = bytearray()
    w = 0.072 * s
    for y in range(s):
        raw.append(0)
        for x in range(s):
            f = y / (s - 1.0)
            r = int(9 + 10 * f); g = int(11 + 12 * f); b = int(17 + 16 * f)
            d = min(dseg(x, y, 0.25 * s, 0.53 * s, 0.43 * s, 0.71 * s),
                    dseg(x, y, 0.43 * s, 0.71 * s, 0.77 * s, 0.31 * s))
            if d < w:
                a = 1.0 if d < w - 1.5 else (w - d) / 1.5
                r = int(r * (1 - a) + 186 * a)
                g = int(g * (1 - a) + 255 * a)
                b = int(b * (1 - a) + 84 * a)
            raw += bytes((r, g, b))
    ihdr = struct.pack('>IIBBBBB', s, s, 8, 2, 0, 0, 0)
    data = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', ihdr) + chunk(b'IDAT', zlib.compress(bytes(raw), 9)) + chunk(b'IEND', b'')
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'wb').write(data)

for name, s in SIZES:
    make('%s/android/app/src/main/res/mipmap-%s/ic_launcher.png' % (BASE, name), s)
print('icono listo')
