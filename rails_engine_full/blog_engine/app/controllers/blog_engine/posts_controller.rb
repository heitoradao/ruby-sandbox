module BlogEngine
  class PostsController < ApplicationController
    def index
      @posts = Post.recent
    end

    def show
      @post = Post.find(params[:id])
    end

    def new
      @post = Post.new
    end

    def create
      @post = Post.new(params.require(:post).permit(:title, :body))
      if @post.save
        redirect_to post_path(@post)
      else
        render :new, status: :unprocessable_entity
      end
    end
  end
end
