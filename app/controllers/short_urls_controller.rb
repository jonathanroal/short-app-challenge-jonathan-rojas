class ShortUrlsController < ApplicationController

  # Since we're working on an API, we don't have authenticity tokens
  skip_before_action :verify_authenticity_token

  def index
    #Returns top 100 urls sorted on click count
    top_urls = ShortUrl.order(click_count: :desc).limit(100);
    json_urls = []
    #Converts each URL into json format ()
    top_urls.each do |n|
      json_urls << n.to_json
    end
    render json: {urls: json_urls}
  end

  def create
    #Checks if url has already been shortened
    url = ShortUrl.find_by_full_url(params[:full_url])
    if url
      #Returns short url if it already exists
      render :json => {short_code: url.short_url}
    else
      #Creates new ShortUrl item in DB
      url = ShortUrl.create(full_url: params[:full_url])
      if url.save
        #Updates title through job
        UpdateTitleJob.perform_now(url.id)
        render :json => {short_code: url.short_url}
      else
        render json: url.errors, status: 404
      end
    end
  end

  def show
    #Looks for short_url with given id
    short_url = ShortUrl.find_by_id(ShortUrl.short_to_index(params[:id]))
    #If exists
    if short_url
      #Increments click count by 1
      short_url.update_attribute(:click_count, short_url.click_count + 1)
      #Redirects in browser
      redirect_to short_url.full_url
    else
      #Renders empty json and returns 404
      render json: {}, status: 404
    end
  end

end
