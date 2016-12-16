class Positive < ActiveRecord::Base
    validates :expression, :uniqueness => true
end
