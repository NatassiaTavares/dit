class Searchtweet < ActiveRecord::Base
    validates :text, :uniqueness => true
end
