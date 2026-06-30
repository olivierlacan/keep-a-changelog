require "minitest/autorun"
require_relative "../tools/version_routing"

# Routing tests for issue #720 ("Default-link to version 2"). They pin the
# contract that 2.0.0 is built and previewable but never the default until it is
# released, and they reproduce the one path that does surface 2.0.0 without a
# ?preview param: a visitor who opted into the preview earlier (it persists).
class VersionRoutingLastVersionTest < Minitest::Test
  def test_default_is_the_published_version_not_the_draft
    # No preview flag (the production build): "latest" stays 1.1.0, never 2.0.0.
    assert_equal "1.1.0", VersionRouting.last_version(preview: nil)
    assert_equal "1.1.0", VersionRouting.last_version(preview: false)
  end

  def test_preview_flag_promotes_the_draft
    assert_equal "2.0.0", VersionRouting.last_version(preview: "1")
    assert_equal "2.0.0", VersionRouting.last_version(preview: true)
  end

  def test_empty_string_flag_counts_as_on_like_an_env_var
    # ENV["KAC_PREVIEW_V2"]="" is truthy in Ruby; config.rb relies on that.
    assert_equal "2.0.0", VersionRouting.last_version(preview: "")
  end
end

class VersionRoutingPublishedVersionTest < Minitest::Test
  # A language that ships every English version, including the 2.0.0 draft.
  FULLY_TRANSLATED = %w[0.3.0 1.0.0 1.1.0 2.0.0]

  def test_production_caps_the_default_redirect_below_the_draft
    # Even though 2.0.0 is installed, the default redirect target is 1.1.0.
    assert_equal "1.1.0", VersionRouting.published_version_for(FULLY_TRANSLATED, last_version: "1.1.0")
  end

  def test_preview_lets_the_redirect_reach_the_draft
    assert_equal "2.0.0", VersionRouting.published_version_for(FULLY_TRANSLATED, last_version: "2.0.0")
  end

  def test_partial_translation_falls_back_to_its_newest_installed_version
    # German has no 2.0.0 yet, so it stays on its newest available spec.
    assert_equal "1.1.0", VersionRouting.published_version_for(%w[1.0.0 1.1.0], last_version: "1.1.0")
    assert_equal "1.0.0", VersionRouting.published_version_for(%w[0.3.0 1.0.0], last_version: "1.1.0")
  end

  def test_ordering_is_semantic_not_lexical
    # 1.10.0 > 1.9.0 numerically even though it sorts earlier as a string.
    assert_equal "1.10.0", VersionRouting.published_version_for(%w[1.9.0 1.10.0], last_version: "2.0.0")
  end

  def test_no_installed_version_yields_nil
    assert_nil VersionRouting.published_version_for([], last_version: "1.1.0")
  end
end

class VersionRoutingExposedVersionTest < Minitest::Test
  INSTALLED = %w[0.3.0 1.0.0 1.1.0 2.0.0]

  def test_build_caps_the_selector_at_the_published_version
    # A production build must not expose the unreleased draft in the selector.
    assert_equal "1.1.0", VersionRouting.exposed_version_for(INSTALLED, last_version: "1.1.0", build: true)
  end

  def test_serve_exposes_newer_drafts_for_local_preview
    assert_equal "2.0.0", VersionRouting.exposed_version_for(INSTALLED, last_version: "1.1.0", build: false)
  end

  def test_preview_build_exposes_the_promoted_draft
    assert_equal "2.0.0", VersionRouting.exposed_version_for(INSTALLED, last_version: "2.0.0", build: true)
  end
end

# The "/" and "/en/" landing redirect (a Ruby mirror of the shipped JS). These
# are the cases issue #720 is about: when does the bare site send a visitor to
# 2.0.0 versus the published 1.1.0?
class VersionRoutingLandingDecisionTest < Minitest::Test
  def decide(param: nil, stored: nil, last_version: "1.1.0")
    VersionRouting.landing_decision(param: param, stored: stored, last_version: last_version)
  end

  def test_no_param_no_storage_lands_on_the_published_version
    target, stored = decide
    assert_equal "1.1.0", target
    assert_nil stored
  end

  def test_preview_param_routes_to_the_draft_and_is_remembered
    target, stored = decide(param: "v2")
    assert_equal "2.0.0", target
    assert_equal "v2", stored # persisted for next time
  end

  # The crux of issue #720: once opted in, a later visit with NO param still
  # lands on 2.0.0 because the choice is remembered. This is the "2.0.0 is the
  # default even without ?preview" behavior — by design, but worth pinning.
  def test_remembered_preview_makes_the_draft_the_default_without_a_param
    target, stored = decide(param: nil, stored: "v2")
    assert_equal "2.0.0", target
    assert_equal "v2", stored
  end

  def test_preview_off_routes_to_published_and_clears_the_memory
    target, stored = decide(param: "off", stored: "v2")
    assert_equal "1.1.0", target
    assert_nil stored
  end

  def test_preview_zero_is_an_alias_for_off
    target, stored = decide(param: "0", stored: "v2")
    assert_equal "1.1.0", target
    assert_nil stored
  end

  def test_unrecognized_param_is_ignored_and_does_not_disturb_memory
    target, stored = decide(param: "yes", stored: "v2")
    assert_equal "2.0.0", target # falls back to the remembered choice
    assert_equal "v2", stored
  end

  def test_default_follows_last_version_under_preview_build
    # If 2.0.0 is actually released ($last_version flips), the non-preview path
    # already points at it without anyone needing the param.
    target, _ = decide(param: nil, stored: nil, last_version: "2.0.0")
    assert_equal "2.0.0", target
  end
end
