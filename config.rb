# --------------------------------------
#   Config
# --------------------------------------

# ----- Site ----- #
# Last version should be the latest English version since the manifesto is first
# written in English, then translated into other languages later.
$versions = Dir.glob("source/en/*").map { |e| e.sub("source/en/", "") }.sort
# $last_version = $versions.last
$last_version = "1.1.0"
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
  $versions.select { |v|
    File.directory?("source/#{code}/#{v}") && Gem::Version.new(v) <= Gem::Version.new($last_version)
  }.max_by { |v| Gem::Version.new(v) }
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

activate :i18n,
  lang_map: $languages,
  mount_at_root: :en

set :gauges_id, ""
set :publisher_url, "https://www.facebook.com/olivier.lacan.5"
set :site_url, "https://keepachangelog.com"

redirect "index.html", to: "en/#{$last_version}/index.html"

$languages.each do |language|
  code = language.first
  redirect "#{code}/index.html", to: "#{code}/#{$published_version_for.call(code)}/index.html"
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

set :markdown, auto_ids: true, smart_quotes: %w[lsquo rsquo ldquo rdquo]

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
    installed = installed.select { |v| Gem::Version.new(v) <= Gem::Version.new($last_version) } if build?
    installed.max_by { |v| Gem::Version.new(v) }
  end

  def available_translation_for(language)
    version = exposed_version_for(language.first)
    "#{version} #{language.last[:name]}" if version
  end

  # The project's own CHANGELOG, shown as the hero example. Soft line wraps in the
  # source (manual 80-column breaks) read badly in a narrow preview, so unwrap
  # them: join hard-wrapped lines within paragraphs and list items while keeping
  # blank lines, headings, list boundaries, and code blocks intact.
  def changelog_preview
    in_code = false
    out = []
    File.read("CHANGELOG.md").each_line do |raw|
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