class CreateBlogEnginePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :blog_engine_posts do |t|
      t.string :title, null: false
      t.text :body, null: false
      t.timestamps
    end
  end
end
