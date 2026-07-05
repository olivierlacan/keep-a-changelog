# --------------------------------------
#   Config
# --------------------------------------

# Version routing (which spec version each entry point resolves to) lives in a
# pure module so it can be unit-tested without booting Middleman. See
# test/version_routing_test.rb.
require_relative "tools/version_routing"

# Version pinning for the hero example changelog (which CHANGELOG.md view each
# spec page shows) lives in a pure module for the same reason. See
# test/changelog_pin_test.rb.
require_relative "tools/changelog_pin"

# Translation coverage analysis. The /translations overview and the
# /translations/progress dashboard embed its data at build time, so both pages
# refresh automatically on every build/deploy — no manual regeneration step.
require_relative "translation_coverage"

# ----- Site ----- #
# Last version should be the latest English version since Keep a Changelog is
# first written in English, then translated into other languages later.
$versions = Dir.glob("source/en/*").map { |e| e.sub("source/en/", "") }.sort
# $last_version = $versions.last

# Published "latest" version. 2.0.0 is written and built on every run, but stays
# unpublished — 1.1.0 remains latest — until release. Set the KAC_PREVIEW_V2 flag
# to promote 2.0.0 to latest for a preview: it flips the "/" and per-language
# redirects, the default selector version, and the "newer version available"
# notices to 2.0.0, without changing the default production build. For example:
#   KAC_PREVIEW_V2=1 bundle exec middleman serve
# To go live, drop the flag and set $last_version = "2.0.0" outright.
$last_version = VersionRouting.last_version(preview: ENV["KAC_PREVIEW_V2"])
$previous_version = $versions[$versions.index($last_version) - 1]

# Expose in-progress version drafts (e.g. a 2.0.0 still being written) only when
# serving locally — never in a production build. This lets the version/language
# selector preview and link to newer English versions before they're published,
# while production stays pinned to $last_version.
# Newest version available for a language that is at or below the published
# $last_version. Used for the default per-language redirect so production never
# routes to an unpublished draft. (Local-dev preview of newer drafts is handled at
# render time by the build?-aware exposed_version_for helper below.)
$published_version_for = lambda do |code|
  installed = $versions.select { |v| File.directory?("source/#{code}/#{v}") }
  VersionRouting.published_version_for(installed, last_version: $last_version)
end

# This list of languages populates the language navigation.
issues_url = "https://github.com/olivierlacan/keep-a-changelog/issues"
$languages = {
  "ar" => {
    name: "العربية"
  },
  "cs" => {
    name: "Čeština"
  },
  "da" => {
    name: "Dansk",
    new: "En ny version er tilgængelig"
  },
  "de" => {
    name: "Deutsch",
    notice: "Die neuste version (#{$last_version}) ist noch nicht auf Deutsch
    verfügbar, aber du kannst sie dir <a href='/en/'>auf Englisch durchlesen</a>
    und <a href='#{issues_url}'>bei der Übersetzung mithelfen</a>."
  },
  "en" => {
    default: true,
    name: "English",
    new: "A new version is available"
  },
  "es-ES" => {
    name: "Español",
    notice: "La última versión (#{$last_version}) aun no está disponible en
    Español, por ahora puedes <a href='/en/'>leerla en Inglés</a> y
    <a href='#{issues_url}'>ayudar a traducirla</a>."
  },
  "fr" => {
    name: "Français",
    notice: "La dernière version (#{$last_version}) n'est pas encore disponible
    en français, mais vous pouvez la <a href='/en/'>lire en anglais</a> pour
    l'instant et <a href='#{issues_url}'>aider à la traduire</a>.",
    new: "Une nouvelle version est disponible"
  },
  "hr" => {
    name: "Hrvatski"
  },
  "id-ID" => {
    name: "Indonesia",
    new: "Ada versi baru tersedia"
  },
  "it-IT" => {
    name: "Italiano",
    notice: "L'ultima versione (#{$last_version}) non è ancora disponibile in
    Italiano, ma la potete <a href='/en/'>leggere in Inglese</a> per ora e
    potete <a href='#{issues_url}'>contribuire a tradurla</a>."
  },
  "ja" => {
    name: "日本語"
  },
  "nb" => {
    name: "Norsk (Bokmål)",
    notice: "Den siste versjonen (#{$last_version}) er ikke tilgjengelig på norsk,
    men du kan <a href='/en/'>lese den på engelsk</a> og <a
    href='#{issues_url}'>hjelpe med å oversette den</a>.",
    new: "En ny versjon er tilgjengelig"
  },
  "nl" => {
    name: "Nederlands"
  },
  "pl" => {
    name: "polski"
  },
  "pt-BR" => {
    name: "Português (BR)",
    notice: "A última versão (#{$last_version}) ainda não está disponível em
    Português mas nesse momento você pode <a href='/en/'>lê-la em inglês</a> e
    <a href='#{issues_url}'>ajudar em sua tradução</a>."
  },
  "ro" => {
    name: "română",
    new: "O nouă versiune este disponibilă"
  },
  "ru" => {
    name: "Pyccкий",
    notice: "Самая последняя версия (#{$last_version}) ещё пока не переведена на
    русский, но вы можете <a href='/en/'>прочитать её на английском</a> и <a
    href='#{issues_url}'>помочь с переводом</a>."
  },
  "sk" => {
    name: "Slovenčina"
  },
  "ka" => {
    name: "ქართული"
  },
  "sl" => {
    name: "Slovenščina"
  },
  "sr" => {
    name: "Srpski"
  },
  "sv" => {
    name: "Svenska",
    notice: "Den senaste versionen (#{$last_version}) är ännu inte tillgänglig på svenska,
    men du kan <a href='/en/'>läsa det på engelska</a> och även <a
    href='#{issues_url}'>hjälpa till att översätta det</a>."
  },
  "tr-TR" => {
    name: "Türkçe"
  },
  "uk" => {
    name: "Українська"
  },
  "zh-CN" => {
    name: "简体中文",
    notice: "最新版 (#{$last_version}) 暂时还没有翻译到简体中文，您可以阅读最新的英语版，并且帮助翻译，不胜感激。"
  },
  "zh-TW" => {
    name: "正體中文",
    notice: "最新版 (#{$last_version}) 暫時還沒有翻譯到正體中文，您可以閱讀最新的英語版，並且幫助翻譯，不勝感激。"
  },
  "ko" => {
    name: "한국어"
  },
  "fa" => {
    name: "فارسی"
  }
}
$language_count = $languages.size

# Localized copy for the "translation missing" interstitial (source/missing.html.haml),
# keyed by the same language codes as $languages. English is the canonical set and
# the per-key fallback — see data/interstitial.yml and the interstitial_string helper.
require "yaml"
$interstitial = YAML.load_file("data/interstitial.yml")

activate :i18n,
  lang_map: $languages,
  mount_at_root: :en

set :gauges_id, ""
set :publisher_url, "https://www.facebook.com/olivier.lacan.5"
set :site_url, "https://keepachangelog.com"

# The root and /en/ landing pages are JS templates (source/index.html.erb and
# source/en/index.html.erb) rather than plain static redirects, so a ?preview=v2
# query param can route visitors to the unreleased 2.0 draft (persisted in
# localStorage; ?preview=off clears it). Without JS they fall through to the
# published $last_version. Every other language keeps a plain static redirect.
$languages.each do |language|
  code = language.first
  next if code == "en"
  redirect "#{code}/index.html", to: "#{code}/#{$published_version_for.call(code)}/index.html"
end

# Every (language, version) pair that hasn't been translated yet still resolves
# to a real URL: a generated interstitial that explains the gap in the target
# language (or English) and links to the English text plus how to contribute the
# missing translation — instead of a 404. This is what lets the version/language
# selectors offer *every* version for *every* language (issue #719): pick one we
# don't have and you land somewhere helpful rather than nowhere.
#
# Interstitials cover every version with an English page — including an
# unreleased draft like 2.0.0. The draft page itself ships in production
# (that's how it is previewed), and its language selector links every language
# at that version, so each of those URLs must resolve. Capping this at
# $last_version in production builds made /fr/2.0.0/ a 404 that the dev
# server, which generated the full set, never showed. Keeping drafts from
# being *surfaced* is the job of selectable_versions, which caps the version
# dropdown in production builds; it is not a reason to leave selector-emitted
# URLs dangling.
spec_versions = $versions.select { |v| File.directory?("source/en/#{v}") }

# Beyond the registered $languages, cover any stray language directory in
# source/ (e.g. "id", the unregistered duplicate of "id-ID"): its pages build
# and render the version selector like any other, so their untranslated
# versions need interstitials too — /id/1.0.0/ was a production 404 reachable
# from /id/1.1.0/'s own version dropdown.
language_dirs = Dir.glob("source/*/*/")
  .select { |d| File.basename(d) =~ /\A\d+\.\d+\.\d+\z/ }
  .map { |d| File.basename(File.dirname(d)) }
  .uniq

($languages.keys | language_dirs).each do |code|
  spec_versions.each do |version|
    next if File.directory?("source/#{code}/#{version}") # real translation exists
    proxy "/#{code}/#{version}/index.html", "/missing.html",
      locals: { language_code: code, version: version }, ignore: true
  end
end

# Patch releases of this project (e.g. 1.1.1) ship fixes to the site and tooling
# without changing the changelog *specification*, so they never get their own
# spec page — the spec stays at the x.y.0 minor (1.1.0). But those patch versions
# do appear in our own example changelog on the homepage, so visitors spot one
# and try /en/1.1.1/, which would otherwise 404 (issue #690). Redirect each such
# patch URL to the minor spec page it belongs to, when that page exists.
File.read("CHANGELOG.md").scan(/^##\s*\[(\d+)\.(\d+)\.(\d+)\]/).each do |major, minor, patch|
  next if patch == "0" # minor/major releases already have their own spec page
  spec_version = "#{major}.#{minor}.0"
  patch_version = "#{major}.#{minor}.#{patch}"
  next unless File.directory?("source/en/#{spec_version}")
  next if File.directory?("source/en/#{patch_version}") # never shadow a real spec page
  redirect "en/#{patch_version}/index.html", to: "en/#{spec_version}/index.html"
end

# ----- Assets ----- #

set :css_dir, "assets/stylesheets"
set :js_dir, "assets/javascripts"
set :images_dir, "assets/images"
set :fonts_dir, "assets/fonts"

# ----- Images ----- #

activate :automatic_image_sizes

# ----- Markdown ----- #

activate :syntax
set :markdown_engine, :kramdown

# input: "GFM" so ```backtick``` fenced code blocks render as <pre><code>
# (kramdown's default parser only fences with ~~~). hard_wrap: false keeps soft
# line wraps from becoming <br>, matching the prior default behavior.
set :markdown, auto_ids: true, smart_quotes: %w[lsquo rsquo ldquo rdquo],
  input: "GFM", hard_wrap: false

# --------------------------------------
#   Helpers
# --------------------------------------

helpers do
  def path_to_url(path)
    Addressable::URI.join(config.site_url, path).normalize.to_s
  end

  # Newest version available for a language. In a production build we cap at the
  # published $last_version; when serving locally we expose newer drafts (e.g. an
  # in-progress 2.0.0) so they can be previewed and picked from the selector.
  def exposed_version_for(code)
    installed = $versions.select { |v| File.directory?("source/#{code}/#{v}") }
    VersionRouting.exposed_version_for(installed, last_version: $last_version, build: build?)
  end

  # The spec versions a visitor may pick from the version selector. We cap at the
  # published $last_version in a production build so unreleased drafts (e.g. an
  # in-progress 2.0.0) never surface; serving locally exposes the full set so
  # drafts can be previewed. Oldest → newest.
  def selectable_versions
    versions = spec_versions
    versions = versions.select { |v| Gem::Version.new(v) <= Gem::Version.new($last_version) } if build?
    versions
  end

  # The real spec version directories ($versions also carries the en index
  # template that the glob picks up), oldest → newest.
  def spec_versions
    dirs = $versions.select { |v| File.directory?("source/en/#{v}") }
    dirs.sort_by { |v| Gem::Version.new(v) }
  end

  # Whether a given spec version has actually been translated for a language.
  def version_available?(code, version)
    File.directory?("source/#{code}/#{version}")
  end

  # major.minor for display (we never ship patch-level spec pages).
  def display_version(version)
    version.split(".").first(2).join(".")
  end

  # A language's autonym (e.g. "Français"), falling back to its code.
  def language_name(code)
    ($languages[code] || {})[:name] || code
  end

  # A localized interstitial string for a language, keyed by e.g. "title" or
  # "lede". Falls back to English per key, so a partially-translated (or entirely
  # untranslated) language still renders a complete page. Interpolate the result
  # with String#% and the appropriate %{...} placeholders. See data/interstitial.yml.
  def interstitial_string(code, key)
    ($interstitial[code] || {})[key] || $interstitial["en"][key]
  end

  # The release date for a version, read from CHANGELOG.md (e.g. the line
  # "## [2.0.0] - 2026-06-07"). Returns the ISO date string, or nil if the
  # version has no dated entry yet.
  def changelog_date_for(version)
    match = File.read("CHANGELOG.md").match(/^##\s*\[#{Regexp.escape(version)}\]\s*-\s*(\d{4}-\d{2}-\d{2})/)
    match && match[1]
  end

  # Human-friendly date with an ordinal day: "2026-06-07" -> "June 7th, 2026".
  # The ISO string stays available for the <time datetime> attribute and title.
  def human_date(iso)
    require "date"
    d = Date.parse(iso)
    n = d.day
    suffix = (11..13).include?(n % 100) ? "th" : { 1 => "st", 2 => "nd", 3 => "rd" }.fetch(n % 10, "th")
    "#{d.strftime("%B")} #{n}#{suffix}, #{d.year}"
  end

  # Should +version+'s page show the pinned (historical) example changelog
  # rather than the live one? Only when the changelog already documents a
  # release on a newer major.minor track than the page's, and the page's own
  # track has a release to pin to.
  def changelog_example_pinned?(version)
    return false unless version
    text = File.read("CHANGELOG.md")
    ChangelogPin.pinned?(text, version) && !ChangelogPin.track_release(text, version).nil?
  end

  # The project's own CHANGELOG, the example every spec page embeds. Pages for
  # spec versions older than the newest track the changelog documents get a
  # view pinned to their own track's last release (see tools/changelog_pin.rb)
  # so the example always matches the conventions the page describes. Raw
  # markdown, hard wraps preserved — what the pre-2.0 pages render directly.
  def changelog_example(version = current_page.metadata[:page][:version])
    text = File.read("CHANGELOG.md")
    changelog_example_pinned?(version) ? ChangelogPin.pin(text, version) : text
  end

  # The example changelog for the 2.0+ hero figure. Soft line wraps in the
  # source (manual 80-column breaks) read badly in a narrow preview, so unwrap
  # them: join hard-wrapped lines within paragraphs and list items while keeping
  # blank lines, headings, list boundaries, and code blocks intact.
  def changelog_preview(version = nil)
    text = changelog_example(version)
    in_code = false
    out = []
    text.each_line do |raw|
      line = raw.chomp
      if line =~ /\A\s*```/
        in_code = !in_code
        out << line
        next
      end
      if in_code || line.strip.empty? ||
         line =~ /\A\s*(#|[-*+]\s|\d+\.\s|>|\|)/ || # heading / list / quote / table
         line =~ /\A\s{4,}\S/ ||                    # indented code
         out.empty? || out.last.strip.empty? ||
         out.last =~ /\A\s*(#|```)/                 # previous line was a heading/fence
        out << line
      else
        out[-1] = "#{out.last} #{line.strip}"
      end
    end
    out.join("\n")
  end
end

# --------------------------------------
#   Content
# --------------------------------------

# ----- Directories ----- #

activate :directory_indexes
page "/404.html", directory_index: false

# ----- Development ----- #

# Live-reload CSS, JS, and templates during `middleman serve` so changes show
# without a manual refresh. The gem ships in the Gemfile but must be activated
# explicitly; without this, edits (especially CSS) don't reload on their own.
configure :development do
  activate :livereload
end

# --------------------------------------
#   Production
# --------------------------------------

# ----- Optimization ----- #

configure :build do
  set :gauges_id, "5389808eeddd5b055a00440d"
  activate :asset_hash
  activate :gzip, {exts: %w[
    .css
    .eot
    .htm
    .html
    .ico
    .js
    .json
    .svg
    .ttf
    .txt
    .woff
  ]}
  activate :minify_css
  activate :minify_html do |html|
    html.remove_quotes = false
  end
  activate :minify_javascript
end

# ----- Prefixing ----- #

activate :autoprefixer do |config|
  config.browsers = ["last 2 versions", "Explorer >= 10"]
  config.cascade = false
end