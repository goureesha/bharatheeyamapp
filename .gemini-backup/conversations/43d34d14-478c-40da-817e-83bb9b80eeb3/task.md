# Universal Mapper Dashboard Tasks

- `[x]` **Mapping Wizard UI (`index.html`)**
  - `[x]` Add Sheet Selection UI.
  - `[x]` Add Column Mapping UI (Dropdowns for Campaign, Date, Revenue, Cost, Installs, Clicks).
  - `[x]` Add "Generate Dashboard" button.
- `[x]` **Mapping Logic (`js/app.js`)**
  - `[x]` Handle file parsing to extract sheet names and column headers.
  - `[x]` Populate sheet dropdown and listen for changes to update column dropdowns.
  - `[x]` Auto-select likely columns based on simple keywords as a default.
  - `[x]` Parse data using the exact indices selected by the user.
- `[x]` **Styling (`css/styles.css`)**
  - `[x]` Add styles for mapping form, selects, and wizard step container.
- `[x]` **Verification**
  - `[x]` Test with `Dec2025_Final_Dashboard.xlsx` to ensure manual mapping accurately builds the dashboard.
