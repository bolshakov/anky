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
All questions refer to **last week**.
Garrett S, et al. J Rheumatol 1994;21(12):2286-91.
Couldn't save this result. Try again.
%@. Score %@.
Discard answers?
Discard
Keep Editing
""".split(separator: "\n").map(String.init)
