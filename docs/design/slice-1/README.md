# Design references for the first slice

These are screenshots of the stakeholder's design canvas "Anky Screens", page "Features 1-5". Workers cannot open the
canvas, so these stand in for it. Each file is 390 by 844 points at 2x.

The ticket text wins when it disagrees with a picture. A picture shows layout, spacing, type size, color and shape. The
ticket says what the words are, what the rules are and what is out of scope.

## What to match and what to leave to the system

- Match the order of sections, the spacing, the chip and row shapes, and the colors in light and dark.
- The canvas draws the navigation bar, tab bar and slider as web shapes. Build them with the native SwiftUI controls
  and keep the canvas's arrangement, titles and labels.
- The canvas uses the Inter font as a stand-in. Use the system font and Dynamic Type.

## What is not in this slice

Some screens show things that belong to later features. Do not build them:

- "Log medication" button on Today, and the dose rows such as "Naproxen 500 mg" and "Adalimumab 40 mg".
- The "Check in" strip on Today and the "Check in" label on a dose row in History.
- The Settings tab. The tab bar has Today and History only.
- "Save and log another place" is not drawn. It is held in its own ticket.

## Which picture belongs to which ticket

| Ticket | Pictures |
| --- | --- |
| t-1 (Log how you feel and see it on Today) | `new-entry-*`, `today-*`, `today-empty-*` |
| t-2 (Fix or delete a logged entry from Today) | `edit-entry-*`, `edit-entry-delete-confirm-light` |
| t-3 (Read the log back in History) | `history-*`, `history-empty-*`, `history-swipe-delete-light` |
| t-4 (Say where it hurts, for any joint) | `places-*`, `new-entry-fatigue-light` |
| t-5 (Repeat a recent entry in one tap) | `new-entry-*` (the two chips on top), `today-light`, `today-logged-light` |

`-light` and `-dark` are the same screen in each appearance.
