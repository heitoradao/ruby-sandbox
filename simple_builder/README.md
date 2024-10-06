# SimpleBuilder

This example renders an html.

Transforming the input:

```ruby
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
```

into:

```html
<html>
  <head>
    <title>
      Title of this html
    </title>
  </head>
  <body>
    <h1>
      titulo
    </h1>
    <div>
      <p>
        conteudo
      </p>
      <hr />
      <p>
        outro conteúdo
      </p>
    </div>
  </body>
</html>
```
