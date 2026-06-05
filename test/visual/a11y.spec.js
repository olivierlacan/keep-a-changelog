const { test, expect } = require("@playwright/test");
const AxeBuilder = require("@axe-core/playwright").default;

// WCAG 2.1 AA audit of the 2.0 page in both color schemes.
for (const scheme of ["light", "dark"]) {
  test(`a11y 2.0 (${scheme})`, async ({ page }) => {
    await page.emulateMedia({ colorScheme: scheme });
    await page.goto("/en/2.0.0/", { waitUntil: "networkidle" });
    const { violations } = await new AxeBuilder({ page })
      .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa"])
      .analyze();
    for (const v of violations) {
      console.log(`\n[${scheme}] ${v.id} (${v.impact}): ${v.help}`);
      for (const n of v.nodes) {
        console.log(`  ${n.target}`);
        console.log(`  ${(n.failureSummary || "").replace(/\n/g, " ")}`);
      }
    }
    expect(violations.map((v) => v.id)).toEqual([]);
  });
}
