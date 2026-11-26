#!/usr/bin/env python3
# Print a wallpaper's average color as normalized RGB multipliers (0..1),
# scaled so its brightest channel is 1. Used to tint the Plymouth animation.
import sys

from PIL import Image

image = Image.open(sys.argv[1]).convert("RGB").resize((64, 64))
pixels = list(image.getdata())
channels = [sum(p[i] for p in pixels) / len(pixels) for i in range(3)]
brightest = max(max(channels), 1.0)
print(",".join(f"{min(1.0, c / brightest):.3f}" for c in channels))
