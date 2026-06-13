const { defineConfig, devices } = require("@playwright/test");

module.exports = defineConfig({
  testDir: "./test/visual",
  snapshotPathTemplate: "{testDir}/__screenshots__/{projectName}/{arg}{ext}",
  fullyParallel: true,
  reporter: "list",
  // Serve the already-built site. Run `rake build` (or the generator's build) first.
  // `bundle exec` so webrick resolves from the bundle (it isn't a default gem on
  // Ruby 3.x, so a bare `ruby -run -e httpd` would fail in clean CI).
  webServer: {
    command: "bundle exec ruby -run -e httpd build -p 8731",
    url: "http://127.0.0.1:8731/en/1.1.0/",
    reuseExistingServer: true,
    timeout: 60000,
  },
  use: { baseURL: "http://127.0.0.1:8731" },
  expect: { toHaveScreenshot: { maxDiffPixelRatio: 0.01, animations: "disabled" } },
  projects: [
    { name: "chromium", use: { ...devices["Desktop Chrome"] } },
    { name: "firefox", use: { ...devices["Desktop Firefox"] } },
    { name: "webkit", use: { ...devices["Desktop Safari"] } },
  ],
});
