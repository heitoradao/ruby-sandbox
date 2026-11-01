require "minitest/autorun"
require "tmpdir"
require "jekyll/lilypond/renderer"

class RendererTest < Minitest::Test
  SCORE = "\\version \"2.24.0\"\n{ c'4 d' e' f' }\n"

  def setup
    skip "lilypond not installed" unless system("lilypond --version", out: File::NULL, err: File::NULL)
  end

  def test_renders_svg_and_caches
    Dir.mktmpdir do |dir|
      r = Jekyll::Lilypond::Renderer.new(cache_dir: dir)
      path = r.render(SCORE)
      assert_match(/\.svg\z/, path)
      assert_includes File.read(path), "<svg"

      mtime = File.mtime(path)
      assert_equal path, r.render(SCORE)
      assert_equal mtime, File.mtime(path)
    end
  end

  def test_renders_png
    Dir.mktmpdir do |dir|
      path = Jekyll::Lilypond::Renderer.new(cache_dir: dir, format: "png").render(SCORE)
      assert_equal "\x89PNG".b, File.binread(path, 4)
    end
  end

  def test_invalid_source_raises
    Dir.mktmpdir do |dir|
      assert_raises(Jekyll::Lilypond::Error) do
        Jekyll::Lilypond::Renderer.new(cache_dir: dir).render("{ not valid {{")
      end
    end
  end

  def test_unsupported_format
    assert_raises(Jekyll::Lilypond::Error) { Jekyll::Lilypond::Renderer.new(cache_dir: "x", format: "gif") }
  end
end
