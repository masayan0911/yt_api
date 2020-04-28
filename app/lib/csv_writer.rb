require 'csv'
class CsvWriter
  def self.generate_report(keyword, row_count = nil ,limit_date_count = nil, limit_play_per_subscriber_rate = nil)
    limit_date_count = 10 if limit_date_count.nil?
    limit_play_per_subscriber_rate = 10 if limit_play_per_subscriber_rate.nil?
    row_count = 50 if row_count.nil?
    items = YoutubeApi.recursive_search(keyword, row_count)
    videos = YoutubeApi.video_filter(items, limit_date_count, limit_play_per_subscriber_rate)
    CSV.open('report.csv', 'w') do |csv|
      csv << ["タイトル", "動画URL", "再生回数", "チャンネル登録者数", "再生回数/チャンネル登録者数","登録日付"]
      videos.each do |item|
        csv << [item["title"], item["url"], item["view_count"], item["subscriber_count"], item["play_per_subscriber_rate"],item["published_date"]]
      end
    end
  end
end