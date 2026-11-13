// SPDX-License-Identifier: GPL-3.0-or-later

let awaitingRussian = """
%@ to %@
created %@
First entry %@
Symptom report
Name line
Recorded by the patient in Anky.
Counts, averages and ranges only.
Anky is a personal log kept by the patient. It does not give medical advice.
Made with Anky, page %lld of %lld
Get Anky on the App Store
Legend weekly average
Legend lowest to highest
Legend one entry
Legend number under a bar
Legend none logged
Week count none
Severity by week heading
Kind none logged
Places logged
Place
Entries
None logged in this period
Erase every entry, dose, medication and BASDAI result on this iPhone? This can't be undone.
Your entries were erased, but your medications, doses and BASDAI results were not. Try again to erase the rest.
Your entries, doses and medications were erased, but your BASDAI results were not. Try again to erase the rest.
%lld BASDAI results
Q%lld %@
%@. Each answer is 0 to 10; score = (Q1 + Q2 + Q3 + Q4 + (Q5 + Q6) / 2) / 5. \
Bath Ankylosing Spondylitis Disease Activity Index (Garrett et al., J Rheumatol 1994).
Include BASDAI scores
BASDAI results
Shows the scores saved in this period. Everything stays on this iPhone until you share the report.
BASDAI scores
BASDAI scores, continued
Date
Q%lld
Are you sure you want to discard your changes?
Discard Changes
""".split(separator: "\n").map(String.init)
