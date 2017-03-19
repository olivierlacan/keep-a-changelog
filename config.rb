# --------------------------------------
#   Config
# --------------------------------------

# ----- Site ----- #
$last_version = "0.3.0"
$languages = {
  "cs"    => "Čeština",
  "de"    => "Deutsch",
  "en"    => "English",
  "es-ES" => "Español",
  "fr"    => "Français",
  "it-IT" => "Italiano",
  "pt-BR" => "Brazilian Portugese",
  "ru"    => "Pyccкий",
  "sl"    => "Slovenščina",
  "sv"    => "Svenska",
  "tr-TR" => "Türkçe",
  "zh-CN" => "简体中文",
  "zh-TW" => " 繁體中文"
}

activate :i18n,
  lang_map: $languages,
  mount_at_root: :en

set :gauges_id, ''
set :publisher_url, 'https://www.facebook.com/olivier.lacan.5'
set :site_url, 'http://keepachangelog.com'

redirect "index.html", to: "en/#{$last_version}/index.html"

$languages.each do |language|
  code = language.first
  available_versions = Dir.entries("source/#{code}") - %w[. ..]

  if Dir.exists?("source/#{code}/#{$last_version}")
    redirect "#{code}/index.html", to: "#{code}/#{$last_version}/index.html"
  else
    redirect "#{code}/index.html", to: "#{code}/#{available_versions.last}/index.html"
  end
end

# ----- Assets ----- #

set :css_dir, 'assets/stylesheets'
set :js_dir, 'assets/javascripts'
set :images_dir, 'assets/images'
set :fonts_dir, 'assets/fonts'

# ----- Images ----- #

activate :automatic_image_sizes

# ----- Markdown ----- #

activate :syntax
set :markdown_engine, :redcarpet
set :markdown, {
  fenced_code_blocks: true,
  footnotes: true,
  smartypants: true,
  tables: true
}

# --------------------------------------
#   Helpers
# --------------------------------------

helpers do
  def path_to_url(path)
    Addressable::URI.join(config.site_url, path).normalize.to_s
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
  set :haml, {ugly: true, attr_wrapper: '"'}
  activate :minify_css
  activate :minify_html do |html|
    html.remove_quotes = false
  end
  activate :minify_javascript
end

# ----- Prefixing ----- #

activate :autoprefixer do |config|
  config.browsers = ['last 2 versions', 'Explorer >= 10']
  config.cascade  = false
end
