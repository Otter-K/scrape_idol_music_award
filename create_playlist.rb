require 'rspotify'
require 'dotenv'
require 'csv'
require 'unicode'
Dotenv.load

class PlaylistCreator
  TYPE_DICT = {
    'major' => 'メジャーアイドル楽曲',
    'indies' => 'インディーズ/地方アイドル楽曲'
  }.freeze

  class << self
    def main(target_name)
      user = prepare_user
      year, type = parse_target_name(target_name)

      playlist = user.create_playlist!("アイドル楽曲大賞#{year} #{type}部門 1~100位")

      CSV.foreach("output/#{target_name}.csv", headers: true, col_sep: "\t").with_index do |row, _index|
        track = track_search(row['title'], row['artist'])
        sleep 1
        playlist.add_tracks!([track]) #配列じゃないと追加できないためArray化
        puts "プレイリスト追加: #{row['title']}/#{row['artist']}"
      end
    end

    private

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

    def track_search(title, artist)
      sleep 1
      track = RSpotify::Track.search("#{title} artist:#{artist}", limit: 1, market: 'JP').first
      return track if valid?(track, artist)

      sleep 1
      track = RSpotify::Track.search("#{title}　#{artist}", limit: 1, market: 'JP').first
      return track if valid?(track, artist)

      # 見つからなかったら世界で一番短い曲を入れる
      RSpotify::Track.find('5oD2Z1OOx1Tmcu2mc9sLY2') # Napalm Death/You Suffer
    end

    def valid?(track, artist)
      # 表記揺れがあるため、バリデーション時のみフォーマットしてから見る
      track && track.artists.any? {|tracks_artist| format_name(tracks_artist.name).include?(format_name(artist))}
    end

    def format_name(name)
      Unicode::nfkc(name.downcase).gsub(/[[:space:]]/, '')
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  RSpotify.authenticate(ENV['APP_TOKEN'], ENV['APP_SECRET_TOKEN'])
  target_name = ARGV[0]
  PlaylistCreator.main(target_name)
end
