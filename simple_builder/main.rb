#! ruby
# frozen_string_literal: true
require_relative 'simple_builder'

sb = SimpleBuilder.new

sb.html do
  sb.head do
    sb.title('Title of this html') {}
  end
  sb.body do
    sb.h1('titulo') {}
    sb.div do
      sb.p('conteudo') {}
      sb.hr
      sb.p('outro conteúdo') {}
    end
  end
end

