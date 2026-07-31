#!/usr/bin/env python3
"""addlogo_helper.py -- composite a logo onto a base image (e.g. an exported Stata graph).

This is the compositing engine behind the Stata command ``addlogo`` but it also
works as a stand-alone CLI, so you can stamp any image from a shell / Makefile.

Example
-------
    python addlogo_helper.py --base fig.png --logo logo.png --out fig_branded.png \
        --position se --scale 0.12 --pad 0.02 --opacity 1.0

Options
-------
--position  9 anchors: nw n ne w c e sw s se
            (long forms northwest/north/.../southeast and top-left etc. accepted)
--scale     logo WIDTH as a fraction of the BASE image width (0.12 = 12%)
--pad       margin from the image edge as a fraction of base width (0.02 = 2%)
--opacity   0..1 multiplier applied to the logo's alpha (1 = opaque)
--bg        flatten colour for formats without alpha (jpg/pdf); default white

Notes
-----
* Requires Pillow:  pip install Pillow
* Output format is inferred from the --out extension (png, tif, jpg, pdf, ...).
* The base graph is kept at full resolution; only the logo is resampled
  (Lanczos). Any embedded DPI on the base image is carried through to the
  output so physical size is preserved when you drop it into LaTeX / Word.
"""
import argparse
import os
import sys

# 9-anchor position vocabulary (+ friendly aliases)
_ALIASES = {
    "northwest": "nw", "north": "n", "northeast": "ne",
    "west": "w", "center": "c", "centre": "c", "middle": "c", "east": "e",
    "southwest": "sw", "south": "s", "southeast": "se",
    "topleft": "nw", "top-left": "nw", "top": "n",
    "topright": "ne", "top-right": "ne",
    "bottomleft": "sw", "bottom-left": "sw", "bottom": "s",
    "bottomright": "se", "bottom-right": "se",
    "left": "w", "right": "e",
}
_VALID = {"nw", "n", "ne", "w", "c", "e", "sw", "s", "se"}


def _die(msg):
    sys.stderr.write("addlogo_helper.py ERROR: " + msg + "\n")
    sys.exit(1)


def main():
    p = argparse.ArgumentParser(description="Composite a logo onto a base image.")
    p.add_argument("--base", required=True, help="base image (the exported graph)")
    p.add_argument("--logo", required=True, help="logo image (PNG w/ transparency ideal)")
    p.add_argument("--out", required=True, help="output file (format from extension)")
    p.add_argument("--position", default="se")
    p.add_argument("--scale", type=float, default=0.12)
    p.add_argument("--pad", type=float, default=0.02)
    p.add_argument("--opacity", type=float, default=1.0)
    p.add_argument("--bg", default="white")
    a = p.parse_args()

    try:
        from PIL import Image
    except ImportError:
        _die("Pillow is not installed for this interpreter (%s).\n"
             "         Fix with:  %s -m pip install Pillow"
             % (sys.executable, sys.executable))

    for path, label in ((a.base, "base"), (a.logo, "logo")):
        if not os.path.isfile(path):
            _die("%s file not found: %s" % (label, path))

    pos = _ALIASES.get(a.position.strip().lower(), a.position.strip().lower())
    if pos not in _VALID:
        _die("unknown position '%s'. Use one of: nw n ne w c e sw s se" % a.position)

    base = Image.open(a.base).convert("RGBA")
    logo = Image.open(a.logo).convert("RGBA")
    bw, bh = base.size

    # --- size the logo relative to the base width ---
    target_w = max(1, int(round(a.scale * bw)))
    lw, lh = logo.size
    target_h = max(1, int(round(target_w * lh / float(lw))))
    logo = logo.resize((target_w, target_h), Image.LANCZOS)

    # --- apply opacity by scaling the alpha channel ---
    op = min(max(a.opacity, 0.0), 1.0)
    if op < 1.0:
        alpha = logo.getchannel("A").point(lambda v: int(round(v * op)))
        logo.putalpha(alpha)

    # --- anchor geometry ---
    pad = int(round(a.pad * bw))
    if pos in ("nw", "w", "sw"):
        x = pad
    elif pos in ("n", "c", "s"):
        x = (bw - target_w) // 2
    else:                                   # ne, e, se
        x = bw - target_w - pad
    if pos in ("nw", "n", "ne"):
        y = pad
    elif pos in ("w", "c", "e"):
        y = (bh - target_h) // 2
    else:                                   # sw, s, se
        y = bh - target_h - pad

    canvas = base.copy()
    canvas.alpha_composite(logo, (x, y))

    # --- save, carrying DPI through; flatten for alpha-less formats ---
    save_kwargs = {}
    dpi = base.info.get("dpi")
    if dpi:
        save_kwargs["dpi"] = dpi

    out_dir = os.path.dirname(os.path.abspath(a.out))
    if out_dir and not os.path.isdir(out_dir):
        os.makedirs(out_dir, exist_ok=True)

    ext = os.path.splitext(a.out)[1].lower().lstrip(".")
    if ext in ("jpg", "jpeg", "pdf", "bmp"):
        bg = Image.new("RGBA", canvas.size, a.bg)
        Image.alpha_composite(bg, canvas).convert("RGB").save(a.out, **save_kwargs)
    else:
        canvas.save(a.out, **save_kwargs)

    print("addlogo_helper.py OK: wrote %s  (%dx%d, logo %dx%d @ %s, pad %dpx, opacity %g)"
          % (a.out, bw, bh, target_w, target_h, pos, pad, op))


if __name__ == "__main__":
    main()
