const { test, expect } = require("@playwright/test");

// Breakpoint sweep: element-level screenshots at one width per layout regime,
// so a change made (and eyeballed) at desktop width can't silently break the
// phone or tablet layouts, and vice versa. Element shots rather than full
// pages so a content edit in one section doesn't shift — and invalidate —
// every other baseline on the page.
//
// The widths straddle every media query in the stylesheets:
//   v2.css      — 480 (collapsed picker), 600 (version/TOC row), 768 (triptych
//                 row + open example), 1248 (TOC sidebar), 1440 (triptych
//                 breakout), 1664 (wide TOC)
//   application — 576 / 768 / 992 / 1200 (the sm/md/lg/xl Sass mixins)
// If a breakpoint is added or moved, add or move a width here to keep one
// probe inside each regime.
//
// Layout across viewports is engine-independent enough that one engine
// suffices; cross-engine rendering is covered by the full-page shots in
// visual.spec.js, which run on all three browsers.
test.skip(({ browserName }) => browserName !== "chromium", "breakpoint sweep runs on chromium only");

const WIDTHS = [390, 540, 700, 1024, 1280, 1512, 1728];

// Per page: the stable, user-facing components worth guarding. Each selector
// must resolve to at least one element at every width (the first match is
// captured).
const PAGES = [
  ["v2", "/en/2.0.0/", {
    header: "article > header",
    hero: ".hero",
    triptych: ".intro-grid",
    toc: "#toc",
    footer: ".footer",
  }],
  ["v1", "/en/1.1.0/", {
    // Not `article > header`: on this design every header child floats, so
    // the header box itself is zero-height and can't be screenshotted. The
    // picker nav is the header's visible content.
    locales: ".locales",
    footer: ".footer",
  }],
  ["legacy", "/en/0.3.0/", {
    locales: ".locales",
    footer: ".footer",
  }],
  ["translations", "/translations/", {
    lede: ".lede",
    grid: ".grid",
    footer: "footer",
  }],
  ["interstitial", "/ro/1.0.0/", {
    header: "article > header",
    missing: ".missing",
  }],
];

for (const [slug, path, elements] of PAGES) {
  for (const width of WIDTHS) {
    test(`${slug} @ ${width}px`, async ({ page }) => {
      await page.setViewportSize({ width, height: 1000 });
      await page.goto(path, { waitUntil: "networkidle" });
      // Screenshot after the webfonts settle, not mid-swap.
      await page.evaluate(() => document.fonts.ready);
      for (const [name, selector] of Object.entries(elements)) {
        await expect(page.locator(selector).first()).toHaveScreenshot(`${slug}-${name}-${width}.png`);
      }
    });
  }
}

// The narrow-screen picker sheet on v2-styled pages is invisible until
// toggled, so the element sweep above never sees it — open it explicitly at
// the phone width. (The focus ring on the version select is part of the
// deal: the toggle handler moves focus into the sheet.)
for (const [slug, path] of [["v2", "/en/2.0.0/"], ["interstitial", "/ro/1.0.0/"]]) {
  test(`${slug} locale sheet @ 390px`, async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await page.goto(path, { waitUntil: "networkidle" });
    await page.evaluate(() => document.fonts.ready);
    await page.click(".locales-toggle");
    await expect(page.locator(".locale-fields")).toHaveScreenshot(`${slug}-locale-sheet-390.png`);
  });
}
