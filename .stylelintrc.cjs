// Stylelint config for the hand-authored CSS (source/assets/stylesheets/*.css).
//
// We extend stylelint-config-standard for its *correctness* rules — duplicate
// selectors, redundant longhands, invalid values, empty blocks, and the like —
// which catch real mistakes. We switch off the purely stylistic opinions that
// fight this file's deliberate, documented house style, so the linter stays
// signal (bugs) and not noise (reformatting). The .sass files use a different
// syntax and are linted by neither this config nor the lint script.
module.exports = {
  extends: ["stylelint-config-standard"],
  rules: {
    // Whitespace between rules/comments/declarations is authored intentionally.
    "comment-empty-line-before": null,
    "rule-empty-line-before": null,
    "declaration-empty-line-before": null,
    "custom-property-empty-line-before": null,
    "at-rule-empty-line-before": null,

    // Compact single-line rules (e.g. `.foo { a: 1; b: 2; }`) are house style.
    "declaration-block-single-line-max-declarations": null,

    // The palette is authored in decimal-lightness, unitless-hue oklch() on
    // purpose, and media queries use classic min-/max- rather than range syntax.
    "lightness-notation": null,
    "hue-degree-notation": null,
    "alpha-value-notation": null,
    "color-function-notation": null,
    "color-function-alias-notation": null,
    "media-feature-range-notation": null,

    // Intentional names and values.
    "custom-property-pattern": null, // negative steps such as --step--1
    "value-keyword-case": null, // proper-case font-family names (Roboto, Menlo…)
    "property-no-vendor-prefix": null, // -webkit-mask etc. are needed for support

    // Noisy against deliberately ordered, component-grouped rules; the real
    // cascade is verified visually, not by source order.
    "no-descending-specificity": null,
  },
};
