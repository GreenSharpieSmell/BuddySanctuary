"""
generate_placeholders.py — Buddy Sanctuary placeholder art generator.

Generates all placeholder PNG sprites needed to make the game visually
playable. Uses Pillow only. All output is RGBA with transparent backgrounds.

Run from repo root:
    python tools/generate_placeholders.py
"""

from PIL import Image, ImageDraw
import os


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def make_rgba(w: int, h: int) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    """Create a transparent RGBA canvas and a draw handle."""
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    return img, draw


def save(img: Image.Image, path: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print(f"  wrote  {path}")


# ---------------------------------------------------------------------------
# Bodies — 64×64, grayscale shapes (white fill so modulate tints them)
# ---------------------------------------------------------------------------

BODIES_DIR = "assets/sprites/bodies"


def gen_round_blobby() -> None:
    """White filled circle ~50px diameter, centered on 64×64."""
    img, draw = make_rgba(64, 64)
    margin = 7
    draw.ellipse((margin, margin, 64 - margin, 64 - margin), fill=(255, 255, 255, 255))
    save(img, f"{BODIES_DIR}/round_blobby.png")


def gen_pudgy_square() -> None:
    """White rounded rectangle ~48×48 — stocky, pudgy feel."""
    img, draw = make_rgba(64, 64)
    margin = 8
    r = 10  # corner radius
    draw.rounded_rectangle(
        (margin, margin, 64 - margin, 64 - margin),
        radius=r, fill=(255, 255, 255, 255)
    )
    save(img, f"{BODIES_DIR}/pudgy_square.png")


def gen_lanky_sprout() -> None:
    """White tall oval ~28×56, centered — tall and thin."""
    img, draw = make_rgba(64, 64)
    cx, cy = 32, 32
    hw, hh = 14, 28  # half-width, half-height
    draw.ellipse((cx - hw, cy - hh, cx + hw, cy + hh), fill=(255, 255, 255, 255))
    save(img, f"{BODIES_DIR}/lanky_sprout.png")


def gen_tall_noodle() -> None:
    """Alias name used in task spec — same as lanky sprout (tall oval)."""
    img, draw = make_rgba(64, 64)
    cx, cy = 32, 32
    hw, hh = 12, 28
    draw.ellipse((cx - hw, cy - hh, cx + hw, cy + hh), fill=(255, 255, 255, 255))
    save(img, f"{BODIES_DIR}/tall_noodle.png")


def gen_spiky_star() -> None:
    """White filled rectangle ~48×48 — task spec shape."""
    img, draw = make_rgba(64, 64)
    margin = 8
    draw.rectangle((margin, margin, 64 - margin, 64 - margin), fill=(255, 255, 255, 255))
    save(img, f"{BODIES_DIR}/spiky_star.png")


# ---------------------------------------------------------------------------
# Eyes — 16×16
# ---------------------------------------------------------------------------

EYES_DIR = "assets/sprites/eyes"


def gen_dot_eyes() -> None:
    """Two small black dots (4px each) side by side."""
    img, draw = make_rgba(16, 16)
    # left dot at (3,6), right dot at (9,6)
    r = 2
    for cx in (4, 11):
        draw.ellipse((cx - r, 6 - r, cx + r, 6 + r), fill=(20, 20, 20, 255))
    save(img, f"{EYES_DIR}/dot_eyes.png")


def gen_wide_eyes() -> None:
    """Two larger open circles with pupils — wide, expressive."""
    img, draw = make_rgba(16, 16)
    for cx in (4, 11):
        # white sclera
        draw.ellipse((cx - 3, 3, cx + 3, 11), fill=(240, 240, 240, 255))
        # pupil
        draw.ellipse((cx - 1, 5, cx + 1, 9), fill=(20, 20, 20, 255))
    save(img, f"{EYES_DIR}/wide_eyes.png")


def gen_starry_eyes() -> None:
    """Two star-shaped highlight eyes (circle with a white glint)."""
    img, draw = make_rgba(16, 16)
    for cx in (4, 11):
        # iris — deep blue
        draw.ellipse((cx - 3, 3, cx + 3, 11), fill=(60, 80, 180, 255))
        # pupil
        draw.ellipse((cx - 1, 5, cx + 1, 9), fill=(10, 10, 30, 255))
        # sparkle glint
        draw.ellipse((cx, 4, cx + 2, 6), fill=(255, 255, 255, 220))
    save(img, f"{EYES_DIR}/starry_eyes.png")


def gen_big_sparkly() -> None:
    """Task spec alias — two large sparkly circles."""
    img, draw = make_rgba(16, 16)
    for cx in (4, 11):
        draw.ellipse((cx - 3, 2, cx + 3, 12), fill=(80, 160, 220, 255))
        draw.ellipse((cx - 1, 4, cx + 1, 8), fill=(10, 10, 40, 255))
        draw.ellipse((cx, 3, cx + 2, 5), fill=(255, 255, 255, 220))
    save(img, f"{EYES_DIR}/big_sparkly.png")


def gen_heart_eyes() -> None:
    """Task spec — two tiny red heart shapes (pixel hearts)."""
    img, draw = make_rgba(16, 16)
    # Pixel-art heart pattern for each eye (5×5 grid)
    # Pattern:  .XX. / XXXX / XXXX / .XX. / ..X.
    heart_pixels = [
        (1, 0), (2, 0), (4, 0), (5, 0),
        (0, 1), (1, 1), (2, 1), (3, 1), (4, 1), (5, 1),
        (0, 2), (1, 2), (2, 2), (3, 2), (4, 2), (5, 2),
        (1, 3), (2, 3), (3, 3), (4, 3),
        (2, 4), (3, 4),
    ]
    red = (220, 40, 60, 255)
    # Left heart offset (0, 5), right heart offset (9, 5) — fits in 16px
    for ox, oy in [(0, 5), (9, 5)]:
        for px, py in heart_pixels:
            if ox + px < 16 and oy + py < 16:
                img.putpixel((ox + px, oy + py), red)
    save(img, f"{EYES_DIR}/heart_eyes.png")


# ---------------------------------------------------------------------------
# Mouths — 16×8
# ---------------------------------------------------------------------------

MOUTHS_DIR = "assets/sprites/mouths"


def gen_simple_smile() -> None:
    """Black curved arc for a friendly smile."""
    img, draw = make_rgba(16, 8)
    # Arc: bounding box, angles 0–180 draws a downward arc (smile)
    draw.arc((1, -2, 14, 10), start=10, end=170, fill=(20, 20, 20, 255), width=2)
    save(img, f"{MOUTHS_DIR}/simple_smile.png")


def gen_toothy_grin() -> None:
    """Smile arc with small white teeth rectangle below it."""
    img, draw = make_rgba(16, 8)
    draw.arc((1, -2, 14, 8), start=10, end=170, fill=(20, 20, 20, 255), width=2)
    # Small teeth row
    draw.rectangle((4, 4, 11, 7), fill=(250, 250, 250, 255))
    draw.line([(7, 4), (7, 7)], fill=(20, 20, 20, 180), width=1)
    save(img, f"{MOUTHS_DIR}/toothy_grin.png")


def gen_pout() -> None:
    """Small downward arc — a pout / sad mouth."""
    img, draw = make_rgba(16, 8)
    # Flip the arc: angles 180–360 draws an upward arc visually = frown
    draw.arc((2, 0, 13, 12), start=190, end=350, fill=(20, 20, 20, 255), width=2)
    save(img, f"{MOUTHS_DIR}/pout.png")


def gen_cat_mouth() -> None:
    """Task spec :3 shape — two small downward V curves."""
    img, draw = make_rgba(16, 8)
    # Left V
    draw.line([(2, 2), (4, 5), (7, 2)], fill=(20, 20, 20, 255), width=2)
    # Right V
    draw.line([(8, 2), (11, 5), (13, 2)], fill=(20, 20, 20, 255), width=2)
    save(img, f"{MOUTHS_DIR}/cat_mouth.png")


def gen_derp() -> None:
    """Task spec wavy line mouth."""
    img, draw = make_rgba(16, 8)
    pts = [(1, 4), (4, 2), (7, 5), (10, 2), (14, 4)]
    draw.line(pts, fill=(20, 20, 20, 255), width=2)
    save(img, f"{MOUTHS_DIR}/derp.png")


# ---------------------------------------------------------------------------
# Accessories — 32×32
# ---------------------------------------------------------------------------

ACC_DIR = "assets/sprites/accessories"


def gen_flower_crown() -> None:
    """Green stem band with tiny coloured dots (flowers)."""
    img, draw = make_rgba(32, 32)
    # Band
    draw.rectangle((2, 20, 29, 25), fill=(60, 160, 60, 255))
    # Flowers
    colours = [(255, 100, 150), (255, 220, 60), (140, 100, 255)]
    for i, (x, col) in enumerate(zip([5, 14, 22], colours)):
        draw.ellipse((x, 12, x + 8, 22), fill=col + (255,))
        draw.ellipse((x + 2, 14, x + 6, 20), fill=(255, 255, 200, 255))
    save(img, f"{ACC_DIR}/head/flower_crown.png")


def gen_wizard_hat() -> None:
    """Classic tall triangle wizard hat, dark purple."""
    img, draw = make_rgba(32, 32)
    # Brim
    draw.ellipse((2, 22, 29, 30), fill=(80, 30, 120, 255))
    # Cone (triangle)
    draw.polygon([(16, 2), (3, 24), (28, 24)], fill=(80, 30, 120, 255))
    # Star on hat
    draw.ellipse((13, 8, 19, 14), fill=(255, 220, 60, 220))
    save(img, f"{ACC_DIR}/head/wizard_hat.png")


def gen_tiny_hat() -> None:
    """Task spec — small brown rectangle top hat."""
    img, draw = make_rgba(32, 32)
    # brim
    draw.rectangle((4, 20, 27, 24), fill=(100, 65, 30, 255))
    # crown
    draw.rectangle((9, 10, 22, 21), fill=(120, 80, 40, 255))
    save(img, f"{ACC_DIR}/head/tiny_hat.png")


def gen_ribbon_bow() -> None:
    """Cute pink ribbon bow shape."""
    img, draw = make_rgba(32, 32)
    # Left wing
    draw.polygon([(4, 8), (14, 14), (14, 20), (4, 26)], fill=(255, 140, 180, 255))
    # Right wing
    draw.polygon([(27, 8), (17, 14), (17, 20), (27, 26)], fill=(255, 140, 180, 255))
    # Center knot
    draw.ellipse((12, 13, 19, 21), fill=(220, 80, 130, 255))
    save(img, f"{ACC_DIR}/neck/ribbon_bow.png")


def gen_gem_necklace() -> None:
    """Gold chain with a blue gem pendant."""
    img, draw = make_rgba(32, 32)
    # Chain arc
    draw.arc((4, 4, 27, 20), start=10, end=170, fill=(200, 170, 60, 255), width=2)
    # Pendant
    draw.polygon([(13, 20), (18, 20), (20, 28), (11, 28)], fill=(60, 120, 220, 255))
    draw.polygon([(14, 20), (17, 20), (18, 23), (13, 23)], fill=(160, 200, 255, 200))
    save(img, f"{ACC_DIR}/neck/gem_necklace.png")


def gen_red_scarf() -> None:
    """Task spec — red rectangle scarf."""
    img, draw = make_rgba(32, 32)
    draw.rectangle((4, 10, 27, 22), fill=(200, 30, 30, 255))
    # Knot lump on right side
    draw.ellipse((19, 8, 28, 20), fill=(180, 20, 20, 255))
    # Tail hanging down
    draw.rectangle((20, 19, 26, 30), fill=(200, 30, 30, 255))
    save(img, f"{ACC_DIR}/neck/red_scarf.png")


def gen_tiny_lantern() -> None:
    """Small glowing lantern on a handle."""
    img, draw = make_rgba(32, 32)
    # Handle
    draw.line([(16, 4), (16, 10)], fill=(120, 90, 50, 255), width=2)
    # Body
    draw.rounded_rectangle((8, 10, 23, 26), radius=4, fill=(200, 180, 80, 255))
    # Glow window
    draw.rounded_rectangle((11, 13, 20, 23), radius=3, fill=(255, 240, 140, 255))
    # Bottom cap
    draw.rectangle((11, 25, 20, 28), fill=(120, 90, 50, 255))
    save(img, f"{ACC_DIR}/held/tiny_lantern.png")


def gen_leaf_fan() -> None:
    """Green leaf fan — two overlapping leaf shapes."""
    img, draw = make_rgba(32, 32)
    # Left leaf
    draw.ellipse((2, 6, 18, 26), fill=(60, 180, 80, 255))
    # Right leaf
    draw.ellipse((12, 6, 28, 26), fill=(40, 150, 60, 255))
    # Handle
    draw.rectangle((14, 24, 17, 31), fill=(120, 80, 40, 255))
    save(img, f"{ACC_DIR}/held/leaf_fan.png")


def gen_balloon() -> None:
    """Task spec — colored circle with a string line."""
    img, draw = make_rgba(32, 32)
    # Balloon
    draw.ellipse((6, 2, 26, 22), fill=(255, 80, 100, 255))
    # Highlight
    draw.ellipse((9, 5, 15, 11), fill=(255, 180, 190, 160))
    # Knot
    draw.ellipse((14, 21, 17, 24), fill=(200, 50, 70, 255))
    # String
    draw.line([(15, 24), (14, 28), (16, 31)], fill=(80, 80, 80, 255), width=1)
    save(img, f"{ACC_DIR}/held/balloon.png")


def gen_mini_backpack() -> None:
    """Small brown rounded backpack."""
    img, draw = make_rgba(32, 32)
    # Main pack
    draw.rounded_rectangle((8, 8, 24, 26), radius=4, fill=(140, 90, 50, 255))
    # Pocket
    draw.rounded_rectangle((10, 16, 22, 24), radius=3, fill=(110, 70, 35, 255))
    # Straps
    draw.rectangle((8, 8, 11, 26), fill=(100, 65, 30, 255))
    draw.rectangle((20, 8, 23, 26), fill=(100, 65, 30, 255))
    save(img, f"{ACC_DIR}/back/mini_backpack.png")


def gen_fairy_wings() -> None:
    """Two translucent iridescent wing shapes."""
    img, draw = make_rgba(32, 32)
    # Left wing
    draw.ellipse((1, 4, 16, 22), fill=(180, 220, 255, 180))
    draw.ellipse((3, 18, 14, 28), fill=(200, 180, 255, 140))
    # Right wing
    draw.ellipse((15, 4, 30, 22), fill=(180, 220, 255, 180))
    draw.ellipse((17, 18, 28, 28), fill=(200, 180, 255, 140))
    save(img, f"{ACC_DIR}/back/fairy_wings.png")


def gen_tiny_wings() -> None:
    """Task spec — two small triangles."""
    img, draw = make_rgba(32, 32)
    # Left wing triangle
    draw.polygon([(4, 20), (14, 6), (16, 20)], fill=(220, 200, 255, 220))
    # Right wing triangle
    draw.polygon([(27, 20), (17, 6), (16, 20)], fill=(220, 200, 255, 220))
    save(img, f"{ACC_DIR}/back/tiny_wings.png")


def gen_tiny_boots() -> None:
    """Pair of small brown rounded boots."""
    img, draw = make_rgba(32, 32)
    for ox in (4, 16):
        # Shaft
        draw.rounded_rectangle((ox, 12, ox + 10, 24), radius=3, fill=(100, 65, 30, 255))
        # Toe cap
        draw.ellipse((ox - 1, 20, ox + 11, 30), fill=(80, 50, 22, 255))
    save(img, f"{ACC_DIR}/feet/tiny_boots.png")


def gen_roller_skates() -> None:
    """Two simple roller skate shapes with wheels."""
    img, draw = make_rgba(32, 32)
    for ox in (3, 17):
        # Boot
        draw.rounded_rectangle((ox, 10, ox + 10, 22), radius=3, fill=(220, 60, 60, 255))
        # Base plate
        draw.rectangle((ox - 1, 20, ox + 11, 24), fill=(180, 180, 180, 255))
        # Wheels
        for wx in (ox, ox + 7):
            draw.ellipse((wx, 23, wx + 3, 28), fill=(40, 40, 40, 255))
    save(img, f"{ACC_DIR}/feet/roller_skates.png")


def gen_puddle() -> None:
    """Task spec — blue oval puddle underfoot."""
    img, draw = make_rgba(32, 32)
    draw.ellipse((4, 16, 27, 28), fill=(80, 140, 220, 200))
    # Highlight
    draw.ellipse((8, 18, 18, 24), fill=(160, 200, 255, 120))
    save(img, f"{ACC_DIR}/feet/puddle.png")


# ---------------------------------------------------------------------------
# Particles — 8×8
# ---------------------------------------------------------------------------

PARTICLES_DIR = "assets/particles"


def gen_heart_particle() -> None:
    """Tiny pink/red pixel heart on 8×8 canvas."""
    img, draw = make_rgba(8, 8)
    # Pixel art heart pattern (6 wide × 5 tall, centred)
    red = (230, 60, 80, 255)
    pixels = [
        (1, 1), (2, 1), (4, 1), (5, 1),
        (0, 2), (1, 2), (2, 2), (3, 2), (4, 2), (5, 2),
        (0, 3), (1, 3), (2, 3), (3, 3), (4, 3), (5, 3),
        (1, 4), (2, 4), (3, 4), (4, 4),
        (2, 5), (3, 5),
    ]
    for px, py in pixels:
        if px < 8 and py < 8:
            img.putpixel((px + 1, py + 1), red)
    save(img, f"{PARTICLES_DIR}/heart.png")


def gen_sparkle_particle() -> None:
    """Tiny white 4-point star on 8×8 canvas."""
    img, draw = make_rgba(8, 8)
    white = (255, 255, 220, 255)
    dim = (255, 255, 220, 160)
    # Centre
    img.putpixel((3, 3), white)
    img.putpixel((4, 3), white)
    img.putpixel((3, 4), white)
    img.putpixel((4, 4), white)
    # Cardinal arms
    for d in range(1, 3):
        img.putpixel((3, 3 - d), dim)
        img.putpixel((4, 3 - d), dim)
        img.putpixel((3, 4 + d), dim)
        img.putpixel((4, 4 + d), dim)
        img.putpixel((3 - d, 3), dim)
        img.putpixel((3 - d, 4), dim)
        img.putpixel((3 + d + 1, 3), dim)
        img.putpixel((3 + d + 1, 4), dim)
    save(img, f"{PARTICLES_DIR}/sparkle.png")


# ---------------------------------------------------------------------------
# Background — 1920×720
# ---------------------------------------------------------------------------

ENV_DIR = "assets/environments/placeholder"


def gen_meadow_bg() -> None:
    """1920×720 simple green gradient — lighter at top, darker at bottom."""
    w, h = 1920, 720
    img = Image.new("RGBA", (w, h), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)

    # Sky band (top ~40%) — soft blue gradient
    sky_h = int(h * 0.40)
    for y in range(sky_h):
        t = y / sky_h
        r = int(160 + t * 20)
        g = int(210 + t * 10)
        b = int(240 - t * 20)
        draw.line([(0, y), (w, y)], fill=(r, g, b, 255))

    # Ground band (bottom ~60%) — green gradient lighter→darker toward bottom
    ground_top = sky_h
    ground_h = h - ground_top
    for y in range(ground_h):
        t = y / ground_h
        r = int(80 - t * 20)
        g = int(160 - t * 40)
        b = int(60 - t * 20)
        draw.line([(0, ground_top + y), (w, ground_top + y)], fill=(r, g, b, 255))

    # Horizon seam — thin soft line
    draw.line([(0, sky_h), (w, sky_h)], fill=(120, 180, 100, 180), width=2)

    save(img, f"{ENV_DIR}/meadow_bg.png")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    print("Generating Buddy Sanctuary placeholder art...")

    print("\n--- Bodies ---")
    gen_round_blobby()
    gen_pudgy_square()
    gen_lanky_sprout()
    gen_tall_noodle()
    gen_spiky_star()

    print("\n--- Eyes ---")
    gen_dot_eyes()
    gen_wide_eyes()
    gen_starry_eyes()
    gen_big_sparkly()
    gen_heart_eyes()

    print("\n--- Mouths ---")
    gen_simple_smile()
    gen_toothy_grin()
    gen_pout()
    gen_cat_mouth()
    gen_derp()

    print("\n--- Accessories: head ---")
    gen_flower_crown()
    gen_wizard_hat()
    gen_tiny_hat()

    print("\n--- Accessories: neck ---")
    gen_ribbon_bow()
    gen_gem_necklace()
    gen_red_scarf()

    print("\n--- Accessories: held ---")
    gen_tiny_lantern()
    gen_leaf_fan()
    gen_balloon()

    print("\n--- Accessories: back ---")
    gen_mini_backpack()
    gen_fairy_wings()
    gen_tiny_wings()

    print("\n--- Accessories: feet ---")
    gen_tiny_boots()
    gen_roller_skates()
    gen_puddle()

    print("\n--- Particles ---")
    gen_heart_particle()
    gen_sparkle_particle()

    print("\n--- Background ---")
    gen_meadow_bg()

    print("\nDone. All placeholder art generated.")


if __name__ == "__main__":
    main()
