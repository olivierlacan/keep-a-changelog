# Narrow-screen version + language picker

Screenshots for [#729](https://github.com/olivierlacan/keep-a-changelog/pull/729),
the redesign of the phone-width picker into a labelled sheet.

## Before

The globe opened a cramped popover: two bare selects with no visible labels,
so tapping a globe (a language cue) landed on unexplained version numbers.

![Broken picker: native version dropdown showing 1.1, 1.0, 0.3 with no labels over a clipped popover](mobile-locale-sheet-before.png)

## After

The gear expands the header downward into a full-width sheet with each field
labelled above a full-width select.

| Open (light) | Open (dark) |
| --- | --- |
| ![Open sheet in light mode: labelled Version and Language selects spanning the full header width](mobile-locale-sheet-open-light.png) | ![Open sheet in dark mode](mobile-locale-sheet-open-dark.png) |

| Closed header | Missing-translation interstitial |
| --- | --- |
| ![Closed header with the gear toggle and chevron](mobile-locale-sheet-closed-light.png) | ![The same sheet on the missing-translation page, which shares the partial](mobile-locale-sheet-missing-open.png) |
