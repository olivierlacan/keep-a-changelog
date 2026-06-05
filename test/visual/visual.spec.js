const { test, expect } = require("@playwright/test");

// Representative pages across versions, scripts, and (below) viewports.
const PAGES = [
  ["/en/0.3.0/", "en-0.3.0"], // legacy.css, markdown
  ["/en/1.0.0/", "en-1.0.0"],
  ["/en/1.1.0/", "en-1.1.0"], // application.css
  ["/en/2.0.0/", "en-2.0.0"], // v2.css
  ["/de/1.1.0/", "de-1.1.0"], // Latin
  ["/ru/1.1.0/", "ru-1.1.0"], // Cyrillic
  ["/ja/1.1.0/", "ja-1.1.0"], // CJK
  ["/ar/1.0.0/", "ar-1.0.0"], // RTL
];

for (const [path, name] of PAGES) {
  test(name, async ({ page }) => {
    await page.goto(path, { waitUntil: "networkidle" });
    await expect(page).toHaveScreenshot(`${name}.png`, { fullPage: true });
  });
}

test.describe("mobile", () => {
  test.use({ viewport: { width: 390, height: 844 } });
  for (const [path, name] of [["/en/1.1.0/", "en-1.1.0-m"], ["/en/2.0.0/", "en-2.0.0-m"]]) {
    test(name, async ({ page }) => {
      await page.goto(path, { waitUntil: "networkidle" });
      await expect(page).toHaveScreenshot(`${name}.png`, { fullPage: true });
    });
  }
});
