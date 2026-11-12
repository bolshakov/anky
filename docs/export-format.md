# Export format

Settings has an Export data row. It builds a zip of CSV files on the phone and opens the share sheet for it. Nothing
is sent anywhere by the app: the person chooses where the file goes, and the app deletes its copy when the sheet
closes.

This page is the format promise. A doctor's script, a spreadsheet or a later version of Anky reads an export by what
this page says.

## The zip

The file is named `anky-export-YYYY-MM-DD.zip`, after the local day of the export.

It holds five files, in this order:

1. `manifest.json`
2. `entries.csv`
3. `medications.csv`
4. `doses.csv`
5. `basdai.csv`

The files are stored, not compressed. Every file is dated 1980-01-01 00:00, so two exports of the same data differ
only in `exported_at`. The zip has no comments.

Every entry, every medication, archived ones too, every dose and every BASDAI result is in the export.

## manifest.json

A JSON object with its keys sorted, pretty-printed.

| Field            | Holds                                                                     |
|------------------|---------------------------------------------------------------------------|
| `schema_version` | A number, the version of this format. It is `2`.                          |
| `app_version`    | Text, the version of Anky that made the export, such as `1.4`.            |
| `build`          | Text, the build number of that version, such as `57`.                     |
| `exported_at`    | Text, the moment of the export in UTC, such as `2026-11-11T08:15:00Z`.    |
| `files`          | A list with one object per CSV, in zip order: `entries.csv`, `medications.csv`, `doses.csv`, `basdai.csv`. |

Each object in `files` has:

| Field  | Holds                                                              |
|--------|--------------------------------------------------------------------|
| `name` | Text, the file's name in the zip.                                  |
| `rows` | A number, the data rows of that file. The header row is not counted. |

## CSV rules

These hold for every CSV in the export.

- UTF-8 with no byte-order mark.
- `,` separates cells.
- One header row, then one row per record. The header names are written bare.
- Every line ends with `\n`, the last one too.
- Quoting follows RFC 4180. Every text cell is quoted, even when it holds no comma. A quote inside a cell is doubled.
  A line break inside a cell stays inside the quotes. A number is written bare.
- An empty cell, with nothing between the commas, means there is no value.
- A moment is UTC ISO 8601 in whole seconds with a `Z`, such as `2026-11-11T08:15:00Z`.
- A schedule's time of day (`HH:mm`) and its dates (`YYYY-MM-DD`) are local to the phone, with no zone.
- An id is a UUID in upper case, such as `7C9E6679-7425-40DE-944B-E07FC1F90AE7`. Where rows are ordered by id, it is
  by this text.

In the tables below, a text cell is marked T, a number N, and a cell that can be empty E.

## entries.csv

One row per symptom entry. Rows are ordered by `time`, then by `id`.

| Column     | Form   | Holds                                                                                   |
|------------|--------|-----------------------------------------------------------------------------------------|
| `id`       | T      | The entry's id.                                                                         |
| `time`     | T      | The moment the symptom was logged for, in UTC.                                          |
| `kind`     | T      | `pain`, `stiffness` or `fatigue`.                                                       |
| `severity` | N      | The severity, a whole number from 0 to 10.                                              |
| `places`   | T or E | The body places, joined by `;`, in the order Anky stores them, such as `lower;si_l`. Empty when no place was chosen, and always empty for `fatigue`. |
| `note`     | T or E | The note as typed. Empty when there is no note.                                         |

A place is the id Anky stores for it, such as `neck`, `upper`, `lower`, `tail`, `ribs` or `chest`. A place on one
side of the body ends in `_l` or `_r`, such as `si_l`, `hip_r` or `knee_r`.

## medications.csv

One row per medication, archived ones included. Rows are ordered by `created_at`, then by `id`.

| Column                   | Form   | Holds                                                                        |
|--------------------------|--------|------------------------------------------------------------------------------|
| `id`                     | T      | The medication's id. A dose names it in `medication_id`.                     |
| `created_at`             | T      | The moment the medication was added, in UTC.                                 |
| `updated_at`             | T      | The moment it was last changed, in UTC.                                      |
| `name`                   | T      | The name as typed.                                                           |
| `strength`               | T or E | The strength as typed, such as `400 mg`. Empty when none was typed.          |
| `how_taken`              | T      | `as_needed` or `scheduled`.                                                  |
| `check_in_delay_minutes` | N or E | Minutes after a dose that Anky asks how the person feels. Empty when it does not ask. |
| `archived_at`            | T or E | The moment the medication was archived, in UTC. Empty when it is not archived. |

The schedule columns follow. They are filled for a `scheduled` medication only, and empty for an `as_needed` one. They
are empty too for a `scheduled` medication that has no schedule saved.

| Column         | Form   | Holds                                                                                     |
|----------------|--------|-------------------------------------------------------------------------------------------|
| `repeat_unit`  | T      | `days`, `weeks` or `months`.                                                              |
| `repeat_every` | N      | How many of that unit lie between dose days, such as `2` for every other week.            |
| `weekdays`     | T or E | For `weeks` only: the days of the week, from `mon` `tue` `wed` `thu` `fri` `sat` `sun`, in that order, joined by `;`. Empty for `days` and `months`. |
| `day_of_month` | N or E | For `months` only: the day of the month, 1 to 31. Empty for `days` and `weeks`.           |
| `times`        | T      | The local times of day of the doses, `HH:mm`, in the order Anky stores them, joined by `;`. |
| `starts`       | T      | The local day the schedule starts, `YYYY-MM-DD`.                                          |
| `ends`         | T or E | The local day the schedule ends, `YYYY-MM-DD`. Empty when it does not end.                |

## doses.csv

One row per dose taken. Rows are ordered by `time_taken`, then by `id`.

| Column          | Form   | Holds                                                                                  |
|-----------------|--------|----------------------------------------------------------------------------------------|
| `id`            | T      | The dose's id.                                                                         |
| `logged_at`     | T or E | The moment the dose was logged, in UTC. Empty for a dose logged before Anky kept this. |
| `medication_id` | T      | The `id` of the medication in `medications.csv`.                                       |
| `time_taken`    | T      | The moment the dose was taken, in UTC.                                                 |
| `pain_before`   | N or E | The severity of the entry the dose names as its reading before. Empty when there is none, or that entry was deleted. |
| `pain_after`    | N or E | The severity of the entry the dose names as its reading after. Empty when there is none, or that entry was deleted. |
| `after_time`    | T or E | The `time` of that after entry, in UTC. Empty when `pain_after` is empty.              |

## basdai.csv

One row per saved BASDAI questionnaire. Rows are ordered by `date`, then by `id`. With no result saved, the file holds
its header row only.

| Column       | Form | Holds                                                                                        |
|--------------|------|----------------------------------------------------------------------------------------------|
| `id`         | T    | The result's id.                                                                             |
| `created_at` | T    | The moment the result was saved, in UTC.                                                     |
| `updated_at` | T    | The moment it was last changed, in UTC.                                                      |
| `date`       | T    | The moment the questionnaire is for, in UTC.                                                 |
| `q1`         | N    | The answer to question 1, a whole number from 0 to 10.                                       |
| `q2`         | N    | The answer to question 2, a whole number from 0 to 10.                                       |
| `q3`         | N    | The answer to question 3, a whole number from 0 to 10.                                       |
| `q4`         | N    | The answer to question 4, a whole number from 0 to 10.                                       |
| `q5`         | N    | The answer to question 5, a whole number from 0 to 10.                                       |
| `q6`         | N    | The answer to question 6, a whole number from 0 to 10. It is the slider value and not minutes: `5` means 1 hr, as on the form. |
| `score`      | N    | The BASDAI score, written bare with exactly one decimal and a dot, such as `3.3`, `10.0` or `0.0`. |

The score is calculated at export time from the six answers, as (`q1` + `q2` + `q3` + `q4` + (`q5` + `q6`) / 2) / 5.
It is not stored, and the phone's language never changes how it is written.

## Schema version

`schema_version` in `manifest.json` goes up when a column is removed, renamed, moved or changes meaning, or a file is
added, removed or renamed. Adding `basdai.csv` raised it from `1` to `2`.

A new column at the end of a file keeps the version, so a reader ignores what it does not know.

## Example

An export made on 2026-11-11, with made-up values: two entries, an as-needed medication, a weekly one that is
archived, two doses, and two BASDAI results. The first entry's note holds a comma and quotes.

```text
anky-export-2026-11-11.zip
  manifest.json
  entries.csv
  medications.csv
  doses.csv
  basdai.csv
```

`manifest.json`:

```json
{
  "app_version" : "1.4",
  "build" : "57",
  "exported_at" : "2026-11-11T08:15:00Z",
  "files" : [
    {
      "name" : "entries.csv",
      "rows" : 2
    },
    {
      "name" : "medications.csv",
      "rows" : 2
    },
    {
      "name" : "doses.csv",
      "rows" : 2
    },
    {
      "name" : "basdai.csv",
      "rows" : 2
    }
  ],
  "schema_version" : 2
}
```

`entries.csv`:

```csv
id,time,kind,severity,places,note
"1B4E28BA-2FA1-4D3B-9A5C-0E1F2A3B4C5D","2026-11-10T07:30:00Z","pain",6,"lower;si_l","Stiff after the drive, ""worse than usual"""
"7C9E6679-7425-40DE-944B-E07FC1F90AE7","2026-11-10T09:50:00Z","pain",3,"lower",
```

`medications.csv`:

```csv
id,created_at,updated_at,name,strength,how_taken,check_in_delay_minutes,archived_at,repeat_unit,repeat_every,weekdays,day_of_month,times,starts,ends
"3F2504E0-4F89-41D3-9A0C-0305E82C3301","2026-09-01T09:00:00Z","2026-09-01T09:00:00Z","Example tablet","400 mg","as_needed",120,,,,,,,,
"9B2D6C1A-5E7F-4A8B-B3C4-D5E6F7A8B9C0","2026-09-15T18:00:00Z","2026-11-01T08:00:00Z","Example injection",,"scheduled",,"2026-11-01T08:00:00Z","weeks",1,"sun",,"09:00","2026-09-20",
```

`doses.csv`:

```csv
id,logged_at,medication_id,time_taken,pain_before,pain_after,after_time
"E4D909C2-90D0-4B3C-8F1E-2A3B4C5D6E7F",,"9B2D6C1A-5E7F-4A8B-B3C4-D5E6F7A8B9C0","2026-10-25T08:05:00Z",,,
"C56A4180-65AA-42EC-A945-5FD21DEC0538","2026-11-10T07:46:00Z","3F2504E0-4F89-41D3-9A0C-0305E82C3301","2026-11-10T07:45:00Z",6,3,"2026-11-10T09:50:00Z"
```

`basdai.csv`:

```csv
id,created_at,updated_at,date,q1,q2,q3,q4,q5,q6,score
"5D2A8F10-3B6C-4E71-8A9D-1C2B3A4D5E6F","2026-11-03T07:10:00Z","2026-11-03T07:10:00Z","2026-11-03T07:10:00Z",4,6,3,5,7,4,4.7
"A1B2C3D4-E5F6-4A7B-8C9D-0E1F2A3B4C5D","2026-11-10T07:20:00Z","2026-11-10T07:25:00Z","2026-11-10T07:20:00Z",0,0,0,0,0,0,0.0
```

The real bytes are checked against this page when a release is made, as `docs/release-checklist.md` says.
