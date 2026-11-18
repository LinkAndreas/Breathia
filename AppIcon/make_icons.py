"""Build the alternate app icons from Breathia's icon (Shared/AppIcon.icon), one recolored copy per variant.

Each variant moves the icon's colors in OKLCH: the cool colors (the sky, the waves and the moon) and
the warm ones (the sun and the horizon's glow) each get their own hue shift and chroma, so the scene
keeps its light and depth in every color. The layers, glass and appearances stay Breathia's own.

Also writes the vector IconPreview-<Name> images the app icon picker shows, and each icon's
palette (AppIconVariant+Palette.swift): the accent color the app's controls take, and the colors of
the background wash.
Run from anywhere after changing the icon or the variants: python3 AppIcon/make_icons.py
"""
import copy, json, math, os, re, shutil

repo = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
base = os.path.join(repo, "Shared/AppIcon.icon")
resources = os.path.join(repo, "Breathia/Resources")
icons_out = os.path.join(resources, "AppIcons")
previews_out = os.path.join(resources, "IconPreviews.xcassets")
palette_out = os.path.join(repo, "Breathia/DesignSystem/AppIconVariant+Palette.swift")

# name: (cool hue shift, cool chroma, cool lightness shift), (warm hue shift, warm chroma, warm lightness shift)
VARIANTS = {
    "Amethyst": ((45, 1.0, 0.0), (-15, 1.0, 0.0)),
    "Blush": ((85, 0.75, 0.02), (5, 0.9, 0.0)),
    "Ember": ((125, 1.05, -0.02), (15, 1.1, 0.0)),
    "Glacier": ((-50, 0.8, 0.03), (40, 0.6, 0.02)),
    "Lagoon": ((-75, 1.0, 0.0), (0, 1.0, 0.0)),
    "MidnightGold": ((0, 0.55, -0.03), (40, 1.0, 0.0)),
    "Noir": ((0, 0.06, 0.0), (0, 0.5, 0.0)),
}

# OKLab, from https://bottosson.github.io/posts/oklab/

def _to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

def _to_srgb(c):
    return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055

def hex_to_oklch(hex_color):
    r, g, b = (_to_linear(int(hex_color[i:i + 2], 16) / 255) for i in (0, 2, 4))
    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    L = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s
    a = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s
    bb = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
    return L, math.hypot(a, bb), math.degrees(math.atan2(bb, a)) % 360

def _oklch_to_linear(L, C, h):
    a, b = C * math.cos(math.radians(h)), C * math.sin(math.radians(h))
    l = (L + 0.3963377774 * a + 0.2158037573 * b) ** 3
    m = (L - 0.1055613458 * a - 0.0638541728 * b) ** 3
    s = (L - 0.0894841775 * a - 1.2914855480 * b) ** 3
    return (4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
            -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
            -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s)

def oklch_to_hex(L, C, h):
    """The color, with its chroma reduced until it fits sRGB."""
    L = min(max(L, 0), 1)
    lo, hi = 0.0, C
    if not all(-1e-4 <= c <= 1 + 1e-4 for c in _oklch_to_linear(L, C, h)):
        for _ in range(30):
            mid = (lo + hi) / 2
            if all(-1e-4 <= c <= 1 + 1e-4 for c in _oklch_to_linear(L, mid, h)):
                lo = mid
            else:
                hi = mid
        C = lo
    return "".join(f"{round(min(max(_to_srgb(min(max(c, 0), 1)), 0), 1) * 255):02x}" for c in _oklch_to_linear(L, C, h))

WARMEST_HUE = 88

def is_warm(hue):
    return hue < 120 or hue > 340

def recolor(hex_color, variant):
    L, C, h = hex_to_oklch(hex_color)
    if C < 0.01:  # white stars and greys stay as they are
        return hex_color
    warm = is_warm(h)
    shift, chroma, lightness = variant[1] if warm else variant[0]
    hue = h + shift
    if warm and shift > 0 and h < 120:
        # Warm colors go as far as gold; past it, the sun turns green.
        hue = min(hue, max(h, WARMEST_HUE))
    return oklch_to_hex(L + lightness, C * chroma, hue)

def recolor_svg(text, variant):
    return re.sub(r"#([0-9a-fA-F]{6})\b", lambda m: "#" + recolor(m.group(1).lower(), variant), text)

def read_asset(name):
    return open(os.path.join(base, "Assets", name)).read()

def make_icon(name, variant):
    """AppIcon-<name>.icon: Breathia's icon with every layer recolored. iPhone and iPad only — the
    watch can't change its icon — so the watch's background is left out."""
    bundle = os.path.join(icons_out, f"AppIcon-{name}.icon")
    shutil.rmtree(bundle, ignore_errors=True)
    os.makedirs(os.path.join(bundle, "Assets"))
    icon = json.load(open(os.path.join(base, "icon.json")))
    icon = copy.deepcopy(icon)
    for group in icon["groups"]:
        for layer in group["layers"]:
            layer["image-name-specializations"] = [
                s for s in layer["image-name-specializations"] if s.get("idiom") != "watchOS"
            ]
            for s in layer["image-name-specializations"]:
                out = os.path.join(bundle, "Assets", s["value"])
                open(out, "w").write(recolor_svg(read_asset(s["value"]), variant))
    icon["supported-platforms"] = {"squares": "shared"}
    with open(os.path.join(bundle, "icon.json"), "w") as f:
        json.dump(icon, f, indent=2)
        f.write("\n")

# The largest the app shows an icon preview, in points. Xcode stores vector previews as bitmaps at
# their declared size, so declaring the artwork's 1024 points would make each preview megabytes.
PREVIEW_SIZE = 96

def layer_body(name, prefix):
    """A layer's defs and shapes, with its gradient ids made unique and the waves' 1088-point
    canvas offset undone, so every layer shares the background's 1024-point coordinates."""
    text = read_asset(name)
    text = re.sub(r'id="([^"]+)"', rf'id="{prefix}-\1"', text)
    text = re.sub(r"url\(#([^)]+)\)", rf"url(#{prefix}-\1)", text)
    inner = text.split(">", 1)[1].rsplit("</svg>", 1)[0]
    return inner.replace('<g transform="translate(32 32)">', "<g>")

def preview_svg(dark, variant):
    suffix = "-dark" if dark else ""
    layers = [f"background{suffix}.svg", f"sun{suffix}.svg", f"wave-back{suffix}.svg", f"wave-front{suffix}.svg"]
    body = "".join(layer_body(layer, f"l{i}") for i, layer in enumerate(layers))
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{PREVIEW_SIZE}" height="{PREVIEW_SIZE}" '
           f'viewBox="0 0 1024 1024">{body}</svg>\n')
    return recolor_svg(svg, variant) if variant else svg

def make_preview(name, variant):
    imageset = os.path.join(previews_out, f"IconPreview-{name}.imageset")
    shutil.rmtree(imageset, ignore_errors=True)
    os.makedirs(imageset)
    open(os.path.join(imageset, "preview.svg"), "w").write(preview_svg(False, variant))
    open(os.path.join(imageset, "preview_dark.svg"), "w").write(preview_svg(True, variant))
    contents = {
        "images": [
            {"filename": "preview.svg", "idiom": "universal"},
            {"appearances": [{"appearance": "luminosity", "value": "dark"}],
             "filename": "preview_dark.svg", "idiom": "universal"},
        ],
        "info": {"author": "xcode", "version": 1},
        "properties": {"preserves-vector-representation": True},
    }
    with open(os.path.join(imageset, "Contents.json"), "w") as f:
        json.dump(contents, f, indent=2)
        f.write("\n")

# The icon colors the app takes, from the icon's artwork. The accent is the far wave's deep blue,
# at a lightness that reads on light and dark backgrounds. The wash fades from the sky to the sun's
# glow in light mode, and from the night sky to the moon's halo in dark mode.
ACCENT = "4a96cc"
ACCENT_LIGHTNESS = 0.56
WASH = {"light": ("253a8c", "ff9f73"), "dark": ("253a8c", "7f8fe6")}
# Stronger in dark mode, where the icon's colors are deeper. (top opacity, middle opacity)
WASH_OPACITY = {"light": (0.16, 0.10), "dark": (0.30, 0.14)}
WASH_LOCATIONS = (0.0, 0.35, 0.7)

def themed(hex_color, variant):
    return recolor(hex_color, variant) if variant else hex_color

def accent(variant):
    L, C, h = hex_to_oklch(themed(ACCENT, variant))
    return oklch_to_hex(ACCENT_LIGHTNESS, C, h)

def swift_color(hex_color, opacity):
    r, g, b = (int(hex_color[i:i + 2], 16) for i in (0, 2, 4))
    return f"PlatformColor(red: {r / 255:.3f}, green: {g / 255:.3f}, blue: {b / 255:.3f}, alpha: {opacity})"

def palette_case(case, variant):
    (light_top, light_middle), (dark_top, dark_middle) = WASH["light"], WASH["dark"]
    (light_top_opacity, light_middle_opacity), (dark_top_opacity, dark_middle_opacity) = WASH_OPACITY["light"], WASH_OPACITY["dark"]
    # The classic icon keeps the system accent color, so the app looks as it always has.
    accent_line = "nil" if variant is None else f"Color({swift_color(accent(variant), 1)})"
    return (
        f"        case .{case}:\n"
        f"            Palette(\n"
        f"                accent: {accent_line},\n"
        f"                sky: .dynamic(light: {swift_color(themed(light_top, variant), light_top_opacity)}, "
        f"dark: {swift_color(themed(dark_top, variant), dark_top_opacity)}),\n"
        f"                glow: .dynamic(light: {swift_color(themed(light_middle, variant), light_middle_opacity)}, "
        f"dark: {swift_color(themed(dark_middle, variant), dark_middle_opacity)})\n"
        f"            )"
    )

def write_palettes(cases):
    locations = ", ".join(str(l) for l in WASH_LOCATIONS)
    swift = f"""// Generated by AppIcon/make_icons.py from the app icon; run it again instead of editing this file.

import SwiftUI
#if canImport(UIKit)
import UIKit
private typealias PlatformColor = UIColor
#else
import AppKit
private typealias PlatformColor = NSColor
#endif

extension AppIconVariant {{
    /// An icon's colors, taken from its artwork: the accent the app's controls take, and the
    /// background wash's sky and glow, already at the wash's opacity.
    struct Palette {{
        /// `nil` keeps the system accent color.
        let accent: Color?
        let sky: Color
        let glow: Color

        /// Where the wash's colors sit, from the top: the sky, the glow, and where it has faded out.
        static let locations: [CGFloat] = [{locations}]
    }}

    var palette: Palette {{
        switch self {{
{chr(10).join(cases)}
        }}
    }}
}}

private extension Color {{
    static func dynamic(light: PlatformColor, dark: PlatformColor) -> Color {{
        #if canImport(UIKit)
        Color(UIColor {{ traits in traits.userInterfaceStyle == .dark ? dark : light }})
        #else
        Color(NSColor(name: nil) {{ appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        }})
        #endif
    }}
}}
"""
    with open(palette_out, "w") as f:
        f.write(swift)

os.makedirs(icons_out, exist_ok=True)
os.makedirs(previews_out, exist_ok=True)
with open(os.path.join(previews_out, "Contents.json"), "w") as f:
    json.dump({"info": {"author": "xcode", "version": 1}}, f, indent=2)
    f.write("\n")

make_preview("Default", None)
cases = [palette_case("classic", None)]
for name, variant in VARIANTS.items():
    make_icon(name, variant)
    make_preview(name, variant)
    cases.append(palette_case(name[0].lower() + name[1:], variant))
    print(name)
write_palettes(cases)
