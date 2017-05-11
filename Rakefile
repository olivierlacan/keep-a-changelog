require "middleman-gh-pages"

desc "Build and publish to GitHub Pages"
task :deploy => :publish

task "assets:precompile" do
  sh "middleman build --verbose"
end
