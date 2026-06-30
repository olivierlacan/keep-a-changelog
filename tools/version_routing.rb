# frozen_string_literal: true

require "rubygems" # Gem::Version

# Pure, framework-free routing logic extracted from config.rb so it can be
# unit-tested without booting Middleman. It answers one question for each entry
# point: which spec version does a visitor land on?
#
#   - last_version          the published "latest" (preview promotes the v2 draft)
#   - published_version_for the per-language default redirect target (never a draft)
#   - exposed_version_for   the newest version offered in the version selector
#   - landing_decision      the client-side "/" and "/en/" redirect — a Ruby mirror
#                           of the JavaScript in source/index.html.erb and
#                           source/en/index.html.erb, kept in sync so the preview
#                           routing can be characterized in a fast test
#
# Keeping these here means the "2.0.0 must not become the default until it is
# released" contract is asserted in CI, not just trusted to live config.
module VersionRouting
  module_function

  # 2.0.0 is written and built on every run but stays unpublished — 1.1.0 remains
  # latest — until release. The KAC_PREVIEW_V2 flag promotes the draft to latest.
  PUBLISHED_VERSION = "1.1.0"
  PREVIEW_VERSION = "2.0.0"

  # The published "latest" version. A truthy preview flag promotes the draft.
  # Mirrors config.rb's `ENV["KAC_PREVIEW_V2"] ? "2.0.0" : "1.1.0"`, so an empty
  # string still counts as "on" (Ruby truthiness), matching the env-var behavior.
  def last_version(preview:)
    preview ? PREVIEW_VERSION : PUBLISHED_VERSION
  end

  # Newest installed version for a language that is at or below last_version, so
  # production never routes to an unpublished draft. `installed` is the list of
  # version strings that actually have a directory for the language.
  def published_version_for(installed, last_version:)
    cap = Gem::Version.new(last_version)
    installed
      .select { |v| Gem::Version.new(v) <= cap }
      .max_by { |v| Gem::Version.new(v) }
  end

  # Newest installed version to expose in the version selector. A production build
  # caps at last_version; serving locally exposes newer drafts so they can be
  # previewed and linked before they are published.
  def exposed_version_for(installed, last_version:, build:)
    pool = installed
    pool = pool.select { |v| Gem::Version.new(v) <= Gem::Version.new(last_version) } if build
    pool.max_by { |v| Gem::Version.new(v) }
  end

  # The landing redirect for "/" and "/en/". Mirrors the shipped JavaScript: an
  # explicit ?preview value wins and is remembered (`v2` opts in; `off`/`0` opt
  # out); with no recognized param the remembered choice decides; the fallback is
  # the published last_version.
  #
  # `param` is the raw ?preview query value (nil when absent). `stored` is the
  # current localStorage value ("v2" or nil). Returns
  # [target_version, stored_after] where stored_after is what localStorage should
  # hold once the script runs (nil means cleared/absent) — so a test can show that
  # 2.0.0 becomes the default on later visits even with no param, once opted in.
  def landing_decision(param:, stored:, last_version:)
    stored_after =
      case param
      when "v2" then "v2"
      when "off", "0" then nil
      else stored
      end

    preview =
      if param == "v2"
        true
      elsif param == "off" || param == "0"
        false
      else
        stored == "v2"
      end

    [preview ? PREVIEW_VERSION : last_version, stored_after]
  end
end
