# anky

anky tracks ankylosing spondylitis symptoms on an iPhone. Read `CLAUDE.md` first.

## Threat model

Confirmed by the stakeholder on 2026-10-26. The data is health data about one person, and it stays on the phone.

The promise: entries live only on the device, and leave it only when the person shares an export through the iOS share
sheet. There is no network sync, no iCloud sync, no analytics and no HealthKit. Each of those is a product call. A
ticket may add one only after the stakeholder approves it, and the promise is reworded in the same change.

In scope:
- Entries leave the device. Nothing is sent, logged, or backed up off the device without a ticket that says so.
- Device backups copy app data by default. A ticket that stores entries decides whether to exclude them.
- A third-party package. Each one needs a ticket that says why, and an `exact:` pin.
- Entries in logs and crash output. Never print an entry's content.

## Acceptance walks

A `By: agent` example runs in a simulator that the walk creates with `xcrun simctl create` and addresses by UDID. It
deletes the simulator after. Screenshots come from `xcrun simctl io <udid> screenshot`. Two walks never share a
simulator or a DerivedData folder.

The first launch on a freshly created simulator can hang for good while `simctl bootstatus` already says booted.
Run `simctl launch` under `timeout 45`. If it hangs, shut the simulator down, boot it again, and try once more.

A walk drives the app with `axe`, which taps, types, swipes and reads the screen by accessibility id. It needs no
test runner and no click in the Simulator window. Start the app with `SIMCTL_CHILD_ANKY_ENTRIES_FOLDER=$(uuidgen)`
so no real data is used, and keep that value to relaunch with the same data.
In a Debug build, `SIMCTL_CHILD_ANKY_SEED=spread` fills an empty log with synthetic entries and doses spread over six
months, and `SIMCTL_CHILD_ANKY_SEED=single` with one entry ten days back. `report-short`, `report-long`, `report-sparse`
and `report-places-7` fill it with the report walks' logs, as `App/DebugReportSeed.swift` lists. `report-basdai` fills
it with the `report-short` log and three synthetic BASDAI results. `today-full` fills it with 14 entries dated today,
each at or before now, so Today's list scrolls. A log that holds anything, BASDAI results included, is left as it is.

```sh
axe describe-ui --udid $U          # JSON of the screen, ids are the AXUniqueId fields
axe tap --id log-entry --wait-timeout 5 --udid $U
axe slider --id severity-slider --value 70 --udid $U
axe tap --id save-entry --udid $U
axe screenshot --udid $U --output step.png
```

- Find a control by `--id`. A label depends on the language, so use it only where a control has no id.
- Use `--wait-timeout` and not a sleep. A missing control fails at once with exit code 1.
- Assert on an id that only the screen under test has. Today's ids stay in the tree while New Entry is open.
- A chip's selected state is not in the tree. Check it in a screenshot or through the row that was saved.
- `axe slider` takes about 5 s and does not run inside `axe batch`. `axe type` capitalises the first letter.

## Tests

Keep the test pyramid: many fast tests of pure logic in the packages, few UI tests. Add no slow test, such as a UI test
that reads a frame, a height or a gap, or one that takes a screenshot. An agent walk with `axe` proves how a screen
looks. The stakeholder said on 2026-11-06: "I'd like to avoid writing slow tests as they slow down development
significantly and app changes a lot". A UI test that already exists stays until a ticket removes it.

## Speed examples

An example about speed or size checks what a person does: the newest days open without delay, and the first few pages
load while the log holds thousands of records. Do not walk, scroll or render a whole large log, since nobody reads that
far back. Reaching every old record is a report's job. The stakeholder said on 2026-11-06: "trying to scroll 11k of
records was kinda stupid - people can have that much but they don't want to go that far back to check individual
records".

## Project files

Never edit `Anky.xcodeproj`. It is generated. A new Swift file under `Sources/` or `App/` needs no other change.

## UI catalog

For a task that touches UI, the plan step names the shared pieces from `App/Design/README.md` that the task must use.
The review checklist asks whether the diff builds something the catalog already has.
