import os
import sys
from PIL import Image
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas


def sorted_images(folder):
    return sorted(
        f for f in os.listdir(folder)
        if f.lower().endswith(('.png', '.jpg', '.jpeg', '.tif', '.tiff'))
    )


def make_pdf(orig_dir, canny_dir, linked_dir, out_pdf, rows_per_page=6):
    origs  = sorted_images(orig_dir)
    cannys = sorted_images(canny_dir)
    links  = sorted_images(linked_dir)

    if not (len(origs) == len(cannys) == len(links)):
        raise ValueError("Folders must contain the same number of images")

    c = canvas.Canvas(out_pdf, pagesize=A4)
    page_w, page_h = A4

    # ---- Layout parameters ----
    label_margin  = 25   # space for rotated filenames

    left_margin   = 40 + label_margin
    right_margin  = 40
    top_margin    = 40
    bottom_margin = 40

    header_height = 30

    col_gap = 10
    row_gap = 15

    usable_w = page_w - left_margin - right_margin - 2 * col_gap
    usable_h = (
        page_h
        - top_margin
        - bottom_margin
        - header_height
        - (rows_per_page - 1) * row_gap
    )

    col_w = usable_w / 3
    row_h = usable_h / rows_per_page

    def draw_rotated_label(x, y, text):
        c.saveState()
        c.translate(x, y)
        c.rotate(90)
        c.setFont("Helvetica", 8)
        c.drawString(0, 0, text)
        c.restoreState()

    def draw_row(y_top, img_paths):
        for i, path in enumerate(img_paths):
            img = Image.open(path)
            img_w, img_h = img.size

            scale = min(col_w / img_w, row_h / img_h)
            w = img_w * scale
            h = img_h * scale

            x = left_margin + i * (col_w + col_gap) + (col_w - w) / 2
            y = y_top - h

            c.drawImage(
                path,
                x,
                y,
                width=w,
                height=h,
                preserveAspectRatio=True
            )

    total = len(origs)

    for start in range(0, total, rows_per_page):
        # ---- Column headers ----
        header_y = page_h - top_margin
        c.setFont("Helvetica-Bold", 10)

        headers = ["Original", "2D Canny", "3D Linked"]
        for j, text in enumerate(headers):
            x = left_margin + j * (col_w + col_gap) + col_w / 2
            c.drawCentredString(x, header_y, text)

        # ---- Rows start directly below header ----
        y = header_y - header_height

        for r in range(rows_per_page):
            idx = start + r
            if idx >= total:
                break

            # Rotated filename on the left
            fname = origs[idx]
            label_x = left_margin - label_margin + 5
            label_y = y - row_h / 2
            draw_rotated_label(label_x, label_y, fname)

            # Draw image row
            draw_row(y, [
                os.path.join(orig_dir, origs[idx]),
                os.path.join(canny_dir, cannys[idx]),
                os.path.join(linked_dir, links[idx]),
            ])

            y -= (row_h + row_gap)

        c.showPage()

    c.save()
    print(f"PDF written to: {out_pdf}")


if __name__ == "__main__":
    if len(sys.argv) != 6:
        print("Usage:")
        print("  python make_canny_pdf.py <originals> <canny2d> <linked3d> <output.pdf> <rows_per_page>")
        sys.exit(1)

    make_pdf(
        sys.argv[1],
        sys.argv[2],
        sys.argv[3],
        sys.argv[4],
        int(sys.argv[5]),
    )
