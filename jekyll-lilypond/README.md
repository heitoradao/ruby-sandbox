# jekyll-lilypond

Skeleton of a Jekyll plugin gem for exploring data conversion: LilyPond source -> SVG/PNG.

- `lib/jekyll/lilypond/renderer.rb` – pure conversion (`lilypond` CLI, cropped output, SHA256 content cache); no Jekyll dependency.
- `lib/jekyll/lilypond.rb` – Jekyll integration: Liquid block `{% lilypond %}…{% endlilypond %}`,
  a Converter for `*.ly` files with front matter, and a StaticFile that publishes images to `assets/lilypond/`.

Config (`_config.yml`): `lilypond: {format: svg|png, resolution: 150, binary: lilypond, output_dir: assets/lilypond, cache_dir: .lilypond-cache}`.

    rake test                                   # needs lilypond installed
    cd example && jekyll build -s . -d /tmp/site
