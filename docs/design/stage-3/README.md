# Stage 3 design boards

Copies of the boards behind the stage 3 tickets, taken from the Design artifact `Anky Screens` (https://claude.ai/artifact/DYgcuUbXYc8Dssossrp1gJ, version `1794044584-f1a2`, exported 2026-11-07). Bodyshop workers cannot open Claude artifacts, so the boards live here. Each board is a `.dc.html` file with a 390 x 844 PNG next to it.

## Tickets

| Folder | Ticket | Screen |
| --- | --- | --- |
| `today/` | t-182 | Today |
| `history/` | t-185 | History |
| `log-and-edit-dose/` | t-183 | Log Dose and Edit Dose |
| `medications/` | t-184 | Medications |
| `where-picker/` | t-186 | Where picker |

`tokens.json` is `ds/anky/tokens.json` from the artifact, the Anky design system the canvas lists.

## Boards

The title and page are the board's name on the canvas. Boards from before stage 3 are on the earlier pages. A board that is a thin wrapper shows another file with some props set, listed under Renders.

### `today/` (t-182)

| Board | Canvas title | Canvas page | Renders | PNG |
| --- | --- | --- | --- | --- |
| `TodayNow.dc.html` | Today, now | Polish: stage 3 | itself | [TodayNow.png](today/TodayNow.png) |
| `TodayTiles.dc.html` | Today, with icon tiles | Polish: stage 3 | itself | [TodayTiles.png](today/TodayTiles.png) |

### `history/` (t-185)

| Board | Canvas title | Canvas page | Renders | PNG |
| --- | --- | --- | --- | --- |
| `HistoryNow.dc.html` | History, now | Polish: stage 3 | History.dc.html | [HistoryNow.png](history/HistoryNow.png) |
| `HistoryTiles.dc.html` | History, with icon tiles | Polish: stage 3 | itself | [HistoryTiles.png](history/HistoryTiles.png) |
| `History.dc.html` | not a board | | imported by `HistoryNow` | none |

### `log-and-edit-dose/` (t-183)

| Board | Canvas title | Canvas page | Renders | PNG |
| --- | --- | --- | --- | --- |
| `LogDose.dc.html` | 7 Log dose | Features 6-8 | itself | [LogDose.png](log-and-edit-dose/LogDose.png) |
| `EditDose.dc.html` | 7 Edit dose | Features 6-8 | LogDose.dc.html with mode=edit | [EditDose.png](log-and-edit-dose/EditDose.png) |
| `LogDosePick.dc.html` | 7 Log dose, choose a reading | Features 6-8 | itself | [LogDosePick.png](log-and-edit-dose/LogDosePick.png) |

### `medications/` (t-184)

| Board | Canvas title | Canvas page | Renders | PNG |
| --- | --- | --- | --- | --- |
| `Meds.dc.html` | 6 Medications | Features 6-8 | itself | [Meds.png](medications/Meds.png) |
| `MedsArchived.dc.html` | 6 Archived medications | Features 6-8 | Meds.dc.html with view=archived, swipe=first | [MedsArchived.png](medications/MedsArchived.png) |
| `MedForm.dc.html` | 6 New medication | Features 6-8 | itself | [MedForm.png](medications/MedForm.png) |
| `MedEdit.dc.html` | 6 Edit medication | Features 6-8 | MedForm.dc.html with mode=edit | [MedEdit.png](medications/MedEdit.png) |
| `MedEditNow.dc.html` | Edit medication, now | Polish: stage 3 | MedForm.dc.html with mode=edit | [MedEditNow.png](medications/MedEditNow.png) |
| `MedEditMenu.dc.html` | Edit medication, Archive in menu | Polish: stage 3 | MedFormMenu.dc.html | [MedEditMenu.png](medications/MedEditMenu.png) |
| `MedEditMenuOpen.dc.html` | Edit medication, menu open | Polish: stage 3 | MedFormMenu.dc.html with menu=open | [MedEditMenuOpen.png](medications/MedEditMenuOpen.png) |
| `MedFormMenu.dc.html` | not a board | | imported by `MedEditMenu`, `MedEditMenuOpen` | none |

### `where-picker/` (t-186)

| Board | Canvas title | Canvas page | Renders | PNG |
| --- | --- | --- | --- | --- |
| `BodyPicker.dc.html` | 2 Places: all joints | Features 1-5 | itself | [BodyPicker.png](where-picker/BodyPicker.png) |
| `PlacesSwipe.dc.html` | 2 Places: swipe to pin | Features 1-5 | BodyPicker.dc.html with swipe=upper | [PlacesSwipe.png](where-picker/PlacesSwipe.png) |
| `PlacesTip.dc.html` | 2 Places: tip | Features 1-5 | BodyPicker.dc.html with tip=true | [PlacesTip.png](where-picker/PlacesTip.png) |

## Notes from the Polish: stage 3 page

Under `TodayTiles` on the canvas:

> Idea · Each row gets a neutral 32 pt tile with an icon for its kind. The first line names the kind (Pain, Stiffness, Fatigue) or the medication. The second line starts with the time, then the place: 08:42 · Lower back. Icons here are placeholders for SF Symbols to be chosen together. The kind is always written in words, so the icon never carries the meaning alone.

Under `HistoryTiles` on the canvas:

> Same treatment as Today: icon tile, kind or medication on the first line, then time and place. The day headers already carry the date, so the time stays short.

Under `MedEditMenu` on the canvas:

> Archive moves from a loose text link at the bottom of the form into the ••• menu, the same place Delete lives on Edit Entry and Edit Dose. It is a normal-coloured item with no confirmation, because archiving can be undone from the Archived list. Delete stays red and keeps its confirmation.

## Reading the files

The `.dc.html` files are the source of the numbers: sizes, spacing, radii, colours and type are in their inline styles and in the token maps in their script. The SVG icons in them are placeholders. SF Symbols are still to be chosen and approved by the stakeholder, so do not copy the paths.

The files do not open on their own from the repo. They load `./support.js`, which is the artifact's design runtime and is not kept here. Their links to other boards point at files outside the folder, and a wrapper fetches the file it imports from its own folder. That is why each folder holds the files its wrappers import, and why the PNGs are the quick way to see a screen.

## How the PNGs were made

Each board was rendered once, light theme and default props, to 390 x 844 at scale 1. The rendering used a scratch copy of the artifact files served over local HTTP, with the artifact's `artifact-type/dc-runtime.js` saved as `support.js` next to them. The scripts and the runtime are not in the repo.

```sh
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu --hide-scrollbars \
  --user-data-dir=<empty dir> --window-size=390,844 --force-device-scale-factor=1 --virtual-time-budget=8000 \
  --screenshot=<Board>.png http://127.0.0.1:<port>/<Board>.dc.html
```

- Chrome 155.0.8059.85, macOS 26.5. The font stack starts with `-apple-system`, so the text is SF Pro.
  A render on another system will differ.
- `MedEdit.png` and `MedEditNow.png` look the same because both boards render `MedForm.dc.html` with `mode=edit`.
- `MedsArchived.png` shows its first row swiped open on purpose, so the Restore action is visible and the row text
  is clipped.
