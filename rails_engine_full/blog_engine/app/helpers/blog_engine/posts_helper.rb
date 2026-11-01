module BlogEngine
  module PostsHelper
    def blog_title
      Rails.application.config.blog_engine.title
    end

    def excerpt(post)
      truncate(post.body, length: 40)
    end
  end
end
