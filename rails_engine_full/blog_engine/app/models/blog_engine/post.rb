module BlogEngine
  class Post < ApplicationRecord
    validates :title, :body, presence: true

    scope :recent, -> { order(id: :desc) }
  end
end
