require 'rspotify'
require 'dotenv'
require 'csv'
Dotenv.load

class PlaylistCreator
  TYPE_DICT = {
    'major' => 'メジャーアイドル楽曲',
    'indies' => 'インディーズ/地方アイドル楽曲'
  }.freeze

  class << self
    def prepare_user
      RSpotify::User.new(JSON.parse(ENV['OAUTH_TOKENS'])).tap do |user|
        # ユーザー認証後のTokenでないと検索結果が安定しないため、Token更新
        RSpotify.instance_variable_set(:@client_token, user.credentials['token'])
      end
    end

    def parse_target_name(target_name)
      year, raw_type = /(\d+)_(\w*)/.match(target_name).to_a.values_at(1, 2)
      [year, TYPE_DICT[raw_type]]
    end

    def create_playlist(target_name)
      user = prepare_user
      year, type = parse_target_name(target_name)

      playlist = user.create_playlist!("アイドル楽曲大賞#{year} #{type}部門 1~100位")

      CSV.foreach("output/#{target_name}.csv", headers: true, col_sep: "\t").with_index do |row, _index|
        # OPTIMIZE: 検索クエリ("artist:"クエリを安定して使えないか)
        query = "#{row['title']}　#{row['artist']}"

        # 検索に失敗した場合は適当な曲で穴埋めし、後から修正
        # NOTE:現状のクエリだと正誤問わずなんかしらは返ってきてそう、バリデーションをかけるべきかも
        sleep 1
        track = RSpotify::Track.search(query, limit: 1, market: 'JP') ||
                RSpotify::Track.search('君が代', limit: 1, market: 'JP')
        playlist.add_tracks!(track)

        puts "プレイリスト追加: #{row['title']}/#{row['artist']}"
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  RSpotify.authenticate(ENV['APP_TOKEN'], ENV['APP_SECRET_TOKEN'])
  target_name = ARGV[0]
  PlaylistCreator.create_playlist(target_name)
end
