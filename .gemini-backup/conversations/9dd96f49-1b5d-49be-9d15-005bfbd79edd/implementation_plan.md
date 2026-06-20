# Translate Next Batch of Upanishads (Batch 5)

Translate the next batch of three short untranslated Upanishads into Kannada, providing high-quality Shabdartha (word-by-word meanings) and Bhavartha (summary translations) for all verses and prose blocks.

## User Review Required

> [!IMPORTANT]
> The target Upanishads selected for this batch are:
> 1. **Kshurika Upanishad** (`upanishad_kshurika_ch_1.txt`)
> 2. **Hansa Upanishad** (`upanishad_hansa_ch_1.txt`)
> 3. **Narayanopanishat** (`upanishad_narayanopanishat_ch_1.txt`)

> [!WARNING]
> We will ensure:
> - Strict double newlines (`\n\n`) around Sanskrit verses/shlokas to allow proper center-alignment in the app's reader screen.
> - 0% foreign scripts (no Latin letters, no Devanagari) in the translated text blocks.
> - Bullet point punctuation: intermediate bullets must end with a semicolon `;`, and the last bullet in each block must end with a period `.`.

## Proposed Changes

### Chapters Component

#### [MODIFY] [upanishad_kshurika_ch_1.txt](file:///d:/bharatheeyam%20books/assets/data/chapters/upanishad_kshurika_ch_1.txt)
- Add Kannada translations (Shabdartha and Bhavartha) inline for all 24 verses and peace invocations.
- Ensure correct double newline separators.

#### [MODIFY] [upanishad_hansa_ch_1.txt](file:///d:/bharatheeyam%20books/assets/data/chapters/upanishad_hansa_ch_1.txt)
- Add Kannada translations (Shabdartha and Bhavartha) inline for all verses and prose blocks of the Hansa Upanishad.
- Ensure correct double newline separators.

#### [MODIFY] [upanishad_narayanopanishat_ch_1.txt](file:///d:/bharatheeyam%20books/assets/data/chapters/upanishad_narayanopanishat_ch_1.txt)
- Add Kannada translations (Shabdartha and Bhavartha) inline for all sections of the Narayanopanishat.
- Remove English comments at the end of the file.
- Ensure correct double newline separators.

## Verification Plan

### Automated Tests
- Run `python verify_all_translated_upanishads.py` in the scratch directory to verify layout, formatting, and character compliance across all files.

### Manual Verification
- View the modified txt files using the `view_file` tool to verify visual structure, double spacing, and correct bullet point punctuation.
