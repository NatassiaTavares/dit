class Search < ActiveRecord::Base
    validates :text, :uniqueness => true
end
