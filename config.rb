# --------------------------------------
#   Config
# --------------------------------------

# ----- Site ----- #
# Last version should be the latest English version since the manifesto is first
# written in English, then translated into other languages later.
$versions = Dir.glob("source/en/*").map{ |e| e.sub("source/en/","") }.sort
# NOTE: for now, while 1.1.0 is in development let's pin the latest
# version to 1.0.0 manually.
# $last_version = $versions.last
$last_version = "1.0.0"
$previous_version = $versions[$versions.index($last_version) - 1]

# This list of languages populates the language navigation.
issues_url = 'https://github.com/olivierlacan/keep-a-changelog/issues'
$languages = {
  "cs"    => {
    name: "Čeština"
  },
  "da"    => {
    name: "Dansk",
    new: "En ny version er tilgængelig"
  },
  "de"    => {
    name: "Deutsch",
    notice: "Die neuste version (#{$last_version}) ist noch nicht auf Deutsch
    verfügbar, aber du kannst sie dir <a href='/en/'>auf Englisch durchlesen</a>
    und <a href='#{issues_url}'>bei der Übersetzung mithelfen</a>."
  },
  "en"    => {
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
  "fr"    => {
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
  "nl" => {
    name: "Nederlands"
  },
  "pl" => {
    name: "polski"
  },
  "pt-BR" => {
    name: "Português do Brasil",
    notice: "A última versão (#{$last_version}) ainda não está disponível em
    Português mas nesse momento você pode <a href='/en/'>lê-la em inglês</a> e
    <a href='#{issues_url}'>ajudar em sua tradução</a>."
  },
  "ru"    => {
    name: "Pyccкий",
    notice: "Самая последняя версия (#{$last_version}) ещё пока не переведена на
    русский, но вы можете <a href='/en/'>прочитать её на английском</a> и <a
    href='#{issues_url}'>помочь с переводом</a>."
  },
  "sk"    => {
    name: "Slovenčina"
  },
  "ka"    => {
    name: "ქართული"
  },
  "sl"    => {
    name: "Slovenščina"
  },
  "sr" => {
    name: "Srpski"
  },
  "sv"    => {
    name: "Svenska",
    notice: "Den senaste versionen (#{$last_version}) är ännu inte tillgänglig på Svenska,
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
  "fa-IR" => {
    name: "فارسی"
  }
}

activate :i18n,
  lang_map: $languages,
  mount_at_root: :en

set :gauges_id, ''
set :publisher_url, 'https://www.facebook.com/olivier.lacan.5'
set :site_url, 'https://keepachangelog.com'

redirect "index.html", to: "en/#{$last_version}/index.html"

$languages.each do |language|
  code = language.first
  versions = Dir.entries("source/#{code}").sort - %w[. ..]
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

## Override default Redcarpet renderer in order to define a class
class CustomMarkdownRenderer < Redcarpet::Render::HTML
  def doc_header
    %Q[<nav role="navigation" class="toc">#{@header}</nav>]
  end

  def header(text, header_level)
    slug = text.parameterize
    tag_name = "h#{header_level}"
    anchor_link = "<a id='#{slug}' class='anchor' href='##{slug}' aria-hidden='true'></a>"
    header_tag_open = "<#{tag_name} id='#{slug}'>"

    output = ""
    output << header_tag_open
    output << anchor_link
    output << text
    output << "</#{tag_name}>"

    output
  end
end

$markdown_config = {
  fenced_code_blocks: true,
  footnotes: true,
  smartypants: true,
  tables: true,
  with_toc_data: true,
  renderer: CustomMarkdownRenderer
}
set :markdown, $markdown_config

# --------------------------------------
#   Helpers
# --------------------------------------

helpers do
  def path_to_url(path)
    Addressable::URI.join(config.site_url, path).normalize.to_s
  end

  def available_translation_for(language)
    language_name = language.last[:name]
    language_path = "source/#{language.first}"

    if File.exists?("#{language_path}/#{$last_version}")
      "#{$last_version} #{language_name}"
    elsif File.exists?("#{language_path}/#{$previous_version}")
      "#{$previous_version} #{language_name}"
    else
      nil
    end
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
  set :haml, { attr_wrapper: '"' }
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

    def renderer
      $markdown_config[:renderer]
    end

    def render(text)
      Redcarpet::Markdown.new(renderer.new($markdown_config)).render(text)
    end
  end
end
