"""Generate 30 extra puzzle imagesets (2026-09-05 ... 2026-10-04) and prepend them to puzzles.json."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "Zoomdle" / "Assets.xcassets"
PUZZLES_PATH = ROOT / "Zoomdle" / "Resources" / "puzzles.json"

NEW_PUZZLES = [
    {
        "id": "2026-10-04",
        "date": "2026-10-04",
        "imageName": "puzzle-earth",
        "answer": "Earth",
        "acceptableAnswers": ["planet earth", "the earth", "globe"],
        "category": "Space",
        "color": (46, 120, 186),
        "accent": (80, 186, 92),
    },
    {
        "id": "2026-10-03",
        "date": "2026-10-03",
        "imageName": "puzzle-microscope",
        "answer": "Microscope",
        "acceptableAnswers": ["lab microscope", "compound microscope"],
        "category": "Objects",
        "color": (90, 90, 110),
        "accent": (210, 210, 220),
    },
    {
        "id": "2026-10-02",
        "date": "2026-10-02",
        "imageName": "puzzle-hot-dog",
        "answer": "Hot Dog",
        "acceptableAnswers": ["hotdog", "frankfurter", "wiener"],
        "category": "Food",
        "color": (196, 92, 46),
        "accent": (242, 198, 86),
    },
    {
        "id": "2026-10-01",
        "date": "2026-10-01",
        "imageName": "puzzle-koala",
        "answer": "Koala",
        "acceptableAnswers": ["koala bear", "koalas"],
        "category": "Animals",
        "color": (140, 140, 128),
        "accent": (90, 130, 70),
    },
    {
        "id": "2026-09-30",
        "date": "2026-09-30",
        "imageName": "puzzle-sydney-opera-house",
        "answer": "Sydney Opera House",
        "acceptableAnswers": ["opera house", "sydney opera", "the opera house"],
        "category": "Landmarks",
        "color": (70, 150, 190),
        "accent": (244, 244, 240),
    },
    {
        "id": "2026-09-29",
        "date": "2026-09-29",
        "imageName": "puzzle-sun",
        "answer": "Sun",
        "acceptableAnswers": ["the sun", "sol"],
        "category": "Space",
        "color": (24, 32, 64),
        "accent": (255, 176, 32),
    },
    {
        "id": "2026-09-28",
        "date": "2026-09-28",
        "imageName": "puzzle-accordion",
        "answer": "Accordion",
        "acceptableAnswers": ["accordian", "squeeze box"],
        "category": "Objects",
        "color": (140, 42, 42),
        "accent": (236, 208, 92),
    },
    {
        "id": "2026-09-27",
        "date": "2026-09-27",
        "imageName": "puzzle-avocado",
        "answer": "Avocado",
        "acceptableAnswers": ["avocados", "avo"],
        "category": "Food",
        "color": (92, 122, 46),
        "accent": (196, 210, 86),
    },
    {
        "id": "2026-09-26",
        "date": "2026-09-26",
        "imageName": "puzzle-dolphin",
        "answer": "Dolphin",
        "acceptableAnswers": ["dolphins", "porpoise"],
        "category": "Animals",
        "color": (48, 118, 168),
        "accent": (186, 214, 230),
    },
    {
        "id": "2026-09-25",
        "date": "2026-09-25",
        "imageName": "puzzle-stonehenge",
        "answer": "Stonehenge",
        "acceptableAnswers": ["stone henge", "the stones"],
        "category": "Landmarks",
        "color": (120, 150, 92),
        "accent": (168, 164, 148),
    },
    {
        "id": "2026-09-24",
        "date": "2026-09-24",
        "imageName": "puzzle-meteor",
        "answer": "Meteor",
        "acceptableAnswers": ["meteorite", "falling star", "fireball"],
        "category": "Space",
        "color": (18, 18, 36),
        "accent": (255, 140, 64),
    },
    {
        "id": "2026-09-23",
        "date": "2026-09-23",
        "imageName": "puzzle-umbrella",
        "answer": "Umbrella",
        "acceptableAnswers": ["brolly", "parasol"],
        "category": "Objects",
        "color": (46, 86, 150),
        "accent": (210, 56, 56),
    },
    {
        "id": "2026-09-22",
        "date": "2026-09-22",
        "imageName": "puzzle-ramen",
        "answer": "Ramen",
        "acceptableAnswers": ["ramen noodles", "noodle soup"],
        "category": "Food",
        "color": (186, 92, 42),
        "accent": (242, 214, 150),
    },
    {
        "id": "2026-09-21",
        "date": "2026-09-21",
        "imageName": "puzzle-wolf",
        "answer": "Wolf",
        "acceptableAnswers": ["wolves", "gray wolf", "grey wolf"],
        "category": "Animals",
        "color": (72, 76, 84),
        "accent": (200, 200, 204),
    },
    {
        "id": "2026-09-20",
        "date": "2026-09-20",
        "imageName": "puzzle-machu-picchu",
        "answer": "Machu Picchu",
        "acceptableAnswers": ["machu pichu", "machu picu"],
        "category": "Landmarks",
        "color": (86, 140, 92),
        "accent": (210, 198, 150),
    },
    {
        "id": "2026-09-19",
        "date": "2026-09-19",
        "imageName": "puzzle-galaxy",
        "answer": "Galaxy",
        "acceptableAnswers": ["spiral galaxy", "milky way"],
        "category": "Space",
        "color": (20, 12, 48),
        "accent": (186, 92, 210),
    },
    {
        "id": "2026-09-18",
        "date": "2026-09-18",
        "imageName": "puzzle-compass",
        "answer": "Compass",
        "acceptableAnswers": ["magnetic compass", "navigation compass"],
        "category": "Objects",
        "color": (42, 72, 64),
        "accent": (212, 176, 72),
    },
    {
        "id": "2026-09-17",
        "date": "2026-09-17",
        "imageName": "puzzle-pretzel",
        "answer": "Pretzel",
        "acceptableAnswers": ["pretzels", "soft pretzel"],
        "category": "Food",
        "color": (166, 104, 52),
        "accent": (92, 48, 20),
    },
    {
        "id": "2026-09-16",
        "date": "2026-09-16",
        "imageName": "puzzle-elephant",
        "answer": "Elephant",
        "acceptableAnswers": ["elephants", "african elephant", "asian elephant"],
        "category": "Animals",
        "color": (128, 128, 136),
        "accent": (64, 120, 72),
    },
    {
        "id": "2026-09-15",
        "date": "2026-09-15",
        "imageName": "puzzle-taj-mahal",
        "answer": "Taj Mahal",
        "acceptableAnswers": ["taj mahal india", "the taj mahal"],
        "category": "Landmarks",
        "color": (72, 140, 176),
        "accent": (236, 236, 232),
    },
    {
        "id": "2026-09-14",
        "date": "2026-09-14",
        "imageName": "puzzle-venus",
        "answer": "Venus",
        "acceptableAnswers": ["planet venus"],
        "category": "Space",
        "color": (40, 28, 24),
        "accent": (214, 164, 86),
    },
    {
        "id": "2026-09-13",
        "date": "2026-09-13",
        "imageName": "puzzle-hourglass",
        "answer": "Hourglass",
        "acceptableAnswers": ["hour glass", "sand timer", "egg timer"],
        "category": "Objects",
        "color": (86, 58, 42),
        "accent": (232, 198, 120),
    },
    {
        "id": "2026-09-12",
        "date": "2026-09-12",
        "imageName": "puzzle-waffle",
        "answer": "Waffle",
        "acceptableAnswers": ["waffles", "belgian waffle"],
        "category": "Food",
        "color": (196, 140, 64),
        "accent": (120, 72, 28),
    },
    {
        "id": "2026-09-11",
        "date": "2026-09-11",
        "imageName": "puzzle-penguin",
        "answer": "Penguin",
        "acceptableAnswers": ["penguins", "emperor penguin"],
        "category": "Animals",
        "color": (36, 72, 110),
        "accent": (240, 240, 244),
    },
    {
        "id": "2026-09-10",
        "date": "2026-09-10",
        "imageName": "puzzle-colosseum",
        "answer": "Colosseum",
        "acceptableAnswers": ["coliseum", "roman colosseum", "the colosseum"],
        "category": "Landmarks",
        "color": (176, 122, 86),
        "accent": (92, 64, 48),
    },
    {
        "id": "2026-09-09",
        "date": "2026-09-09",
        "imageName": "puzzle-neptune",
        "answer": "Neptune",
        "acceptableAnswers": ["planet neptune"],
        "category": "Space",
        "color": (16, 28, 92),
        "accent": (64, 120, 210),
    },
    {
        "id": "2026-09-08",
        "date": "2026-09-08",
        "imageName": "puzzle-violin",
        "answer": "Violin",
        "acceptableAnswers": ["fiddle", "violins"],
        "category": "Objects",
        "color": (92, 42, 24),
        "accent": (186, 130, 64),
    },
    {
        "id": "2026-09-07",
        "date": "2026-09-07",
        "imageName": "puzzle-donut",
        "answer": "Donut",
        "acceptableAnswers": ["doughnut", "donuts", "doughnuts"],
        "category": "Food",
        "color": (214, 118, 150),
        "accent": (120, 64, 36),
    },
    {
        "id": "2026-09-06",
        "date": "2026-09-06",
        "imageName": "puzzle-owl",
        "answer": "Owl",
        "acceptableAnswers": ["owls", "barn owl", "great horned owl"],
        "category": "Animals",
        "color": (64, 52, 40),
        "accent": (210, 164, 72),
    },
    {
        "id": "2026-09-05",
        "date": "2026-09-05",
        "imageName": "puzzle-big-ben",
        "answer": "Big Ben",
        "acceptableAnswers": ["elizabeth tower", "london clock", "big ben clock"],
        "category": "Landmarks",
        "color": (56, 92, 128),
        "accent": (214, 186, 92),
    },
]


def render(path: Path, color, accent, seed: str) -> None:
    size = 1024
    img = Image.new("RGB", (size, size), color)
    draw = ImageDraw.Draw(img)
    h = abs(hash(seed))
    for i in range(6):
        inset = 80 + (h + i * 97) % 180
        ring = accent if i % 2 == 0 else tuple(max(0, c - 40) for c in color)
        draw.ellipse((inset, inset, size - inset, size - inset), outline=ring, width=18)
    cx, cy = 280 + h % 200, 260 + (h // 7) % 220
    draw.ellipse((cx, cy, cx + 220, cy + 220), fill=accent)
    dx, dy = 520 + (h // 11) % 180, 480 + (h // 13) % 160
    draw.rounded_rectangle((dx, dy, dx + 280, dy + 180), radius=32, fill=tuple((c + 40) % 256 for c in accent))
    try:
        font = ImageFont.truetype("arial.ttf", 56)
    except OSError:
        font = ImageFont.load_default()
    label = seed.replace("puzzle-", "").replace("-", " ").title()
    draw.text((48, 920), label[:22], fill=(255, 255, 255), font=font)
    img.save(path, "PNG")


def write_imageset(image_name: str, color, accent) -> None:
    folder = ASSETS / f"{image_name}.imageset"
    folder.mkdir(parents=True, exist_ok=True)
    filename = f"{image_name}.png"
    render(folder / filename, color, accent, image_name)
    (folder / "Contents.json").write_text(
        json.dumps(
            {
                "images": [{"filename": filename, "idiom": "universal"}],
                "info": {"author": "xcode", "version": 1},
            },
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )


def main() -> None:
    existing = json.loads(PUZZLES_PATH.read_text(encoding="utf-8"))
    known = {item["id"] for item in existing}
    additions = []
    for item in NEW_PUZZLES:
        write_imageset(item["imageName"], item["color"], item["accent"])
        if item["id"] not in known:
            additions.append({k: item[k] for k in ("id", "date", "imageName", "answer", "acceptableAnswers", "category")})
    merged = additions + existing
    merged.sort(key=lambda item: item["date"], reverse=True)
    PUZZLES_PATH.write_text(json.dumps(merged, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(additions)} new puzzles; catalog now {len(merged)} days")


if __name__ == "__main__":
    main()
