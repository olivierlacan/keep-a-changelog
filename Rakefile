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

namespace :translations do
  desc "Regenerate the static translation-progress dashboard (translation-dashboard.html)"
  task :dashboard do
    sh "ruby translation_coverage.rb --dashboard"
  end

  desc "One-time setup: Python venv + LaBSE model for translation QA"
  task :setup do
    sh "tools/setup.sh"
  end

  desc "Deterministic, rule-based translation lint"
  task :lint do
    sh "ruby translation_coverage.rb --lint"
  end

  desc "Semantic triage: export segments and score them with LaBSE"
  task :qa do
    unless File.exist?("tools/.venv/bin/python")
      abort "Run `bin/rake translations:setup` first to install the model."
    end
    sh "ruby translation_coverage.rb --segments --format jsonl | " \
       "tools/.venv/bin/python tools/labse_triage.py - --relative"
  end
end

namespace :snapshots do
  desc "Build, then record cross-browser baseline screenshots (run before migrating)"
  task baseline: :build do
    sh "npm run snapshot:baseline"
  end

  desc "Rebuild, then diff cross-browser screenshots against the baseline (run after migrating)"
  task check: :build do
    sh "npm run snapshot:check"
  end

  # The breakpoint sweep (test/visual/responsive.spec.js) runs as part of the
  # tasks above; these run it alone, which is much faster while iterating on
  # a layout change at a single breakpoint.
  namespace :sweep do
    desc "Build, then record baselines for the breakpoint sweep only"
    task baseline: :build do
      sh "npm run snapshot:sweep:baseline"
    end

    desc "Rebuild, then diff the breakpoint sweep against its baseline"
    task check: :build do
      sh "npm run snapshot:sweep"
    end
  end
end

require "minitest/test_task"

Minitest::TestTask.create(:test) do |t|
  t.libs << "test"
  # t.libs << "lib"
  t.warning = false
  t.test_globs = ["test/*_test.rb"]
end

task :default => :test