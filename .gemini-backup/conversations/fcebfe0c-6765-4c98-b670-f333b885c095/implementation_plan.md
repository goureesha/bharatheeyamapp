# Implementation Plan - Translate and Restructure Shiva Purana Rudra Parvati Chapters 3 and 4

This plan describes the process to translate and restructure the Sanskrit verses/prose blocks of Shiva Purana Rudra Samhita (Parvati Khanda) Chapters 3 and 4 into a high-quality Kannada shloka-by-shloka (Sanskrit + Shabdartha + Bhavartha) format.

## Proposed Changes

We will modify the following 2 chapter files in `assets/data/chapters/` to fully translate and format all verses:

- [purana_shiva_rudra_parvati_ch_3.txt](file:///d:/bharatheeyam%20books/assets/data/chapters/purana_shiva_rudra_parvati_ch_3.txt) (43 verses + 1 colophon = 44 blocks)
- [purana_shiva_rudra_parvati_ch_4.txt](file:///d:/bharatheeyam%20books/assets/data/chapters/purana_shiva_rudra_parvati_ch_4.txt) (54 verses + 1 colophon = 55 blocks)

### Restructuring Rules
- Each block of Sanskrit is followed by:
  - `"ಶಬ್ದಾರ್ಥ:"` header and a bulleted list of word meanings separated by hyphens (`-`).
  - `"ಭಾವಾರ್ಥ:"` header and a clean Kannada explanation of the verse.
- Ensure 0% foreign/Devanagari/Latin characters in the Shabdartha and Bhavartha sections.

---

## Detailed Steps

### Step 1: Chunking the Input
- We have chunked the 2 chapters into 7 JSON files in the scratch directory (14 blocks per batch, except Batch 7 which has 15).

### Step 2: Translation Subagents
- Define and invoke `shridhisha_translator` subagents to process the 7 batches.
- We will execute them in sequential/paired waves to stay safely under rate limit thresholds.

### Step 3: Merging & Reconstruction
- Write a merge script `merge_shiva_rudra_parvati_ch3_4.py` to compile the translated batches back into their respective files.

### Step 4: Verification
- Write and run a validation script `validate_shiva_rudra_parvati_ch3_4.py` to verify block counts, headers, and script range.

### Step 5: Git Operations
- Stage the changes, commit, and push to GitHub.

---

## Verification Plan

### Automated Tests
- Run `validate_shiva_rudra_parvati_ch3_4.py` to check block counts, character compliance, and formatting on both chapters.

### Manual Verification
- View sample lines of each merged file using `view_file` to verify readability, layout, and correct formatting.
