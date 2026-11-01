require_relative "lib/jekyll/lilypond/version"

Gem::Specification.new do |spec|
  spec.name = "jekyll-lilypond"
  spec.version = Jekyll::Lilypond::VERSION
  spec.authors = ["heitoradao"]
  spec.summary = "Jekyll plugin that renders LilyPond scores to SVG/PNG"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.files = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]

  spec.add_dependency "jekyll", ">= 3.9", "< 5"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rake"
end
