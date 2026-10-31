#!/usr/bin/env ruby
# frozen_string_literal: true

# Extracts every image from a PDF using the `poppler` gem (poppler-glib).
#
#   ruby extract_images.rb arquivo.pdf [diretorio_de_saida]
#
# Requer: gem install poppler (e libpoppler-glib8 + gir1.2-poppler-0.18).
# As imagens saem como PNG, nomeadas pagina-<N>_img-<M>.png. O Poppler as
# entrega já decodificadas (cairo surfaces), então o formato original do PDF
# (JPEG, JBIG2...) não é preservado.

require 'fileutils'
require 'poppler'

pdf_path, out_dir = ARGV
abort "Uso: #{$PROGRAM_NAME} arquivo.pdf [diretorio_de_saida]" unless pdf_path
abort "Arquivo não encontrado: #{pdf_path}" unless File.file?(pdf_path)

out_dir ||= File.join(File.dirname(pdf_path), "#{File.basename(pdf_path, '.*')}_imagens")
FileUtils.mkdir_p(out_dir)

begin
  document = Poppler::Document.new(File.expand_path(pdf_path))
rescue GLib::Error => e
  abort "Não foi possível abrir o PDF: #{e.message}"
end

total = 0
document.each_with_index do |page, page_index|
  page.image_mapping.each_with_index do |mapping, image_index|
    surface = mapping.image
    next unless surface

    file = File.join(out_dir, format('pagina-%03d_img-%02d.png', page_index + 1, image_index + 1))
    surface.write_to_png(file)
    puts "#{file} (#{surface.width}x#{surface.height})"
    total += 1
  end
end

puts "#{total} imagem(ns) extraída(s) de #{document.n_pages} página(s) em #{out_dir}"
