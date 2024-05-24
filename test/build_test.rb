require "minitest/autorun"

class TestMeme < Minitest::Test
  def setup
    @output = `bin/rake build`
  end

  def test_build
    assert @output.include?("Project built successfully.") 
  end
end