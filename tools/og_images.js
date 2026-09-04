#!/usr/bin/env node
// Renders one OpenGraph preview card per spec page into
// source/assets/images/opengraph/<language>/<version>.jpg, from the title and
// description in the page's frontmatter plus the version, in the design of that version's
// site (0.3, 1.x, or 2.0). The layout picks the card for the page's language
// and version, and falls back to the English card for the version, so a new
// translation works before this is re-run.
//
// Dev-only, like the visual regression suite: it needs Node, Playwright's
// Chromium, and network access to Google Fonts (the faces the site uses, plus
// Noto faces for scripts they don't cover). Run it with `bin/rake og:images`
// (or `npm run og:images`) and commit the results. Where the browser can't
// reach Google Fonts, set OG_FONTS_CSS to a stylesheet (path or URL) that
// serves the same families from somewhere it can.

const fs = require("fs");
const os = require("os");
const path = require("path");
const { chromium } = require("playwright");

const root = path.resolve(__dirname, "..");
const sourceDir = path.join(root, "source");
const outDir = path.join(sourceDir, "assets", "images", "opengraph");
const template = path.join(__dirname, "og_template.html");

// Scripts the site's fonts don't cover, and the Google Fonts family that
// stands in for them.
const scriptFonts = {
  ja: "Noto Sans JP",
  ko: "Noto Sans KR",
  "zh-CN": "Noto Sans SC",
  "zh-TW": "Noto Sans TC",
  ar: "Noto Naskh Arabic",
  fa: "Noto Naskh Arabic",
  ka: "Noto Sans Georgian",
};
const rtl = new Set(["ar", "fa"]);

// One stylesheet with every face any card can need, loaded once.
const fontsUrl = (() => {
  const families = [
    "Muli:wght@400;700",
    "Source Code Pro:wght@400;700",
    "Carrois Gothic",
    ...new Set(Object.values(scriptFonts)).values(),
  ].map((f) => (f.includes(":") || f === "Carrois Gothic" ? f : `${f}:wght@400;700`));
  const query = families.map((f) => "family=" + encodeURIComponent(f).replace(/%20/g, "+")).join("&");
  return `https://fonts.googleapis.com/css2?${query}&display=block`;
})();

// Which generation of the site a version belongs to, hence which design.
function design(version) {
  if (version === "0.3.0") return "legacy";
  return Number(version.split(".")[0]) >= 2 ? "v2" : "v1";
}

// The frontmatter here is flat "key: value" lines; that is all we read.
function frontmatter(file) {
  const match = fs.readFileSync(file, "utf8").match(/^---\n([\s\S]*?)\n---/);
  if (!match) return {};
  return Object.fromEntries(
    match[1]
      .split("\n")
      .map((line) => line.match(/^([\w-]+):\s*(.*)$/))
      .filter(Boolean)
      .map(([, key, value]) => [key, value.trim()])
  );
}

function pages() {
  const list = [];
  for (const code of fs.readdirSync(sourceDir).sort()) {
    const langDir = path.join(sourceDir, code);
    if (!fs.statSync(langDir).isDirectory()) continue;
    for (const version of fs.readdirSync(langDir).sort()) {
      if (!/^\d+\.\d+\.\d+$/.test(version)) continue;
      const dir = path.join(langDir, version);
      const file = fs.readdirSync(dir).find((name) => name.startsWith("index.html"));
      if (!file) continue;
      const data = frontmatter(path.join(dir, file));
      if (!data.title || !data.description) {
        throw new Error(`${code}/${version}: frontmatter needs both title and description`);
      }
      list.push({ code, version, title: data.title, description: data.description });
    }
  }
  return list;
}

(async () => {
  const items = pages();
  fs.mkdirSync(outDir, { recursive: true });

  // The template is written next to itself with the fonts URL filled in, so
  // its relative image paths still resolve; removed when done.
  const rendered = path.join(__dirname, ".og_render.html");
  const fontsHref = process.env.OG_FONTS_CSS
    ? (/^[a-z]+:/.test(process.env.OG_FONTS_CSS) ? process.env.OG_FONTS_CSS : "file://" + path.resolve(process.env.OG_FONTS_CSS))
    : fontsUrl;
  fs.writeFileSync(rendered, fs.readFileSync(template, "utf8").replace("__FONTS__", fontsHref));

  // Chromium doesn't read the proxy environment variables on its own.
  const proxy = process.env.HTTPS_PROXY || process.env.https_proxy;
  const browser = await chromium.launch({
    // The template is opened from disk; this lets a local OG_FONTS_CSS
    // stylesheet load its font files from disk too.
    args: ["--allow-file-access-from-files"],
    ...(proxy ? { proxy: { server: proxy } } : {}),
  });
  const page = await browser.newPage({ viewport: { width: 1200, height: 630 }, deviceScaleFactor: 1 });
  try {
    await page.goto("file://" + rendered, { waitUntil: "load" });

    for (const item of items) {
      await page.evaluate(
        ({ code, version, title, description, design, dir, langFont }) => {
          document.documentElement.lang = code;
          document.documentElement.dir = dir;
          document.documentElement.style.setProperty("--lang-font", langFont);
          document.body.dataset.design = design;
          const h1 = document.getElementById("title");
          h1.style.fontSize = "";
          h1.textContent = title;
          document.getElementById("description").textContent = description;
          document.getElementById("version").textContent = version;
        },
        {
          code: item.code,
          version: item.version,
          title: item.title,
          description: item.description,
          design: design(item.version),
          dir: rtl.has(item.code) ? "rtl" : "ltr",
          langFont: scriptFonts[item.code] ? `"${scriptFonts[item.code]}"` : "sans-serif",
        }
      );
      // Fonts load lazily, for the glyphs the text needs: force a layout so
      // the loads start, then wait until nothing is still loading.
      await page.evaluate(async () => {
        document.body.offsetHeight;
        do {
          await document.fonts.ready;
          await new Promise((resolve) => setTimeout(resolve, 50));
        } while (document.fonts.status === "loading");
      });
      // Long titles (Georgian, Persian, Romanian) shrink until the text fits
      // inside the card instead of running off the bottom.
      await page.evaluate(() => {
        const card = document.querySelector(".card");
        const text = document.querySelector(".text");
        const h1 = document.getElementById("title");
        let size = parseFloat(getComputedStyle(h1).fontSize);
        const limit = card.clientHeight - 90;
        while (size > 40 && (text.scrollWidth > text.clientWidth || text.getBoundingClientRect().bottom > limit)) {
          size -= 4;
          h1.style.fontSize = size + "px";
        }
      });

      const file = path.join(outDir, item.code, `${item.version}.jpg`);
      fs.mkdirSync(path.dirname(file), { recursive: true });
      await page.screenshot({ path: file, type: "jpeg", quality: 85 });
      console.log(`${item.code}/${item.version} (${design(item.version)}) -> ${path.relative(root, file)}`);
    }
  } finally {
    await browser.close();
    fs.rmSync(rendered, { force: true });
  }
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
