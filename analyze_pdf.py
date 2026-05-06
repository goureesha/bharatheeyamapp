import fitz

doc = fitz.open(r'D:\bharatheeyamapp clone\pdfs\5_6055258040242799489.pdf')
print(f'Total pages: {doc.page_count}')
title = doc.metadata.get("title", "N/A")
author = doc.metadata.get("author", "N/A")
print(f'Title: {title}')
print(f'Author: {author}')
print()

# Extract text from first 5 pages to understand structure
for i in range(min(5, doc.page_count)):
    page = doc[i]
    text = page.get_text()
    print(f'=== PAGE {i+1} ===')
    print(text[:2000])
    print()

doc.close()
