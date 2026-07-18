const { test, expect } = require("@playwright/test");

// Routing tests originally written for issue #720 ("Default-link to version
// 2"). Before release they pinned the contract that 2.0.0 was previewable but
// never the default; since the 2.0.0 release they pin the inverse: every entry
// point lands on 2.0.0, with or without a ?preview param, with or without
// JavaScript. The ?preview param stays recognized but is a no-op while no
// newer draft exists, so links shared before the release keep working.
//
// These complement test/version_routing_test.rb: that unit-tests a Ruby mirror
// of the decision; this exercises the shipped JavaScript and localStorage.

const PUBLISHED = /\/en\/2\.0\.0\/$/;

// Land on `path`, then wait for the JS-replace / meta-refresh redirect to settle
// on a versioned spec page (e.g. /en/2.0.0/ or /de/1.1.0/) and return that URL.
async function landed(page, path) {
  // "commit" (not "load"): the landing page calls location.replace during load,
  // which aborts a load-waiting goto. Then poll the URL until the redirect lands
  // on a versioned spec page — polling (rather than waitForURL) avoids missing
  // the synchronous replace event that fires before a listener could attach.
  await page.goto(path, { waitUntil: "commit" });
  await expect.poll(() => page.url(), { timeout: 15000 }).toMatch(/\/\d+\.\d+\.\d+\/$/);
  return page.url();
}

test.describe("landing redirect (/)", () => {
  test.use({ storageState: { cookies: [], origins: [] } }); // start with empty storage

  test("with no preview param, defaults to the released 2.0.0", async ({ page }) => {
    expect(await landed(page, "/")).toMatch(PUBLISHED);
  });

  test("/en/ also defaults to the released 2.0.0", async ({ page }) => {
    expect(await landed(page, "/en/")).toMatch(PUBLISHED);
  });

  test("?preview=v2 still lands on 2.0.0 (pre-release links keep working)", async ({ page }) => {
    expect(await landed(page, "/?preview=v2")).toMatch(PUBLISHED);
  });

  test("?preview=off no longer opts out of the released version", async ({ page }) => {
    expect(await landed(page, "/?preview=v2")).toMatch(PUBLISHED);
    expect(await landed(page, "/?preview=off")).toMatch(PUBLISHED);
    expect(await landed(page, "/")).toMatch(PUBLISHED);
  });
});

test.describe("without JavaScript", () => {
  test.use({ javaScriptEnabled: false });

  // The meta-refresh fallback sends no-JS visitors to the published version,
  // which is now 2.0.0.
  test("falls back to the released 2.0.0 via meta refresh", async ({ page }) => {
    expect(await landed(page, "/")).toMatch(PUBLISHED);
  });
});

test.describe("per-language static redirects", () => {
  // A language without a 2.0.0 translation must redirect to its newest
  // translated spec, never to a page that does not exist in that language.
  test("/de/ redirects to the newest translated German spec", async ({ page }) => {
    expect(await landed(page, "/de/")).toMatch(/\/de\/1\.1\.0\/$/);
  });
});
