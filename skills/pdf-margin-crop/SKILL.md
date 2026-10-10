---
name: pdf-margin-crop
description: >-
  Remove white margins (whitespace borders) from every page of a PDF, losslessly.
  Use this whenever the user wants to crop, trim, or delete the blank/white
  margins around PDF pages, tighten page borders, make scanned or exported PDFs
  fit their content, get rid of big empty borders when printing, or reflow pages
  onto a standard sheet (A4/Letter) so "actual size" printing has no large white
  or black borders. Trigger it for phrases like "去掉PDF白边", "裁掉页边空白",
  "打印有很大白边/黑边", "crop PDF margins", "remove whitespace from PDF",
  "fit PDF to A4 without borders", even when the user does not name a tool.
compatibility: Requires Python 3 and the PyMuPDF package (pip install pymupdf).
---

# PDF Margin Crop

Remove the white margins around PDF pages. Content is detected by rendering each
page and finding the non-white bounding box; the page geometry is then adjusted.
The change is lossless — text and vector graphics are re-embedded, never
rasterized — so the output stays sharp and selectable.

## Choose the mode first

There are two fundamentally different outcomes. Pick based on what the user
actually needs, and ask only if it is genuinely ambiguous:

- **trim** — each page's *physical size* (MediaBox) shrinks to its content box,
  so the whitespace is gone entirely. Pages may end up different sizes. Use this
  when the user just wants the margins removed and does not care about a uniform
  paper size.

- **fit** — first trims to content, then scales that content up and centers it
  on a fixed standard sheet (A4 by default) leaving a small uniform margin. Use
  this when the target is **printing**: every page becomes a real A4/Letter
  sheet, so printing at "actual size / 100%" no longer leaves a big empty border.

Why this distinction matters: users often say "I removed the margins but printing
still has huge white/black borders." That is almost always because only the
CropBox was changed, or because the trimmed page is far smaller than the printer's
paper. `trim` fixes the PDF; `fit` fixes the *print result*. When someone
complains about borders **when printing**, prefer `fit`.

## Prerequisite

The script needs PyMuPDF. Check and install if missing (prefer a domestic mirror
when the default index times out):

```bash
python3 -c "import pymupdf" 2>/dev/null || \
  pip install --user --break-system-packages \
    -i https://pypi.tuna.tsinghua.edu.cn/simple pymupdf
```

If the environment blocks `pip` with an "externally-managed" error, add
`--break-system-packages` as shown; if `python3 -m venv` is available, a venv is
cleaner.

## Usage

The bundled script `scripts/crop_pdf_margins.py` does the work. Always write to a
new file and keep the original.

```bash
# Trim: page size becomes the content size (whitespace deleted)
python3 scripts/crop_pdf_margins.py input.pdf -o output.pdf --mode trim

# Fit: place content centered on A4 with a small uniform margin (good for print)
python3 scripts/crop_pdf_margins.py input.pdf -o output_A4.pdf \
    --mode fit --paper a4 --margin-mm 5
```

Key options:

- `--mode {trim,fit}` — default `trim`.
- `--paper {a4,a3,a5,letter,legal}` — target sheet for `fit` (default `a4`).
- `--margin-mm N` — uniform margin for `fit` in millimeters (default `5`).
- `--pad N` — safety padding in points kept around detected content (default `2`).
  Increase slightly if content looks clipped at the edge.
- `--dpi N` — detection render resolution (default `150`). Raise for very fine
  content, lower to speed up huge documents.
- `--threshold N` — a pixel is "content" if any RGB channel is below `N` (0–255,
  default `245`). Lower it (e.g. `230`) if a faint off-white background is being
  treated as content and nothing gets cropped; raise it toward `254` to catch
  very light content.

## Verify the result

Do not claim success from the script log alone. Confirm both the geometry and the
visual result:

```bash
# 1) Check page sizes actually changed (MediaBox, not just CropBox)
python3 -c "import pymupdf,sys; d=pymupdf.open(sys.argv[1]); \
[print(i+1,[round(v,1) for v in p.mediabox]) for i,p in enumerate(d)]" output.pdf

# 2) Render a page to an image and inspect it for leftover borders
python3 -c "import pymupdf,sys; pymupdf.open(sys.argv[1])[0]\
.get_pixmap(dpi=120).save('check_p1.png')" output.pdf
```

Then view `check_p1.png`. A correct result shows content tight to the edges
(trim) or centered with only the requested small margin (fit). Remove the
temporary PNG afterward.

Common pitfall: if MediaBox is unchanged but CropBox shrank, most printers ignore
it and still print the original paper size — that is exactly the "still has big
borders" complaint. This script sets the physical page (new MediaBox), so both
viewers and printers honor it.

## Notes

- The original file is never modified; output goes to a separate path.
- `fit` scales content proportionally, so when the content's aspect ratio differs
  from the sheet, one dimension reaches the margin first and the other keeps a bit
  of extra centered space. That is expected and avoids distortion.
- Blank pages are passed through unchanged.
