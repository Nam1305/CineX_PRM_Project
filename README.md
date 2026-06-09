# CineX

A Flutter app for independent film teams to manage screenplay structure, character profiles, locations, and production scheduling — all stored locally on device with SQLite.

---

## Features

| Module | What it does |
|---|---|
| **Projects** | Create, edit, delete film projects (title, genre, description, date) |
| **Acts** | Divide a project into narrative acts (e.g. Act 1 – Setup, Act 2 – Confrontation) |
| **Characters** | Manage cast with role type (Main / Support / Crowd), description, and photo |
| **Locations** | Track shooting locations with INT/EXT setting and DAY/NIGHT time of day |
| **Storyboard** | Create scene cards per act — link a location + multiple characters, write a summary, set status (TODO / IN_PROGRESS / DONE) |
| **Production** | Auto-group scenes by location into shooting days; advanced filters (by character and time of day) |
| **Analytics** | Bar chart (character appearance frequency) and pie chart (INT vs EXT ratio) powered by `fl_chart` |
| **PDF Export** | Export the full project — character roster + scene timeline — as a PDF file |

---

## Business Flow

```
[1] Create a Project
        │
        ▼
[2] Build Resources
    ├── Add Characters  (name, role, photo)
    └── Add Locations   (INT/EXT, DAY/NIGHT, notes)
        │
        ▼
[3] Structure the Story
    ├── Create Acts     (sequence order, title)
    └── Create Scene Cards per Act
            ├── Pick a Location   (dropdown)
            ├── Pick Characters   (multi-select filter chips)
            ├── Write a summary
            └── Set status: TODO → IN_PROGRESS → DONE
        │
        ▼
[4] Plan Production
    ├── Scenes are auto-grouped by location → proposed Shooting Days
    ├── Filter by character AND/OR time of day
    └── View analytics: appearance frequency, INT/EXT ratio
        │
        ▼
[5] Export
    └── Generate PDF with full project data
```

---

## Project Structure

```
lib/
├── main.dart                        # Entry point — MultiProvider setup
├── app.dart                         # MaterialApp, dark/light theme, home route
│
├── core/
│   ├── database/
│   │   ├── database_helper.dart     # Singleton SQLite — onCreate, FK pragma
│   │   └── db_constants.dart        # Table names and column constants
│   ├── theme/
│   │   └── app_theme.dart           # Material 3, cinematic amber seed color
│   └── utils/
│       ├── enums.dart               # RoleType, LocationSetting, SceneTime, SceneStatus
│       └── validators.dart          # Reusable form validators
│
├── shared/
│   └── widgets/
│       ├── empty_state_widget.dart  # Icon + hint when list is empty
│       ├── confirm_dialog.dart      # AlertDialog for delete confirmations
│       └── app_snackbar.dart        # Success/error SnackBar helper
│
└── features/
    ├── projects/                    # F1.1 — CRUD projects
    │   ├── data/models/project.dart
    │   ├── data/repositories/project_repository.dart
    │   ├── providers/project_provider.dart
    │   └── presentation/
    │       ├── screens/project_launcher_screen.dart   # GridView of project cards
    │       ├── screens/project_form_screen.dart
    │       └── widgets/project_card.dart
    │
    ├── acts/                        # F1.2 — Acts within a project
    │   ├── data/models/act.dart
    │   ├── data/repositories/act_repository.dart
    │   ├── providers/act_provider.dart
    │   └── presentation/widgets/act_expansion_tile.dart
    │
    ├── characters/                  # F2.1 — Character profiles
    │   ├── data/models/character.dart
    │   ├── data/repositories/character_repository.dart
    │   ├── providers/character_provider.dart
    │   └── presentation/
    │       ├── screens/characters_tab.dart            # SliverGrid
    │       ├── screens/character_form_screen.dart
    │       └── widgets/character_card.dart
    │
    ├── locations/                   # F2.2 — Shooting locations
    │   ├── data/models/location.dart
    │   ├── data/repositories/location_repository.dart
    │   ├── providers/location_provider.dart
    │   └── presentation/
    │       ├── screens/locations_tab.dart
    │       ├── screens/location_form_screen.dart
    │       └── widgets/location_tile.dart
    │
    ├── scenes/                      # F3.1–F3.3 — Scene cards
    │   ├── data/models/scene.dart
    │   ├── data/repositories/scene_repository.dart    # manages scene_characters join
    │   ├── providers/scene_provider.dart
    │   └── presentation/
    │       ├── screens/storyboard_tab.dart            # Acts → ExpansionTile → Scene cards
    │       ├── screens/scene_form_screen.dart         # Dropdown + FilterChips
    │       └── widgets/scene_card.dart
    │
    ├── workspace/                   # Shell with BottomNavigationBar (4 tabs)
    │   └── presentation/screens/workspace_screen.dart
    │
    └── production/                  # F4.1, F4.2, F5.1, F5.2
        ├── providers/production_provider.dart         # group-by + filter logic
        └── presentation/
            ├── screens/production_tab.dart
            └── widgets/
                ├── shooting_day_group.dart            # F4.1 grouped cards
                ├── scene_filter_bar.dart              # F4.2 filter UI
                ├── character_frequency_chart.dart     # F5.1 bar chart
                └── int_ext_pie_chart.dart             # F5.1 pie chart
```

### Architecture

```
Screens / Widgets
      ↕  (context.watch / context.read)
  Provider (ChangeNotifier)
      ↕  (async calls)
  Repository
      ↕  (SQL queries)
  DatabaseHelper (singleton SQLite)
```

- **Feature-first layout** — each feature owns its model, repository, provider, and presentation code.
- **`DatabaseHelper`** is a singleton with `PRAGMA foreign_keys = ON` enforced on every connection.
- All providers are registered at the root via `MultiProvider` in `main.dart`.

### Database Schema

```
projects ──< acts ──< scenes >──── scene_characters ────< characters
   │                    │
   └──< characters      └── location_id ──> locations
   └──< locations
```

| Table | Key columns |
|---|---|
| `projects` | id, title, genre, description, created_at |
| `acts` | id, project_id FK, title, sequence_order |
| `characters` | id, project_id FK, name, role_type, description, image_path |
| `locations` | id, project_id FK, name, setting (INT/EXT), time_of_day (DAY/NIGHT), notes |
| `scenes` | id, act_id FK, location_id FK, scene_number, summary, status |
| `scene_characters` | scene_id FK, character_id FK (composite PK) |

`ON DELETE CASCADE` propagates from `projects` down to `acts → scenes → scene_characters`.

---

## Setup Guide

### Prerequisites

| Tool | Version |
|---|---|
| Flutter SDK | ≥ 3.12 |
| Dart SDK | ≥ 3.12 (bundled with Flutter) |
| Android SDK / Xcode | For Android / iOS targets |

### 1. Clone and install dependencies

```bash
git clone <repo-url>
cd cinex_application
flutter pub get
```

### 2. (Optional) Enable Vietnamese PDF font

Download **NotoSans-Regular.ttf** and **NotoSans-Bold.ttf** from [Google Fonts](https://fonts.google.com/specimen/Noto+Sans) and place them in:

```
assets/fonts/NotoSans-Regular.ttf
assets/fonts/NotoSans-Bold.ttf
```

Then uncomment the font block in `pubspec.yaml`:

```yaml
fonts:
  - family: NotoSans
    fonts:
      - asset: assets/fonts/NotoSans-Regular.ttf
      - asset: assets/fonts/NotoSans-Bold.ttf
```

### 3. Run the app

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Linux desktop
flutter run -d linux

# Web
flutter run -d chrome
```

### 4. Build a release APK

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Supported Platforms

- Android (primary target)
- iOS
- Linux desktop
- Web (limited — `sqflite` uses an in-memory SQLite shim on web)

---

## Key Dependencies

| Package | Purpose |
|---|---|
| `sqflite` | SQLite engine |
| `path` / `path_provider` | Resolve database file path on device |
| `provider` | ChangeNotifier state management |
| `image_picker` | Pick character photos from device gallery |
| `fl_chart` | Bar chart + pie chart in Production tab |
| `pdf` / `printing` | Build and share/print PDF reports |
| `intl` | Date formatting |
| `uuid` | UUID generation if needed |
