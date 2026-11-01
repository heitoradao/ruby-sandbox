require "jekyll"
require_relative "lilypond/renderer"

module Jekyll
  module Lilypond
    DEFAULTS = {
      "format" => "svg",
      "resolution" => 150,
      "binary" => "lilypond",
      "output_dir" => "assets/lilypond",
      "cache_dir" => ".lilypond-cache"
    }.freeze

    # Static file read from the cache dir but written under output_dir.
    class ScoreFile < Jekyll::StaticFile
      def initialize(site, cache_dir, output_dir, name)
        super(site, cache_dir, "", name)
        @output_dir = output_dir
      end

      def destination(dest)
        File.join(dest, @output_dir, name)
      end

      def url
        "/#{@output_dir}/#{name}"
      end
    end

    # Shared by the tag and the converter: render + register the image as a static file.
    module Helper
      module_function

      def config(site)
        DEFAULTS.merge(site.config["lilypond"] || {})
      end

      # Renders +source+ and returns the site-relative URL of the image.
      def render_to_site(site, source)
        cfg = config(site)
        cache = File.expand_path(cfg["cache_dir"], site.source)
        renderer = Renderer.new(cache_dir: cache, format: cfg["format"],
                                resolution: cfg["resolution"], binary: cfg["binary"])
        path = renderer.render(source)
        name = File.basename(path)
        site.static_files << ScoreFile.new(site, cache, cfg["output_dir"], name)
        "#{site.baseurl}/#{cfg["output_dir"]}/#{name}"
      rescue Error => e
        Jekyll.logger.error "Lilypond:", e.message
        raise Jekyll::Errors::FatalException, e.message
      end

      def wrap(source)
        source.include?("\\version") ? source : "\\version \"2.24.0\"\n#{source}"
      end
    end

    # {% lilypond alt="First bars" %} { c'4 d' e' f' } {% endlilypond %}
    class Block < Liquid::Block
      def initialize(tag_name, markup, tokens)
        super
        @alt = markup[/alt="([^"]*)"/, 1] || "Music score"
      end

      def render(context)
        site = context.registers[:site]
        url = Helper.render_to_site(site, Helper.wrap(super.to_s))
        %(<img class="lilypond" src="#{url}" alt="#{CGI.escapeHTML(@alt)}">)
      end
    end

    # Converts *.ly files (with front matter) into pages containing the rendered score.
    class Converter < Jekyll::Converter
      safe true
      priority :low

      def matches(ext)
        ext.casecmp(".ly").zero?
      end

      def output_ext(_ext)
        ".html"
      end

      def convert(content)
        site = Jekyll.sites.last
        url = Helper.render_to_site(site, Helper.wrap(content))
        %(<img class="lilypond" src="#{url}" alt="Music score">)
      end
    end
  end
end

Liquid::Template.register_tag("lilypond", Jekyll::Lilypond::Block)
