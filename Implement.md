# Build Flutter UI Module: CineX – Project & Location Management

You are a senior Flutter developer.

Build a complete, production-ready Flutter UI module for a film production management application called **CineX**.

Focus on:

* Clean architecture
* Reusable widgets
* Responsive layouts
* Dark cinematic design
* Mock data only (no backend integration)
* Navigation flow between list → detail → create screens

---

# Design System

Create a centralized ThemeData.

## Colors

```dart
backgroundColor = Color(0xFF131313);
surfaceColor = Color(0xFF1C1B1B);
primaryColor = Color(0xFFFF4D00);
textPrimary = Color(0xFFFFFFFF);
textMuted = Color(0xFF9E9E9E);
dividerColor = Color(0xFF393939);
```

## Typography

Use Google Fonts:

```dart
GoogleFonts.hankenGrotesk()
```

## Component Styling

* Border radius: 12px
* Elevated cards
* High contrast dark UI
* Large touch targets
* Consistent spacing system (8 / 12 / 16 / 24)

---

# Project Structure

Organize code using Feature First architecture.

```text
lib/
 ├── core/
 │    ├── theme/
 │    ├── widgets/
 │    └── constants/
 │
 ├── features/
 │    ├── projects/
 │    │     ├── models/
 │    │     ├── screens/
 │    │     ├── widgets/
 │    │     └── providers/
 │    │
 │    └── locations/
 │          ├── models/
 │          ├── screens/
 │          ├── widgets/
 │          └── providers/
 │
 └── main.dart
```

Use Riverpod (preferred) for state management.

---

# Navigation Requirements

Implement navigation:

```text
Project List
 ├── Add Project
 └── Project Detail

Location List
 ├── Add Location
 └── Location Detail
```

Main list screens must use a shared BottomNavigationBar.

Tabs:

1. Projects
2. Locations
3. Profile (placeholder)

Use GoRouter or Navigator 2.0.

---

# Shared Components

Create reusable widgets:

## AppHeader

Reusable custom header with:

* Page title
* Search button
* Notification button

## PrimaryButton

Reusable orange CTA button.

## SectionCard

Reusable dark card component.

## StatusBadge

Support statuses:

* Active
* Completed
* Pending
* Approved

## ProgressWidget

Support:

* Linear progress
* Percentage display

## ImageCard

Support:

* Hero animation
* CachedNetworkImage
* Placeholder state

---

# FEATURE 1 — PROJECT MANAGEMENT

## Screen 1 — Project List

Purpose:
Display all film projects.

Layout:

### Header

Title:

"Dự án của tôi"

Actions:

* Search
* Notifications

### Featured Project Card

Contains:

* Large poster image
* Hero animation
* Badge: "ĐANG QUAY"
* Progress bar
* Start date
* Crew count

### Statistics Row

Horizontal cards:

* Đang thực hiện
* Đã hoàn tất

### Project List

Scrollable vertical list.

Each card contains:

* Thumbnail
* Project name
* Progress percentage
* Current status

### FAB

Floating Action Button

Color:

Action Orange

Action:

Navigate to Add Project Screen.

---

## Screen 2 — Add Project

Create a project creation form.

Fields:

### Poster Upload

2:3 aspect ratio placeholder.

Support image picker UI only.

### Inputs

* Project Name
* Director
* Genre (dropdown)
* Start Date (date picker)
* End Date (date picker)

### Logline

Multiline text area.

### Submit

Full width CTA:

"Tạo dự án"

Display validation states.

---

## Screen 3 — Project Detail

### Hero Section

Large poster image.

Overlay:

* Dark gradient
* Project title
* Current status

### Metadata Grid

2 x 2 grid:

* Start Date
* End Date
* Crew Count
* Progress

### Action Buttons

Grid of actions:

* Lịch Quay
* Phân Tích Chi Tiết
* Xuất Báo Cáo

### Budget Summary Card

Display:

* Total Budget
* Spent
* Remaining

Include simple progress visualization.

### Act Progress

Display:

* Act I
* Act II
* Act III
* Act IV

Statuses:

* Done
* In Progress
* Waiting

---

# FEATURE 2 — LOCATION MANAGEMENT

## Screen 4 — Location List

Purpose:
Manage filming locations.

### Search

Large search field.

### Filter Chips

Options:

* Tất cả
* Nội cảnh (INT)
* Ngoại cảnh (EXT)

### Location Cards

Top section:

* Large image
* Hero animation

Overlay tags:

* INT / EXT
* DAY / NIGHT

Bottom section:

* Location name
* Address
* Coordinates
* Scene numbers

Status badge:

* CHỜ DUYỆT
* ĐÃ XÁC NHẬN

---

## Screen 5 — Add Location

Form screen.

### Moodboard Upload

Large preview area.

### Environment Toggle

Segmented Control:

* INT
* EXT

### Inputs

* Location Name
* Scene Numbers
* Time Of Day

Dropdown:

* DAY
* NIGHT

### Technical Notes

Multiline textarea.

Examples:

* Lighting requirements
* Audio constraints
* Logistics notes

### Submit Button

Label:

"Xác nhận bối cảnh"

Icon:

Checkmark

---

## Screen 6 — Location Detail

### Gallery

Horizontal image carousel.

### Quick Tags

Display badges:

* INT
* EXT
* DAY
* NIGHT
* QUAN TRỌNG

### Technical Information

Cards:

* Lighting
* Audio
* Power
* Space

### Associated Scenes

List scene cards.

Each card contains:

* Scene number
* Title
* Estimated duration
* Page count
* Status

### Management Information

Display:

* Contact person
* Phone number
* Rental cost
* Availability

---

# Responsive Requirements

Must support:

* Mobile phones
* Tablets
* Landscape mode

Use:

* LayoutBuilder
* MediaQuery

Avoid fixed widths.

---

# Animation Requirements

Implement:

* Hero transitions
* Fade transitions
* Smooth page navigation
* Animated progress updates

Keep animations subtle and professional.

---

# Assets

Use CachedNetworkImage.

Generate mock URLs for posters and location images.

Include loading and error states.

---

# Deliverables

Generate:

1. Complete folder structure.
2. Models for Project and Location.
3. Riverpod providers.
4. ThemeData configuration.
5. Reusable widgets.
6. All six screens.
7. Navigation setup.
8. Mock data.
9. Example main.dart.

Code should compile without modification.
Use modern Flutter best practices and maintainable architecture.
