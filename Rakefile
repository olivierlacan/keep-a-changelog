require "middleman-gh-pages"

desc "Preview build on localhost:4567 with live reload"
task :serve do
  puts "Running local development server on http://localhost:4567"
  system("bundle exec middleman serve")
end

desc "Clean, build and publish to GitHub Pages"
task deploy: [:clean, :publish]

desc "Build middleman static site"
task :build do
  puts "Build site into build/ directory, print any errors"
  system("bundle exec middleman build --verbose")
end

desc "Delete build directory"
task :clean do
  puts "Cleaning build/ directory"
  system("rm -rf build/")
end

require "minitest/test_task"

Minitest::TestTask.create(:test) do |t|
  t.libs << "test"
  # t.libs << "lib"
  t.warning = false
  t.test_globs = ["test/*_test.rb"]
end

task :default => :test