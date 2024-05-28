class Api::Me::SuggestController < Api::ApplicationController
  def index
    genre_counts = HistoryLike.where(user_id: current_user.id).joins(song: :genre)
      .group("genres.id")
      .select("genres.id, genres.title, COUNT(*) as count")
      .order("count DESC")
      .limit(3)

    top_genres = genre_counts.map do |genre_count|
      { id: genre_count.id, title: genre_count.title, count: genre_count.count }
    end

    suggested_song_ids = []
    top_genres.each do |genre|
      songs_not_listened = Song.where.not(id: HistoryLike.where(user_id: current_user.id).pluck(:song_id))
                              .joins(:genre)
                              .where(genres: { id: genre[:id] })
                              .limit(5)
                              .pluck(:id)
      suggested_song_ids.concat(songs_not_listened)
    end

    songs = Song.where(id: suggested_song_ids)
    if songs
      render json: songs, each_serializer: SongSerializer
    else
      render json: []
    end
  end
end