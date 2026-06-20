# Technical Proposal - App Size and Memory Footprint Reduction

Currently, the app bundles **137 MB** of raw JSON text assets under `assets/data/`:
- `stotra_data.json` (~58.1 MB)
- `scriptures_data.json` (~52.9 MB)
- `rigveda_data.json` (~17.3 MB)
- `yajurveda_data.json` (~5.0 MB)
- `atharvaveda_data.json` (~2.1 MB)
- `shukla_yajurveda_data.json` (~1.0 MB)
- `samaveda_data.json` (~0.6 MB)

While Flutter compresses assets in the release APK (reducing the download size addition to ~25-35MB), loading and parsing these files at runtime causes **severe UI freezing (5-10 seconds)** and **high memory consumption (300-500MB of RAM)** because the entire file is decoded into memory at once.

Below are the 4 best strategies to resolve these size and performance issues, along with their pros and cons.

---

## Strategy 1: GZIP Asset Compression
Compress all JSON files into `.json.gz` files and decompress them dynamically in Dart when the app starts.

### How it works
1. Use a script to compress `scriptures_data.json` to `scriptures_data.json.gz`.
2. In Dart, read the raw bytes using `rootBundle.load('assets/data/scriptures_data.json.gz')`.
3. Decompress the bytes using the built-in `gzip.decode()` from `dart:io` and decode the UTF-8 string.

### Evaluation
* **App Size Reduction**: **High** (reduces assets from 137MB to ~18-20MB).
* **RAM Usage Reduction**: **None** (still decodes the entire JSON string in memory once read).
* **Implementation Effort**: **Very Low** (only requires updating the file loading logic in services).
* **Offline Capability**: **100% Offline**.

---

## Strategy 2: Splitting JSON Files (On-Demand Local Loading)
Split the large JSON files into a lightweight metadata/index file and separate sub-files for individual chapters/books.

### How it works
1. Generate an index file (e.g., `stotras_index.json` containing only category and stotra names/IDs, size < 1MB).
2. Save each individual stotra or scripture chapter as a separate small file (e.g., `assets/data/stotras/stotra_123.json`).
3. The app loads the index file on startup. When a user taps a stotra/chapter, the app loads only that specific small JSON file.

### Evaluation
* **App Size Reduction**: **Medium** (reduces final APK size slightly due to minor overhead of multiple files, but still keeps all data in assets).
* **RAM Usage Reduction**: **Extremely High** (RAM drops from 300MB+ to <2MB; loading is instant with no UI freezing).
* **Implementation Effort**: **Medium** (requires writing a script to split the data, and updating list/detail views).
* **Offline Capability**: **100% Offline**.

---

## Strategy 3: Local SQLite/Isar Database
Convert the raw JSON data into a structured binary SQLite or Isar database file and bundle it as an asset.

### How it works
1. Create a script to populate a SQLite database file (e.g., `scriptures.db`) from the JSON files.
2. Store `scriptures.db` in the assets folder.
3. On first startup, copy the database file to the app's local document directory and query it directly using `sqflite` or `isar`.

### Evaluation
* **App Size Reduction**: **High** (binary database format is much more compact than raw JSON, usually ~30-40MB total).
* **RAM Usage Reduction**: **Extremely High** (queries only the exact verse/stotra needed; minimal RAM overhead).
* **Implementation Effort**: **High** (requires rewriting data services and models to use database queries instead of JSON parsing).
* **Offline Capability**: **100% Offline**.

---

## Strategy 4: On-Demand Cloud Downloads (Firebase / Supabase CDN)
Remove the large data assets from the app bundle entirely and host them on a CDN or cloud database.

### How it works
1. Host the JSON files or document data in a Cloud Storage bucket (e.g., Firebase Storage) or a database (Supabase/Firestore).
2. When the user opens a scripture/stotra, fetch it over the network and save it locally in a cache (like Hive or SQLite) so it remains available offline afterward.

### Evaluation
* **App Size Reduction**: **Extremely High** (reduces initial APK size to **under 10MB**).
* **RAM Usage Reduction**: **Extremely High** (only loads active reading content).
* **Implementation Effort**: **High** (requires cloud setup, local caching logic, and handling network connectivity states).
* **Offline Capability**: **Requires Internet for First Load** (but fully offline after download).

---

## Recommendation

For the best user experience (keeping the app **100% offline** while fixing the startup delays and reducing size):
- **Immediate Fix (Easy)**: **Strategy 1 (GZIP)** will quickly reduce the size of the assets in development and the repository.
- **Robust Long-term Solution (Best)**: **Strategy 2 (Splitting Files)** or **Strategy 3 (SQLite Database)**. Splitting files is particularly easy to do in Flutter and solves the RAM/freezing issue completely without introducing heavy database dependencies.
