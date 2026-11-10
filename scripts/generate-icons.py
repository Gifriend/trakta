"""Generate deterministic PWA icons from the application's vector checkmark."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1] / "static" / "icons"
ROOT.mkdir(parents=True, exist_ok=True)

for size, name in [(192, "icon-192.png"), (512, "icon-512.png"), (512, "maskable-512.png")]:
    scale = 4
    image = Image.new("RGB", (size * scale, size * scale), "#124e43")
    draw = ImageDraw.Draw(image)
    points = [(int(x / 512 * size * scale), int(y / 512 * size * scale)) for x, y in [(149, 263), (222, 334), (363, 181)]]
    width = int(42 / 512 * size * scale)
    draw.line(points, fill="#d5ed9c", width=width, joint="curve")
    for x, y in points:
        r = width / 2
        draw.ellipse((x-r, y-r, x+r, y+r), fill="#d5ed9c")
    image.resize((size, size), Image.Resampling.LANCZOS).save(ROOT / name)
print("Generated 192px, 512px, and maskable PWA icons.")
