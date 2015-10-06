require 'pry'
require 'redcarpet'
require "pathname"

class Generate < Thor
  include Thor::Actions

  LANGUAGES = {
    "pt-BR" => "Brazilian Portugese"
  }

  desc "index", "generate index.html from README.md"
  def index
    puts "Processing README.md to generate a new index.html..."

    relative_path_to_readme = "README.md"
    relative_path_to_index = "index.html"

    # `r` means we're using the "read" mode with the file
    # we need a String for Redcarpet, it doesn't accept File objects.
    string = File.open(relative_path_to_readme, 'r') { |file| file.read }
    renderer = HTMLwithHeaderLinks.new
    markdown = ::Redcarpet::Markdown.new(renderer, markdown_renderer_options)

    rendered_markdown = markdown.render(string)

    html_output = template { rendered_markdown }

    File.open(relative_path_to_index, 'w') { |file| file.write(html_output) }

    puts "All done!"
  end

  desc "translations", "generate translations HTML from README.md"
  def translations
    puts "Processing translations to generate new translatations/language/index.html..."

    path_to_translations = "translations/"
    path_to_index = "index.html"

    # `r` means we're using the "read" mode with the file
    # we need a String for Redcarpet, it doesn't accept File objects.
    translation_directories = Pathname.new(path_to_translations).children.select { |c| c.directory? }

    translation_directories.each do |directory|
      language_code = directory.basename.to_s
      language = LANGUAGES[language_code]

      string = File.open(directory + "README.md", 'r') { |file| file.read }
      renderer = HTMLwithHeaderLinks.new
      markdown = ::Redcarpet::Markdown.new(renderer, markdown_renderer_options)

      rendered_markdown = markdown.render(string)
      asset_path = "../../assets" # we're inside translations/<language_code>
      html_output = template(language, asset_path) { rendered_markdown }

      File.open(directory + path_to_index, 'w') { |file| file.write(html_output) }

      puts "All done!"
    end
  end

  private

  def language_links
    LANGUAGES.map do |language|
      code = language.first
      name = language.last

      <<-HTML
        <li>
          <a lang="#{code}" rel="alternate" hreflang="#{code}" href="/translations/#{code}/index.html">
            #{name}
          </a>
        </li>
      HTML
    end.join
  end

  def template(language = "English", assets_path = 'assets', &block)
    <<-HTML.gsub /^\s+/, ""
      <html>
        <head>
          <title>Keep a Changelog | #{language}</title>
          <link rel="stylesheet" href="#{assets_path}/stylesheets/normalize.css" media="screen" charset="utf-8">
          <link rel="stylesheet" href="#{assets_path}/stylesheets/style.css" media="screen" charset="utf-8">
          <script type="text/javascript" src="//use.typekit.net/tng8liq.js"></script>
          <script type="text/javascript">try{Typekit.load();}catch(e){}</script>
        </head>
        <body>
          <article>
            <nav class="lang">
              <ol>
                <li><a href="/index.html">English</a></li>
                #{language_links}
              </ol>
            </nav>
            #{yield}
            <footer class="clearfix">
              <p class="license">This project is <a href="http://choosealicense.com/licenses/mit/">MIT Licensed</a>.</p>
              <p class="about"><a href="https://github.com/olivierlacan/keep-a-changelog/">Typed</a> with trepidation by <a href="http://olivierlacan.com">Olivier Lacan</a> from <a href="http://codeschool.com">Code School</a>.</p>
            </footer>
          </article>
          <script type="text/javascript">
            var _gauges = _gauges || [];
            (function() {
              var t   = document.createElement('script');
              t.type  = 'text/javascript';
              t.async = true;
              t.id    = 'gauges-tracker';
              t.setAttribute('data-site-id', '5389808eeddd5b055a00440d');
              t.src = '//secure.gaug.es/track.js';
              var s = document.getElementsByTagName('script')[0];
              s.parentNode.insertBefore(t, s);
            })();
          </script>
        </body>
      </html>
    HTML
  end

  def markdown_renderer_options
    {
      autolink: true,
      no_intra_emphasis: true,
      fenced_code_blocks: true,
      disable_indented_code_blocks: true,
      lax_spacing: true,
      lax_html_blocks: true,
      strikethrough: true,
      superscript: true,
      tables: true,
      with_toc_data: true
    }
  end
end

class HTMLwithHeaderLinks < Redcarpet::Render::HTML
  def header(title, level)
    @headers ||= []
    permalink = title.gsub(/\W+/, '-').downcase

    if @headers.include?(permalink)
      permalink += '_1'
      permalink = permalink.succ while @headers.include?(permalink)
    end

    @headers << permalink

    %(
      <h#{level} id=\"#{permalink}\">
        <a name="#{permalink}" class="anchor" href="##{permalink}"></a>
        #{title}
      </h#{level}>
    )
  end
end
