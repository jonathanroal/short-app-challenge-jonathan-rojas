class UpdateTitleJob < ApplicationJob
  queue_as :default

  def perform(short_url_id)
    #Finds object to update and calls update method
    short_url_obj = ShortUrl.find_by_id(short_url_id)
    short_url_obj.update_title!
  end
end
