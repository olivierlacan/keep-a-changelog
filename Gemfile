source "https://rubygems.org"

gem "addressable"
gem "middleman", "~> 4.5.1"
gem "middleman-autoprefixer"
gem "middleman-blog"
gem "middleman-livereload"
gem "middleman-minify-html"
gem "middleman-syntax"
gem "middleman-gh-pages"
gem "redcarpet"
# Adds GFM parsing to kramdown so ```backtick``` fenced code blocks render as
# <pre><code> (kramdown's own parser only fences with ~~~).
gem "kramdown-parser-gfm"
gem "standard", "~> 1.51"

# activesupport, em-websocket, and tilt load these from the standard library but
# don't declare them, and Ruby 3.4 drops them from the default gems. Declare them
# so the bundle keeps working on 3.4+ (and Ruby stops warning on 3.3).
gem "base64"
gem "bigdecimal"
gem "csv"
gem "mutex_m"

group :development, :test do
  gem "minitest"
end
