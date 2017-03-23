# --------------------------------------
#   Config
# --------------------------------------

# ----- Site ----- #
# Last version should be the latest English version since the manifesto is first 
# written in English, then translated into other languages later.
$last_version = (Dir.entries("source/en") - %w[. ..]).last

# This list of languages populates the language navigation.
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
  versions = Dir.entries("source/#{code}") - %w[. ..]
  redirect "#{code}/index.html", to: "#{code}/#{versions.last}/index.html"
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
$markdown_config = {
  fenced_code_blocks: true,
  footnotes: true,
  smartypants: true,
  tables: true,
  with_toc_data: true
}
set :markdown, $markdown_config

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

# Haml doesn't pick up on Markdown configuration so we have to remove the 
# default Markdown Haml filter and reconfigure one that follows our 
# global configuration.

module Haml::Filters
  remove_filter("Markdown") #remove the existing Markdown filter

  module Markdown
    include Haml::Filters::Base

    def render(text)
      Redcarpet::Markdown.new(Redcarpet::Render::HTML.new($markdown_config)).render(text)
    end
  end
end
