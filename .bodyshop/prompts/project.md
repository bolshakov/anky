# anky

anky tracks ankylosing spondylitis symptoms on an iPhone. Read `CLAUDE.md` first.

## Threat model

Confirmed by the stakeholder on 2026-10-26. The data is health data about one person, and it stays on the phone.

The promise: entries live only on the device. There is no network sync, no iCloud sync, no analytics and no HealthKit.
Each of those is a product call. A ticket may add one only after the stakeholder approves it, and the promise is
reworded in the same change.

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

## Project files

Never edit `Anky.xcodeproj`. It is generated. A new Swift file under `Sources/` or `App/` needs no other change.
