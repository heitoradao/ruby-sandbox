require "digest"
require "fileutils"
require "open3"
require "tmpdir"

module Jekyll
  module Lilypond
    class Error < StandardError; end

    # Pure conversion: LilyPond source -> image file. No Jekyll dependency,
    # so it can be explored/tested on its own. Results are cached by content hash.
    class Renderer
      FORMATS = %w[svg png].freeze

      attr_reader :cache_dir, :format, :resolution, :binary

      def initialize(cache_dir:, format: "svg", resolution: 150, binary: "lilypond")
        raise Error, "unsupported format: #{format}" unless FORMATS.include?(format)

        @cache_dir = cache_dir
        @format = format
        @resolution = resolution
        @binary = binary
      end

      # Returns the path of the rendered image, rendering only on cache miss.
      def render(source)
        FileUtils.mkdir_p(cache_dir)
        name = "#{Digest::SHA256.hexdigest([source, format, resolution].join("\0"))[0, 16]}.#{format}"
        target = File.join(cache_dir, name)
        compile(source, target) unless File.exist?(target)
        target
      end

      private

      def compile(source, target)
        Dir.mktmpdir("jekyll-lilypond") do |dir|
          input = File.join(dir, "score.ly")
          File.write(input, source)
          _out, err, status = Open3.capture3(*command(File.join(dir, "score"), input))
          raise Error, "lilypond failed:\n#{err}" unless status.success?

          FileUtils.cp(File.join(dir, "score.cropped.#{format}"), target)
        end
      rescue Errno::ENOENT => e
        raise Error, "cannot run #{binary}: #{e.message}"
      end

      def command(output_prefix, input)
        args = [binary, "-dcrop", "-o", output_prefix]
        args += format == "svg" ? ["-dbackend=svg"] : ["--png", "-dresolution=#{resolution}"]
        args << input
      end
    end
  end
end
