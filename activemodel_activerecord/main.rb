#! /usr/bin/env ruby
# frozen_string_literal: true

require 'active_record'

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
ActiveRecord::Schema.verbose = false

ActiveRecord::Schema.define do
  create_table :articles do |t|
    t.string :title
    t.text :body
    t.string :status, default: 'draft'
    t.timestamps
  end
end

# ActiveRecord::Base already includes ActiveModel (Validations, Dirty, Callbacks, Naming, Serialization...)
p ActiveRecord::Base.include?(ActiveModel::Validations)

# A reusable ActiveModel concern shared by record and non-record classes
module Slugged
  extend ActiveSupport::Concern

  def slug = title.to_s.downcase.strip.gsub(/[^a-z0-9]+/, '-').gsub(/\A-|-\z/, '')
end

class Article < ActiveRecord::Base
  include Slugged

  enum :status, { draft: 'draft', published: 'published' }, default: 'draft'

  validates :title, presence: true, length: { maximum: 80 }
  validates :body, presence: true, unless: :draft?

  before_save { self.title = title.strip }
  after_save { puts "saved ##{id} (changes: #{saved_changes.except('created_at', 'updated_at').keys.join(', ')})" }
end

# A form object: ActiveModel without a table, delegating to the ActiveRecord model
class ArticleForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :title, :string
  attribute :body, :string
  attribute :publish, :boolean, default: false

  validate :article_valid

  def save
    return false unless valid?

    article.save!
  end

  def article
    @article ||= Article.new(title: title, body: body, status: publish ? :published : :draft)
  end

  private

  # Re-use the record's validations and copy its errors into the form
  def article_valid
    return if article.valid?

    article.errors.each { |e| errors.add(e.attribute, e.message) }
  end
end

form = ArticleForm.new(title: '  Hello ActiveModel  ', body: 'text', publish: '1')
p form.save, form.article.status, form.article.slug

bad = ArticleForm.new(title: '', publish: true)
p bad.save
puts bad.errors.full_messages

article = Article.first
article.title = 'New title'
p article.changed?, article.changes.keys
article.save
puts article.to_json(only: %i[id title status])
p Article.model_name.plural, article.persisted?
