# Look check for screens

This applies when your brief names a design picture, or when your task adds or changes something the user sees.

A screen that passes its tests can still look wrong. A native control can draw itself differently from the design, and
no test notices. So before you report, compare your screen with the design picture, one control at a time.

1. Take a screenshot of your screen in light and in dark. Put it next to the design picture. Compare in points, not
   pixels, because the pictures have different scales.
2. Write one row per control in the `## Pull request` section. Name the control, the design value, your value, and
   whether they match. Cover size, colour, corner shape, spacing, text size and weight.

   ```
   | Control      | Design                    | Mine                      | Match |
   |--------------|---------------------------|---------------------------|-------|
   | Slider knob  | round, brand red, 28 pt   | white pill, 28 pt         | no    |
   | Card colour  | #1C1C1E in dark           | #1C1C1E in dark           | yes   |
   ```

3. Fix every row that says no. A row may stay no only when the fix is impossible, and then the row says why in one
   line. A native iOS 26 control that draws itself in its own style is a reason to replace it, not to leave it.
4. If your brief names no design picture, say so in one line and describe what you checked by eye instead.

The reviewers read this table. A missing table or a no with no reason is sent back.
