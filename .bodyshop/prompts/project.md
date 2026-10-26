# anky

anky tracks ankylosing spondylitis symptoms on an iPhone. Read `CLAUDE.md` first.

## Threat model

Draft, not yet confirmed by the stakeholder. The data is health data about one person.

In scope:
- Entries leave the device. Nothing is sent, logged, or backed up off the device without a ticket that says so.
- A third-party package. Each one needs a ticket that says why, and an `exact:` pin.
- Entries in logs and crash output. Never print an entry's content.

## Acceptance walks

A `By: agent` example runs in a simulator that the walk creates with `xcrun simctl create` and addresses by UDID. It
deletes the simulator after. Screenshots come from `xcrun simctl io <udid> screenshot`. Two walks never share a
simulator or a DerivedData folder.

The first launch on a freshly created simulator can hang for good while `simctl bootstatus` already says booted.
Run `simctl launch` under `timeout 45`. If it hangs, shut the simulator down, boot it again, and try once more.

## Project files

Never edit `Anky.xcodeproj`. It is generated. A new Swift file under `Sources/` or `App/` needs no other change.
