require 'open-uri'
require 'nokogiri'
require 'uri'

class ShortUrl < ApplicationRecord

  CHARACTERS = [*'0'..'9', *'a'..'z', *'A'..'Z'].freeze
  validates_presence_of :full_url, message: "can't be blank"
  validate :validate_full_url

  #Returns complete short_url for display
  def short_url
    #Gets full short url
    'http://localhost:3000/' + self.short_code
  end

  #Converts index to base 62
  def short_code
    return nil if self.id.nil?
    #Gets index
    index = self.id
    #Initializes short code variable
    short_code = ''
    #Loops until index is reduced to 0
    while index > 0
      # Gets modulo of index / 62
      res = index % 62
      # res indicates which char to get from array, which is then added to the beginning of short_code
      short_code.prepend(CHARACTERS[res])
      # Divides index and rounds down to determine if there's more base 62 digits and continue loop
      index = (index / 62).floor
    end
    short_code
  end

  def update_title!
    fetched_title = ""
    begin
      #Uses open-uri to get the HTML data
      open(full_url) do |f|
        #Nokogiri parses HTML
        doc = Nokogiri::HTML(f)
        #Gets title from parsed HTML
        fetched_title = doc.at_css('title').text
      end
    rescue => e
      #Prints error (disabled for test purposes)
      # p e
    end
    #Assigns fetched title to DB object
    self.title = fetched_title
    self.save
  end

  def public_attributes
    # { "click_count" => self.click_count, "created_at"=>self.created_at, "full_url"=>self.full_url, "id"=>self.id, "title"=>self.title, "updated_at"=>self.updated_at }
    self.to_json
  end

  def self.short_to_index(short_code)
    index = 0
    # Digit counter for short_code
    digit = 0
    # Iterates short_code starting from the end
    short_code.reverse.each_char do |char|
      # Gets index of current char within CHARACTERS array
      num = CHARACTERS.index(char)
      # Adds result to base 10 index
      index += num * (62 ** digit)
      # Increments digit counter
      digit += 1
    end
    index
  end

  def self.find_by_short_code(short_code)
    ShortUrl.find_by_id(short_to_index(short_code))
  end

  private

  # Helper method to verify URL
  def compliant?
    # Parses URL to URI object
    uri = URI.parse(full_url)
    # Checks object is valid
    uri.is_a?(URI::HTTP) && !uri.host.nil?
  rescue URI::InvalidURIError
    false
  end

  def validate_full_url
    #Checks URL is valid using helper method
    is_valid = compliant?
    #Throws error unless valid
    if !is_valid
      errors.add(:errors, "Full url is not a valid url")
      errors.add(:full_url, "is not a valid url")
    end
  end

end
