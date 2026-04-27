# Implementation Plan: Analyzing Chapter 1 Shlokas & Vyakhyanas

The goal is to analyze the first chapter of "Muhurta Chintamani" in iterative batches of 5 shlokas, extracting both the inner shloka texts and their corresponding **Vyakhyanas (commentaries)** from the PDF, and integrating them into the app.

## User Review Required

> [!WARNING]  
> The current `Shloka` model in your app (`lib/models/grantha.dart`) does not support storing Vyakhyanas (commentaries). It only supports `kannadaMeaning` and `englishMeaning`.
> 
> Furthermore, the Vyakhyana in the provided PDF is the "Peetambara Hindi Vyakhyana" (written in Hindi). 
> 
> **Proposed Approach**: 
> 1. I will modify the data models in `lib/models/grantha.dart` to add a new `hindiVyakhyana` field (and optionally a `kannadaVyakhyana` field).
> 2. I will write a custom Python script to scan the PDF to detect the exact starting pages of Chapter 1.
> 3. I will extract the first 5 shlokas along with their full Hindi Vyakhyana.
> 4. I will translate/transliterate the extracted data into the `Shloka` objects and append them to `lib/data/grantha_data.dart`.
>
> Please confirm if modifying the data models is acceptable, and whether you want the Hindi Vyakhyana translated to Kannada or kept in Hindi.

## Proposed Changes

### `lib/models/grantha.dart`

- [MODIFY] `lib/models/grantha.dart`
  - Add `final String? hindiVyakhyana;` and `final String? kannadaVyakhyana;` to the `Shloka` class.
  - Update the constructor to include these new optional fields.

### `lib/data/grantha_data.dart`

- [MODIFY] `lib/data/grantha_data.dart`
  - Replace the placeholder Mangalacharana with the strictly analyzed first 5 Shlokas and their Vyakhyanas from the PDF.

## Open Questions

1. Is modifying the `Shloka` model to include `hindiVyakhyana` and `kannadaVyakhyana` acceptable to you?
2. Do you want me to translate the Hindi Vyakhyanas to Kannada, or should I just store the raw Hindi Vyakhyana?
3. This process will be done in batches of 5. Would you like me to create an automated script that you can run yourself later for the subsequent batches?

## Verification Plan

### Manual Verification
- Review changes to `grantha.dart` to ensure it compiles.
- Check `grantha_data.dart` for the first 5 shlokas to ensure the formatting matches our new schema.
