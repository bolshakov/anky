// SPDX-License-Identifier: GPL-3.0-or-later

let awaitingRussian = """
How would you describe the overall level of fatigue/tiredness you have experienced?
How would you describe the overall level of AS **neck, back or hip** pain you have had?
How would you describe the overall level of pain/swelling in joints **other than** neck, back or hips you have had?
How would you describe the overall level of discomfort you have had from any areas tender to touch or pressure?
How would you describe the overall level of morning stiffness you have had from the time you wake up?
How long does your morning stiffness last from the time you wake up?
Spinal pain
Joint pain
Tenderness
Stiffness severity
Stiffness duration
Very severe
0 hrs
2 or more hrs
1 hr
%lld min
1 hr %lld min
2 hrs or more
Not answered
not answered
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
BASDAI
No BASDAI results yet
BASDAI is six questions about the last week, each answered from 0 to 10. It takes about a minute. \
Saved results are listed here with their date.
Bath Ankylosing Spondylitis Disease Activity Index (Garrett et al., J Rheumatol 1994).
Bath Ankylosing Spondylitis Disease Activity Index (Garrett et al., J Rheumatol 1994). Swipe left to delete.
Start
Garrett S, et al. J Rheumatol 1994;21(12):2286-91.
Couldn't save this result. Try again.
%@. Score %@.
Discard answers?
Discard
Keep Editing
Legend weekly average
Legend lowest to highest
Legend one entry
Legend number under a bar
Legend none logged
Week count none
Places logged
Place
Entries
None logged in this period
Delete this result? This can't be undone.
Delete result
Couldn't delete this result. Try again.
Result deleted
Score
Erase every entry, dose, medication and BASDAI result on this iPhone? This can't be undone.
Your entries were erased, but your medications, doses and BASDAI results were not. Try again to erase the rest.
Your entries, doses and medications were erased, but your BASDAI results were not. Try again to erase the rest.
%lld BASDAI results
Q%lld %@
%@. Each answer is 0 to 10; score = (Q1 + Q2 + Q3 + Q4 + (Q5 + Q6) / 2) / 5. \
Bath Ankylosing Spondylitis Disease Activity Index (Garrett et al., J Rheumatol 1994).
""".split(separator: "\n").map(String.init)
