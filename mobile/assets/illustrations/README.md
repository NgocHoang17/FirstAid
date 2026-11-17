# FirstAid reminder diagrams

These JSON files describe original vector reminder diagrams rendered by
`StepIllustration` and `ReminderPainter`. The drawings and captions were authored
for FirstAid. They contain no copied PDF photographs, downloaded medical images,
third-party stock artwork or AI-generated clinical poses.

The drawings follow the same usage terms as the project code. There is no
additional third-party image permission to obtain for these original drawings.
References for the medical instructions remain attached to each article.

The drawings summarize actions such as calling, cooling, protecting a wound and
monitoring breathing. They do not demonstrate anatomical hand placement, force,
injection technique or patient positioning. The complete written instructions,
age limits and exceptions must remain visible. Captions and screen-reader labels
are supplied offline with the drawings.

The Admin illustration selector and preview read this same JSON catalogue.
`admin/src/StepIllustration.tsx` renders SVG equivalents of `ReminderPainter`
using the same coordinates and colors. When introducing a new `kind`, update
both renderers; adding an asset with an existing kind requires only its JSON.
Each reading view groups the step heading, instructions and its illustration
together, so a following step's image cannot be mistaken for the preceding one.

A missing or unsupported drawing must leave the written step available. Never
infer a medical procedure from a diagram or generate a caption from a keyword.
