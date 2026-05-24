# Paste-to-Dashboard Tool

Instead of file upload and parsing, the user will **copy columns directly from Excel** and **paste them into labeled input fields**. This is the most foolproof approach — no parsing ambiguity, no column name guessing.

## How It Works

1. **Input Page**: A clean form with labeled `<textarea>` fields:
   - **Campaign Name** (required) — user copies the Campaign Name column from Excel, pastes here
   - **Date** (required) — user copies the Date column, pastes here
   - **Revenue** (optional)
   - **Cost** (optional)
   - **Clicks** (optional)
   - **Installs / Downloads** (optional)
   - **Purchases / Events** (optional)

2. Each textarea accepts **one value per line** (which is exactly how Excel copies column data to clipboard).

3. User clicks **"Generate Dashboard"** → the website zips the columns together row-by-row and builds the full dashboard with:
   - Overview (KPI cards + global charts)
   - Campaign Pivot Table
   - Campaign Detail drill-down
   - Campaign Comparison view

## Proposed Changes

### [NEW] `d:\excel tools\tool2_dec2025\index.html`
- Input page with labeled textareas
- Dashboard section (same 4-view layout as before)

### [NEW] `d:\excel tools\tool2_dec2025\css\styles.css`
- Premium dark theme (reused from first tool)
- New styles for the paste input form

### [NEW] `d:\excel tools\tool2_dec2025\js\app.js`
- Parse pasted text by splitting on newlines
- Zip columns together into row objects
- Group by Campaign Name, compute summaries
- Render all 4 dashboard views

## Verification Plan
- Paste sample data from the Dec 2025 Excel file
- Verify KPI totals match expected values
- Test with missing optional columns (e.g. no Margin pasted)
