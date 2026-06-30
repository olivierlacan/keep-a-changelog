const { test, expect } = require("@playwright/test");

// Routing tests for issue #720 ("Default-link to version 2"). They drive the
// real built landing pages — the client-side redirect in source/index.html.erb
// and source/en/index.html.erb plus the static per-language redirects — and pin
// when a visitor lands on the unreleased 2.0.0 draft versus the published 1.1.0.
//
// These complement test/version_routing_test.rb: that unit-tests a Ruby mirror
// of the decision; this exercises the shipped JavaScript and localStorage.

const PUBLISHED = /\/en\/1\.1\.0\/$/;
const PREVIEW = /\/en\/2\.0\.0\/$/;

// Land on `path`, then wait for the JS-replace / meta-refresh redirect to settle
// on a versioned spec page (e.g. /en/1.1.0/ or /de/1.1.0/) and return that URL.
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

  test("with no preview param, defaults to the published version", async ({ page }) => {
    expect(await landed(page, "/")).toMatch(PUBLISHED);
  });

  test("/en/ also defaults to the published version", async ({ page }) => {
    expect(await landed(page, "/en/")).toMatch(PUBLISHED);
  });

  test("?preview=v2 opts into the 2.0.0 draft", async ({ page }) => {
    expect(await landed(page, "/?preview=v2")).toMatch(PREVIEW);
  });

  // The heart of issue #720: opting into the preview persists, so a later bare
  // visit with no param still lands on 2.0.0. That is "2.0.0 is the default even
  // without ?preview" — by design (localStorage), but reproduced here explicitly.
  test("a remembered preview makes 2.0.0 the default on the next bare visit", async ({ page }) => {
    expect(await landed(page, "/?preview=v2")).toMatch(PREVIEW);
    expect(await landed(page, "/")).toMatch(PREVIEW); // no param, yet still 2.0.0
  });

  test("?preview=off clears the memory and returns to the published version", async ({ page }) => {
    expect(await landed(page, "/?preview=v2")).toMatch(PREVIEW);
    expect(await landed(page, "/?preview=off")).toMatch(PUBLISHED);
    expect(await landed(page, "/")).toMatch(PUBLISHED); // memory cleared
  });
});

test.describe("without JavaScript", () => {
  test.use({ javaScriptEnabled: false });

  // The meta-refresh fallback must always send no-JS visitors to the published
  // version, never the draft — even the PREVIEW constant is JS-only.
  test("falls back to the published version via meta refresh", async ({ page }) => {
    expect(await landed(page, "/?preview=v2")).toMatch(PUBLISHED);
  });
});

test.describe("per-language static redirects", () => {
  // A partially translated language has no 2.0.0 draft, so its bare path must
  // redirect to its newest published spec — capped at the published version.
  test("/de/ redirects to the newest published German spec", async ({ page }) => {
    expect(await landed(page, "/de/")).toMatch(/\/de\/1\.1\.0\/$/);
  });
});
