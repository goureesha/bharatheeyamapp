# Implementation Plan - Shloka-by-Shloka Translation of Remaining Upanishads (Batch 1)

This plan details the next phase of the translation project: converting the remaining 371 chapters of other Upanishad books to the **shloka-by-shloka style** (Annapurna Chapter 1 style). 

Due to the volume of chapters (371 chapters total across 229 books), we will execute the refactoring in batches. This plan defines **Batch 1**, which focuses on key, highly-referenced Upanishad books.

## Proposed Changes (Batch 1)

We will modify the following 24 chapters to restructure them with shloka-by-shloka translations:

### 1. Annapurna Upanishad (4 chapters)
- [upanishad_annapurnaupan_ch_2.txt](file:///d:/bharatheeyam%20books/assets/data/chapters/upanishad_annapurnaupan_ch_2.txt)
- [upanishad_annapurnaupan_ch_3.txt](file:///d:/bharatheeyam%20books/assets/data/chapters/upanishad_annapurnaupan_ch_3.txt)
- [upanishad_annapurnaupan_ch_4.txt](file:///d:/bharatheeyam%20books/assets/data/chapters/upanishad_annapurnaupan_ch_4.txt)
- [upanishad_annapurnaupan_ch_5.txt](file:///d:/bharatheeyam%20books/assets/data/chapters/upanishad_annapurnaupan_ch_5.txt)

### 2. Aitareya Upanishad With Vedic Accents (5 chapters)
- [upanishad_aitareyaupanvedic_ch_1.txt](file:///d:/bharatheeyam%20books/assets/data/chapters/upanishad_aitareyaupanvedic_ch_1.txt) to [upanishad_aitareyaupanvedic_ch_5.txt](file:///d:/bharatheeyam%20books/assets/data/chapters/upanishad_aitareyaupanvedic_ch_5.txt)

### 3. Brihadaranyaka Upanishad (6 chapters)
- [upanishad_brihadaranyaka_ch_1.txt](file:///d:/bharatheeyam%20books/assets/data/chapters/upanishad_brihadaranyaka_ch_1.txt) to [upanishad_brihadaranyaka_ch_6.txt](file:///d:/bharatheeyam%20books/assets/data/chapters/upanishad_brihadaranyaka_ch_6.txt)

### 4. Chandogyopanishad.H (9 chapters)
- [upanishad_chandogyopanishad_ch_1.txt](file:///d:/bharatheeyam%20books/assets/data/chapters/upanishad_chandogyopanishad_ch_1.txt) to [upanishad_chandogyopanishad_ch_9.txt](file:///d:/bharatheeyam%20books/assets/data/chapters/upanishad_chandogyopanishad_ch_9.txt)

---

### Execution Strategy

We will reuse the specialized `translation_helper` subagent to process these files sequentially in smaller subsets (to prevent rate limits):
1. **Subset 1**: *Annapurna Upanishad* (Chapters 2–5)
2. **Subset 2**: *Aitareya Upanishad With Vedic Accents* (Chapters 1–5)
3. **Subset 3**: *Brihadaranyaka Upanishad* (Chapters 1–6)
4. **Subset 4**: *Chandogyopanishad.H* (Chapters 1–9)

For each chapter:
- Split the text into individual Sanskrit blocks (verses ending with standard dandas or vertical bars).
- Generate a dedicated **ಶಬ್ದಾರ್ಥ:** (word-meanings) and **ಭಾವಾರ್ಥ:** (overall meaning) directly underneath each block.
- Remove the old summary blocks from the end.
- Standardize the punctuation and ensure exactly 0% non-permitted characters (no Latin/Devanagari characters).

## Verification Plan

### Automated Tests
- **Verification Script**: Run `verify_all_characters.py` to confirm 0 bad characters.
- **Audit Script**: Run `aggregate_upanishad_status.py` to verify that the target books have successfully moved to the "Fully Shloka-by-Shloka" status.

### Manual Verification
- Review random chapters from each of the 4 books to ensure translations are natural, grammatically correct, and properly aligned.
