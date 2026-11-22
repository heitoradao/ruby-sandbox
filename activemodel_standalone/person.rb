# frozen_string_literal: true

require 'active_model'

class Person
  include ActiveModel::Model                # initialize(attrs), validations, naming, conversion
  include ActiveModel::Attributes           # typed attributes
  include ActiveModel::Dirty                # change tracking
  include ActiveModel::Serializers::JSON

  attribute :name, :string
  attribute :age, :integer
  attribute :email, :string
  attribute :born_on, :date

  define_attribute_methods :name, :age

  validates :name, presence: true, length: { minimum: 2 }
  validates :age, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  validate :born_on_not_in_future

  def name=(value)
    name_will_change! unless value == name
    super
  end

  def save
    return false unless valid?

    changes_applied
    true
  end

  private

  def born_on_not_in_future
    errors.add(:born_on, 'cannot be in the future') if born_on && born_on > Date.today
  end
end
