---
description: Convert an image to a compressed square (1:1) PNG padded with transparent bars, ready to post anywhere
argument-hint: "<image> [-o OUTPUT] [--quality MIN-MAX]"
---
Run the `social-square` command (Nix-managed, defined in
`~/config/nix-aron/home/aron/packages.nix`, logic in
`~/config/nix-aron/home/aron/scripts/social-square.sh`).

It takes any image ImageMagick can read, bakes in EXIF rotation, strips metadata,
pads the short side with transparent bars to a 1:1 ratio, and writes a compressed
PNG next to the input as `<name>-square.png` (override with `-o`).

User arguments: $@

Behaviour:

- No arguments: ask which image. Do not guess a file from the working directory.
- Arguments given: pass them through verbatim.
- Compression is pngquant `--quality=80-98` plus a lossless oxipng pass; the loss is
  around 39 dB PSNR, i.e. not visible at normal viewing size. Raise the floor with
  `--quality 90-100` if the user says the result looks degraded.
- pngquant exiting 99 means it could not hit the quality floor; the script then keeps
  the lossless image, so a big output is a signal, not a bug.

Report afterwards: output path, final square size in px, file size, and how it compares
to the input.

Note when it applies: PNG is lossless-by-nature, so a JPEG photo usually comes out
*larger* as a PNG even after quantisation. Transparent bars require alpha and therefore
PNG, so this is a trade, not a fixable regression — say so instead of hunting for
extra compression.
