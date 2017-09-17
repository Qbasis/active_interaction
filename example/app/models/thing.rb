# Define a thing with a name.
class Thing < ActiveRecord::Base
  validates :name,
    presence: true
end
