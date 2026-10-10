#!/usr/bin/env python3
"""Remove white margins from every page of a PDF, losslessly.

Two modes:

  trim  Shrink each page's physical size (MediaBox) to its content bounding
        box, i.e. delete the surrounding whitespace entirely. Page sizes may
        then differ page to page. Best when you just want the whitespace gone.

  fit   First trim to content, then place that content, scaled up and centered,
        onto a fixed standard page (default A4) leaving a small uniform margin.
        Best for printing: every page becomes a real A4/Letter sheet, so
        "actual size / 100%" printing no longer leaves big empty borders.

Content is detected by rendering each page to a raster image and finding the
extent of non-white pixels. Only the page's crop/media boxes (or a re-embedded
vector copy) change -- text and vector graphics are never rasterized, so the
output stays sharp and selectable.

Usage examples:
  python crop_pdf_margins.py in.pdf                       # trim, -> in_cropped.pdf
  python crop_pdf_margins.py in.pdf -o out.pdf --mode trim
  python crop_pdf_margins.py in.pdf --mode fit --paper a4 --margin-mm 5
  python crop_pdf_margins.py in.pdf --mode fit --paper letter --margin-mm 8
"""
import argparse
import os
import sys

import pymupdf  # PyMuPDF (a.k.a. fitz). Install: pip install pymupdf

# Standard paper sizes in PDF points (1 pt = 1/72 inch).
PAPER = {
    "a4": (595.2755905511812, 841.8897637795276),      # 210 x 297 mm
    "a3": (841.8897637795276, 1190.5511811023623),     # 297 x 420 mm
    "a5": (419.5275590551181, 595.2755905511812),       # 148 x 210 mm
    "letter": (612.0, 792.0),                            # 8.5 x 11 in
    "legal": (612.0, 1008.0),                            # 8.5 x 14 in
}

MM_PER_PT = 25.4 / 72.0


def mm_to_pt(mm):
    return mm / MM_PER_PT


def detect_content_bbox(page, zoom, threshold):
    """Return (x0,y0,x1,y1) content box in page points, or None if the page is
    effectively blank. Coordinates are relative to page.rect's top-left origin.
    """
    mat = pymupdf.Matrix(zoom, zoom)
    pix = page.get_pixmap(matrix=mat, alpha=False)
    w, h, n = pix.width, pix.height, pix.n
    samples = pix.samples
    stride = w * n
    thr = threshold

    min_x, min_y, max_x, max_y = w, h, -1, -1
    for y in range(h):
        base = y * stride
        left = None
        for x in range(w):
            off = base + x * n
            if samples[off] < thr or samples[off + 1] < thr or samples[off + 2] < thr:
                left = x
                break
        if left is None:
            continue
        right = left
        for x in range(w - 1, left - 1, -1):
            off = base + x * n
            if samples[off] < thr or samples[off + 1] < thr or samples[off + 2] < thr:
                right = x
                break
        if left < min_x:
            min_x = left
        if right > max_x:
            max_x = right
        if y < min_y:
            min_y = y
        if y > max_y:
            max_y = y

    if max_x < 0:
        return None
    return (min_x / zoom, min_y / zoom, (max_x + 1) / zoom, (max_y + 1) / zoom)


def content_clip(page, bbox, pad):
    """Turn a detected bbox into an absolute clip Rect on the source page,
    clamped to the page and expanded by `pad` points."""
    pr = page.rect
    x0, y0, x1, y1 = bbox
    cx0 = pr.x0 + max(0.0, x0 - pad)
    cy0 = pr.y0 + max(0.0, y0 - pad)
    cx1 = pr.x0 + min(pr.width, x1 + pad)
    cy1 = pr.y0 + min(pr.height, y1 + pad)
    return pymupdf.Rect(cx0, cy0, cx1, cy1)


def run_trim(src, out, args):
    for i, page in enumerate(src):
        pr = page.rect
        bbox = detect_content_bbox(page, args.zoom, args.threshold)
        if bbox is None:
            np = out.new_page(width=pr.width, height=pr.height)
            np.show_pdf_page(np.rect, src, i)
            print(f"page {i+1}: blank, kept {pr.width:.0f}x{pr.height:.0f}")
            continue
        clip = content_clip(page, bbox, args.pad)
        if clip.width < 1 or clip.height < 1:
            np = out.new_page(width=pr.width, height=pr.height)
            np.show_pdf_page(np.rect, src, i)
            print(f"page {i+1}: content too small, kept original")
            continue
        # New physical page == content box; embed the clipped region 1:1.
        np = out.new_page(width=clip.width, height=clip.height)
        np.show_pdf_page(np.rect, src, i, clip=clip)
        print(f"page {i+1}: {pr.width:.0f}x{pr.height:.0f} -> "
              f"{clip.width:.0f}x{clip.height:.0f} (trimmed)")


def run_fit(src, out, args):
    pw, ph = PAPER[args.paper]
    margin = mm_to_pt(args.margin_mm)
    avail_w = pw - 2 * margin
    avail_h = ph - 2 * margin
    if avail_w <= 0 or avail_h <= 0:
        sys.exit(f"error: margin {args.margin_mm}mm too large for {args.paper}")
    for i, page in enumerate(src):
        pr = page.rect
        bbox = detect_content_bbox(page, args.zoom, args.threshold)
        clip = content_clip(page, bbox, args.pad) if bbox else pr
        cw, ch = clip.width, clip.height
        scale = min(avail_w / cw, avail_h / ch)
        tw, th = cw * scale, ch * scale
        x0 = (pw - tw) / 2
        y0 = (ph - th) / 2
        target = pymupdf.Rect(x0, y0, x0 + tw, y0 + th)
        np = out.new_page(width=pw, height=ph)
        np.show_pdf_page(target, src, i, clip=clip)
        print(f"page {i+1}: content {cw:.0f}x{ch:.0f} -> {args.paper.upper()} "
              f"{pw:.0f}x{ph:.0f}, scale x{scale:.2f}, centered")


def main():
    ap = argparse.ArgumentParser(description="Remove white PDF margins (lossless).")
    ap.add_argument("input", help="source PDF path")
    ap.add_argument("-o", "--output", help="output PDF path (default: <input>_cropped.pdf)")
    ap.add_argument("--mode", choices=["trim", "fit"], default="trim",
                    help="trim: page=content size; fit: place on standard paper (default: trim)")
    ap.add_argument("--paper", choices=sorted(PAPER), default="a4",
                    help="target paper for fit mode (default: a4)")
    ap.add_argument("--margin-mm", type=float, default=5.0,
                    help="uniform margin in mm for fit mode (default: 5)")
    ap.add_argument("--pad", type=float, default=2.0,
                    help="safety padding in points kept around content (default: 2)")
    ap.add_argument("--dpi", type=int, default=150,
                    help="render DPI for content detection (default: 150)")
    ap.add_argument("--threshold", type=int, default=245,
                    help="pixel < this on any RGB channel counts as content, 0-255 (default: 245)")
    args = ap.parse_args()

    if not os.path.isfile(args.input):
        sys.exit(f"error: input not found: {args.input}")
    if not (0 < args.threshold <= 255):
        sys.exit("error: --threshold must be in 1..255")
    args.zoom = args.dpi / 72.0

    out_path = args.output
    if not out_path:
        base, ext = os.path.splitext(args.input)
        out_path = f"{base}_cropped{ext or '.pdf'}"
    if os.path.abspath(out_path) == os.path.abspath(args.input):
        sys.exit("error: output would overwrite input; choose a different --output")

    src = pymupdf.open(args.input)
    out = pymupdf.open()
    try:
        if args.mode == "trim":
            run_trim(src, out, args)
        else:
            run_fit(src, out, args)
        out.save(out_path, garbage=4, deflate=True)
    finally:
        out.close()
        src.close()
    print(f"saved: {out_path}")


if __name__ == "__main__":
    main()
