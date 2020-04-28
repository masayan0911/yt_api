class YoutubeApi
  BASE_URL = "https://www.googleapis.com/youtube/v3/"

  ## Googleから取得したAPIキーを設定する
  API_KEY = "YOUR_API_KEY"

  def self.search(search_keyword, page_token = nil)
    client = Faraday.new BASE_URL do |b|
      b.request :url_encoded
      b.adapter Faraday.default_adapter
    end
    res = client.get 'search' do |req|
      req.params[:key] = API_KEY
      req.params[:part] = "snippet"
      req.params[:q] = search_keyword
      req.params[:order] = "date"
      req.params[:maxResults] = 50
      if page_token.present?
        req.params[:pageToken] = page_token
      end
    end
    json = JSON.parse(res.body)
  end

  def self.videos(video_ids)
    client = Faraday.new BASE_URL do |b|
      b.request :url_encoded
      b.adapter Faraday.default_adapter
    end
    res = client.get 'videos' do |req|
      req.params[:key] = API_KEY
      req.params[:part] = "statistics"
      if video_ids.is_a?(Array)
        req.params[:id] = video_ids.join(",")
      else
        req.params[:id] = video_ids
      end
      req.params[:maxResults] = 50
    end
    json = JSON.parse(res.body)
  end

  def self.channels(channel_ids)
    client = Faraday.new BASE_URL do |b|
      b.request :url_encoded
      b.adapter Faraday.default_adapter
    end
    res = client.get 'channels' do |req|
      req.params[:key] = API_KEY
      req.params[:part] = "statistics"
      if channel_ids.is_a?(Array)
        req.params[:id] = channel_ids.join(",")
      else
        req.params[:id] = channel_ids
      end
      req.params[:maxResults] = 50
    end
    json = JSON.parse(res.body)
  end

  def self.recursive_search(search_keyword, limit = 100)
    items = []
    json = self.search(search_keyword)
    items.concat(json["items"])
    next_page_token = json["nextPageToken"]
    while items.count < limit
      json = self.search(search_keyword, next_page_token)
      items.concat(json["items"])
      next_page_token = json["nextPageToken"]
      break unless next_page_token
    end
    items
  end

  def self.video_filter(items, limit_date_count, limit_play_per_subscriber_rate)
    videos = []
    items.each do |item|
      published_at_str = item["snippet"]["publishedAt"]
      video_id = item["id"]["videoId"]
      channel_id = item["snippet"]["channelId"]
      published_at = Time.parse(published_at_str)
      video_statics = self.videos(video_id)
      next if video_statics["items"].empty?
      play_count = video_statics["items"].first["statistics"]["viewCount"]
      channel_statics = self.channels(channel_id)
      next if channel_statics["items"].empty?
      subscriber_count = channel_statics["items"].first["statistics"]["subscriberCount"]
      title = item["snippet"]["title"]
      ap item["snippet"]["title"]
      if subscriber_count.to_i > 0
        play_per_subscriber_rate = ((play_count.to_f / subscriber_count.to_f)*100).floor
      else
        play_per_subscriber_rate = 0
      end
      ap "再生回数/チャンネル登録者数: #{play_per_subscriber_rate}%"
      ap published_at
      if (published_at + limit_date_count.days) > Time.now && limit_play_per_subscriber_rate <= play_per_subscriber_rate
        hash = {}
        hash["url"] = "https://www.youtube.com/watch?v=#{video_id}"
        hash["view_count"] = play_count
        hash["subscriber_count"] = subscriber_count
        hash["play_per_subscriber_rate"] = play_per_subscriber_rate
        hash["published_date"] = published_at.strftime("%Y/%m/%d")
        hash["title"] = title
        videos << hash
      end

    end
    videos
  end
end