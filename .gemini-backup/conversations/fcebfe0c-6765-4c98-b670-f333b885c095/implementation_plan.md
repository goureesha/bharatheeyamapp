# Implementation Plan - Translate and Restructure Shiva Purana Rudra Kumara Chapters 17 and 18

This plan describes the process to translate and restructure the Sanskrit verses/prose blocks of Shiva Purana Rudra Samhita (Kumara Khanda) Chapters 17 and 18 into a high-quality Kannada shloka-by-shloka (Sanskrit + Shabdartha + Bhavartha) format.

## Proposed Changes

We will modify the following 2 chapter files in `assets/data/chapters/` to fully translate and format all verses:

- [purana_shiva_rudra_kumara_ch_17.txt](file:///d:/bharatheeyam%20books/assets/data/chapters/purana_shiva_rudra_kumara_ch_17.txt) (64 blocks)
- [purana_shiva_rudra_kumara_ch_18.txt](file:///d:/bharatheeyam%20books/assets/data/chapters/purana_shiva_rudra_kumara_ch_18.txt) (84 blocks)

### Restructuring Rules
- Each block of Sanskrit is followed by:
  - `"ಶಬ್ದಾರ್ಥ:"` header and a bulleted list of word meanings separated by hyphens (`-`).
  - `"ಭಾವಾರ್ಥ:"` header and a clean Kannada explanation of the verse.
- Ensure 0% foreign/Devanagari/Latin characters in the Shabdartha and Bhavartha sections. Only Kannada characters, spaces, and punctuation are allowed.
- Shabdartha separators must be hyphens (`-`), not equals signs (`=`).

---

## Detailed Steps

### Step 1: Chunking the Input
- Chunk the 148 blocks into 13 JSON files in the scratch directory (11-13 blocks per batch).

### Step 2: Translation Subagents
- Define and invoke `shridhisha_translator` subagents to process the batches in waves (max 3 concurrent subagents) to avoid rate limit issues.

### Step 3: Merging & Reconstruction
- Write a merge script `merge_shiva_rudra_kumara_ch17_18.py` to compile the translated batches back into their respective files.

### Step 4: Verification
- Write and run a validation script `validate_shiva_rudra_kumara_ch17_18.py` to verify block counts, headers, and script range.
- Run a check script to look for Latin character typos in Sanskrit verses.

### Step 5: Git Operations
- Stage the changes, commit, and push to GitHub.

---

## Verification Plan

### Automated Tests
- Run `validate_shiva_rudra_kumara_ch17_18.py` to check block counts, character compliance, and formatting on both chapters.
- Run `check_latin_sanskrit_kumara_ch17_18.py` to ensure no Latin characters remain.

### Manual Verification
- View sample lines of each merged file using `view_file` to verify readability, layout, and correct formatting.
