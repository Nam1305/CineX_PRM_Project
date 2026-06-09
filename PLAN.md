# CineX — Source Structure & Setup Plan

---

## 1. Architecture Decision

**Pattern: Feature-First + Repository Pattern + Provider**

```
UI (Screens/Widgets)
       ↕
  Provider (State)
       ↕
  Repository (Business Logic + Data Access)
       ↕
  DatabaseHelper (SQLite via sqflite)
```

- Each feature is self-contained (own model, repository, provider, screens)
- `DatabaseHelper` is a singleton shared across all repositories
- `Provider` is registered at the top of the widget tree in `main.dart`

---

## 2. Full Folder Structure

```
lib/
├── main.dart                          # Entry point, MultiProvider setup
├── app.dart                           # MaterialApp, ThemeData, named routes
│
├── core/
│   ├── database/
│   │   ├── database_helper.dart       # Singleton SQLite: onCreate, tables, FK
│   │   └── db_constants.dart          # Table names & column name constants
│   ├── theme/
│   │   └── app_theme.dart             # ThemeData (colors, fonts, MD3)
│   └── utils/
│       ├── enums.dart                 # RoleType, Setting, TimeOfDay, SceneStatus
│       └── validators.dart            # Reusable form validators
│
├── shared/
│   └── widgets/
│       ├── empty_state_widget.dart    # Icon + hint text when list is empty
│       ├── confirm_dialog.dart        # AlertDialog for delete confirmations
│       └── app_snackbar.dart          # Helper to show success/error SnackBar
│
└── features/
    │
    ├── projects/                      # Module 1 (F1.1)
    │   ├── data/
    │   │   ├── models/
    │   │   │   └── project.dart
    │   │   └── repositories/
    │   │       └── project_repository.dart
    │   ├── providers/
    │   │   └── project_provider.dart
    │   └── presentation/
    │       ├── screens/
    │       │   ├── project_launcher_screen.dart   # GridView of projects
    │       │   └── project_form_screen.dart       # Add / Edit form
    │       └── widgets/
    │           └── project_card.dart
    │
    ├── acts/                          # Module 1 (F1.2)
    │   ├── data/
    │   │   ├── models/
    │   │   │   └── act.dart
    │   │   └── repositories/
    │   │       └── act_repository.dart
    │   ├── providers/
    │   │   └── act_provider.dart
    │   └── presentation/
    │       └── widgets/
    │           └── act_expansion_tile.dart        # ExpansionTile in StoryBoard
    │
    ├── characters/                    # Module 2 (F2.1)
    │   ├── data/
    │   │   ├── models/
    │   │   │   └── character.dart
    │   │   └── repositories/
    │   │       └── character_repository.dart
    │   ├── providers/
    │   │   └── character_provider.dart
    │   └── presentation/
    │       ├── screens/
    │       │   ├── characters_tab.dart            # SliverGrid tab
    │       │   └── character_form_screen.dart
    │       └── widgets/
    │           └── character_card.dart            # Image + name + role Chip
    │
    ├── locations/                     # Module 2 (F2.2)
    │   ├── data/
    │   │   ├── models/
    │   │   │   └── location.dart
    │   │   └── repositories/
    │   │       └── location_repository.dart
    │   ├── providers/
    │   │   └── location_provider.dart
    │   └── presentation/
    │       ├── screens/
    │       │   ├── locations_tab.dart             # ListTile with day/night icon
    │       │   └── location_form_screen.dart
    │       └── widgets/
    │           └── location_tile.dart
    │
    ├── scenes/                        # Module 3 (F3.1 – F3.3)
    │   ├── data/
    │   │   ├── models/
    │   │   │   └── scene.dart                     # includes List<Character>
    │   │   └── repositories/
    │   │       └── scene_repository.dart          # also manages scene_characters
    │   ├── providers/
    │   │   └── scene_provider.dart
    │   └── presentation/
    │       ├── screens/
    │       │   ├── storyboard_tab.dart            # Tab 1 of Workspace
    │       │   └── scene_form_screen.dart         # Dropdown + multi-select
    │       └── widgets/
    │           └── scene_card.dart                # Scene number + location + avatars
    │
    ├── workspace/                     # Shell for Workspace screen
    │   └── presentation/
    │       └── screens/
    │           └── workspace_screen.dart          # BottomNavigationBar (4 tabs)
    │
    └── production/                    # Module 4 + Module 5
        ├── providers/
        │   └── production_provider.dart           # Group-by logic + filter logic
        └── presentation/
            ├── screens/
            │   └── production_tab.dart            # Tab 4: charts + grouped scenes
            └── widgets/
                ├── shooting_day_group.dart        # F4.1: grouped location cards
                ├── scene_filter_bar.dart          # F4.2: advanced filter UI
                ├── character_frequency_chart.dart # F5.1: fl_chart bar chart
                └── int_ext_pie_chart.dart         # F5.1: fl_chart pie chart
```

---

## 3. Libraries

### `pubspec.yaml` — full dependencies block

```yaml
dependencies:
  flutter:
    sdk: flutter

  # --- Database ---
  sqflite: ^2.4.1          # SQLite engine for Flutter
  path: ^1.9.1             # Construct file paths (for DB location)
  path_provider: ^2.1.5    # Get device storage directories

  # --- State Management ---
  provider: ^6.1.2         # ChangeNotifier-based state management

  # --- Image ---
  image_picker: ^1.1.2     # Pick character photos from device/gallery

  # --- Charts ---
  fl_chart: ^0.70.2        # Bar chart (character frequency) + Pie chart (INT/EXT)

  # --- PDF Export ---
  pdf: ^3.11.1             # Build PDF document programmatically
  printing: ^5.13.2        # Preview/share/save the PDF on device

  # --- Utilities ---
  intl: ^0.20.2            # Date formatting, Vietnamese locale
  uuid: ^4.5.1             # Generate unique IDs if needed

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true

  # Vietnamese font for PDF rendering (bundle in assets)
  fonts:
    - family: NotoSans
      fonts:
        - asset: assets/fonts/NotoSans-Regular.ttf
        - asset: assets/fonts/NotoSans-Bold.ttf

  assets:
    - assets/fonts/
    - assets/images/            # placeholder/empty-state illustrations
```

> **Important:** Download `NotoSans-Regular.ttf` and `NotoSans-Bold.ttf` from Google Fonts
> and place them in `assets/fonts/`. This is required for correct Vietnamese text in PDF export (F5.2).

---

## 4. Database Setup (`core/database/database_helper.dart`)

Key points to implement:
- `PRAGMA foreign_keys = ON;` — must be enabled on every connection
- All 6 tables created in `_onCreate`
- `ON DELETE CASCADE` on `acts`, `scenes`, `scene_characters`

```
Tables creation order (respect FK deps):
1. projects
2. acts           (FK → projects)
3. characters     (FK → projects)
4. locations      (FK → projects)
5. scenes         (FK → acts, locations)
6. scene_characters (FK → scenes, characters)
```

---

## 5. Provider Registration (`main.dart`)

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => ProjectProvider()),
    ChangeNotifierProxyProvider<ProjectProvider, ActProvider>(...),
    ChangeNotifierProxyProvider<ProjectProvider, CharacterProvider>(...),
    ChangeNotifierProxyProvider<ProjectProvider, LocationProvider>(...),
    ChangeNotifierProxyProvider<ActProvider, SceneProvider>(...),
    ChangeNotifierProxyProvider2<SceneProvider, LocationProvider, ProductionProvider>(...),
  ],
  child: const App(),
)
```

Use `ChangeNotifierProxyProvider` for providers that depend on another provider's selected project/act ID.

---

## 6. Navigation (Named Routes)

| Route | Screen | Trigger |
|---|---|---|
| `/` | `ProjectLauncherScreen` | App start |
| `/workspace` | `WorkspaceScreen` | Tap a project card |
| `/project/add` | `ProjectFormScreen` | FAB on launcher |
| `/project/edit` | `ProjectFormScreen` | Edit button on card |
| `/character/form` | `CharacterFormScreen` | FAB on Characters tab |
| `/location/form` | `LocationFormScreen` | FAB on Locations tab |
| `/scene/form` | `SceneFormScreen` | FAB on StoryBoard tab |

---

## 7. Enum Definitions (`core/utils/enums.dart`)

```dart
enum RoleType { main, support, crowd }
enum LocationSetting { interior, exterior }      // INT / EXT
enum TimeOfDay { day, night }
enum SceneStatus { todo, inProgress, done }
```

---

## 8. Implementation Order (Recommended for team of 5)

| Sprint | Member | Task |
|---|---|---|
| Week 1 | Member 1 | Setup DB, `database_helper.dart`, all 6 table schemas, enums |
| Week 1 | Member 2 | `ProjectProvider` + `ProjectLauncherScreen` + `WorkspaceScreen` shell |
| Week 2 | Member 3 | `CharacterProvider` + Characters tab + `CharacterFormScreen` |
| Week 2 | Member 4 | `LocationProvider` + Locations tab + `LocationFormScreen` |
| Week 3 | Member 5 | `SceneProvider` + StoryBoard tab + `SceneFormScreen` (multi-select) |
| Week 4 | Member 1+2 | `ProductionProvider` + Production tab (group-by + filter) |
| Week 5 | Member 3+4 | fl_chart integration (bar + pie charts) |
| Week 5 | Member 5 | PDF export with NotoSans font (Vietnamese) |
| Week 6 | All | Polish: empty states, SnackBar, AlertDialog, responsive layout |

---

## 9. Assets Folder Structure

```
assets/
├── fonts/
│   ├── NotoSans-Regular.ttf
│   └── NotoSans-Bold.ttf
└── images/
    ├── empty_projects.png        # Empty state for project launcher
    ├── empty_characters.png      # Empty state for characters tab
    ├── empty_locations.png       # Empty state for locations tab
    └── empty_scenes.png          # Empty state for storyboard tab
```
