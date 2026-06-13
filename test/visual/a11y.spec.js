const { test, expect } = require("@playwright/test");
const AxeBuilder = require("@axe-core/playwright").default;

// axe is DOM-based, so one engine is enough; running it on every browser project
// would just triple the time without adding coverage.
test.skip(({ browserName }) => browserName !== "chromium", "axe runs on chromium only");

// WCAG 2.1 A/AA is the gate; best-practice (landmarks, etc.) is included so the
// structure we cleaned up stays clean.
const TAGS = ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "best-practice"];

async function audit(page) {
  const { violations } = await new AxeBuilder({ page }).withTags(TAGS).analyze();
  for (const v of violations) {
    console.log(`\n${v.id} (${v.impact}): ${v.help}`);
    for (const n of v.nodes) {
      console.log(`  ${n.target}`);
      console.log(`  ${(n.failureSummary || "").replace(/\n/g, " ")}`);
    }
  }
  return violations.map((v) => v.id);
}

async function scrollPastHero(page) {
  await page.evaluate(() => {
    const hero = document.querySelector(".hero");
    window.scrollTo(0, hero.getBoundingClientRect().bottom + window.scrollY + 200);
  });
  await page.waitForTimeout(400); // let the IntersectionObserver pin the header
}

for (const scheme of ["light", "dark"]) {
  test(`a11y 2.0 desktop, top (${scheme})`, async ({ page }) => {
    await page.emulateMedia({ colorScheme: scheme });
    await page.goto("/en/2.0.0/", { waitUntil: "networkidle" });
    expect(await audit(page)).toEqual([]);
  });

  test(`a11y 2.0 desktop, pinned header + active TOC (${scheme})`, async ({ page }) => {
    await page.emulateMedia({ colorScheme: scheme });
    await page.goto("/en/2.0.0/", { waitUntil: "networkidle" });
    await scrollPastHero(page);
    expect(await audit(page)).toEqual([]);
  });

  test(`a11y 2.0 mobile, top (${scheme})`, async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await page.emulateMedia({ colorScheme: scheme });
    await page.goto("/en/2.0.0/", { waitUntil: "networkidle" });
    expect(await audit(page)).toEqual([]);
  });

  test(`a11y 2.0 mobile, language picker open (${scheme})`, async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await page.emulateMedia({ colorScheme: scheme });
    await page.goto("/en/2.0.0/", { waitUntil: "networkidle" });
    await page.evaluate(() => document.querySelector(".locales").setAttribute("data-open", ""));
    await page.waitForTimeout(150);
    expect(await audit(page)).toEqual([]);
  });
}
