require 'nokogiri'
require 'open-uri'
require 'CSV'

class IdolMusicAwardCrawler
  SLICE_LIMIT_RANK = 100
  TYPE_DICT = {
    "major" => 'songm',
    "indies" => 'songi',
  }

  attr_reader :target_name, :url

  def initialize(target_name)
    @target_name = target_name
    prepare_url(target_name)
  end

  def crawl
    doc = prepare_doc
    ranking = slice_ranking(doc)
    CSV.open("output/#{target_name}.csv", "w", col_sep: "\t") do |line|
      header = %W(rank title artist points)
      line << header
      ranking.each { |row| line << row }
    end
  end

  private

  def prepare_url(target_name)
    year, raw_type = /(\d+)_(\w*)/.match(target_name).to_a.values_at(1,2)
    type = TYPE_DICT[raw_type]
    @url = "https://www.esrp2.jp/ima/#{year}/comment/result/#{type}.html"
  end

  def prepare_doc
    html = fetch_html
    doc = Nokogiri::HTML.parse(html, nil, nil)
  end

  def fetch_html
    charset = nil
    sleep 1
    html = URI.open(url) do |f|
      charset = f.charset
      f.read
    end
  end

  def slice_ranking(doc)
    raw_ranking = doc.css('tbody tr').first(SLICE_LIMIT_RANK)
    raw_ranking.map {|row| convert_to_array(row) }
  end

  def convert_to_array(row)
    result = row.css('td').map {|element| element.text.strip}
    result.pop(2) #票数、平均ポイントは削除
    result
  end

end

if __FILE__ == $0
  target_name = ARGV[0]
  crawler = IdolMusicAwardCrawler.new(target_name)
  crawler.crawl
end
