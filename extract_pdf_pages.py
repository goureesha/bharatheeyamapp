import fitz
import os

pdf_path = r'D:\bharatheeyamapp clone\pdfs\5_6055258040242799489.pdf'
output_dir = r'D:\bharatheeyamapp clone\pdfs\pages'
os.makedirs(output_dir, exist_ok=True)

doc = fitz.open(pdf_path)
print(f'Total pages: {doc.page_count}')

# Extract first 5 pages as images for analysis
for i in range(min(5, doc.page_count)):
    page = doc[i]
    # Render at 200 DPI for good quality
    mat = fitz.Matrix(200/72, 200/72)
    pix = page.get_pixmap(matrix=mat)
    output_path = os.path.join(output_dir, f'page_{i+1}.png')
    pix.save(output_path)
    print(f'Saved page {i+1} -> {output_path} ({pix.width}x{pix.height})')

doc.close()
print('Done!')
