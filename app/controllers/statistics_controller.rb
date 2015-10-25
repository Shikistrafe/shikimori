class StatisticsController < ShikimoriController
  respond_to :html
  YEARS_AGO = 26.years

  include CacheHelper

  def index
    @page_title = 'История аниме'
    @page_description = 'Никогда не задумывались, сколько всего существует аниме, каких оно жанров и типов, и как оно менялось по прошествии лет? На данной странице представлены несколько графиков со статистикой по истории аниме за последние четверть века.'
    set_meta_tags description: @page_description
    set_meta_tags keywords: 'история аниме, статистка аниме сериалов, индустрия аниме, рейтинги аниме, студии аниме, жанры аниме'

    @kinds = Anime.kind.values#.select {|v| v != 'music' }
    @rating_kinds = ['tv', 'movie', 'ova']

    @total, @by_kind, @by_rating, @by_genre, @by_studio =
      Rails.cache.fetch([:statistics, russian_genres_key, Time.zone.today]) do
        prepare
        [total_stats, stats_by_kind, stats_by_rating, stats_by_genre, stats_by_studio]
      end

    @topic = Topics::Factory.new(false).build Topic.find(81906)
  end

private

  # общая статистика
  def total_stats
    grouped = @animes.group_by(&:kind).sort

    by_kind = {
      name: 'Тип',
      data: grouped.map do |kind, group|
        {
          name: I18n.t("enumerize.anime.kind.#{kind}"),
          y: group.size
        }
      end
    }
    by_score = {
      name: 'Оценка',
      data: grouped.map do |kind, group|
        group.group_by do |v|
          if v.score >= 8
            '8+'
          elsif v.score >= 7
            '7'
          else
            '6-'
          end
        end.sort.map do |score, group|
          {
            name: score,
            y: group.size
          }
        end
      end.flatten
    }

    {
      categories: [],
      series: [by_kind, by_score]
    }
  end

  # статистика по рейтингу
  def stats_by_rating
    ratings = Anime.rating.values.select { |v| v != 'none' }

    @rating_kinds.each_with_object({}) do |kind, memo|
      memo[kind] = stats_data(@animes.select { |v| v.kind == kind && !v.rating_none? }, :rating, ratings)
    end
  end

  # статистика по жанрам
  def stats_by_genre
    top_genres = @rating_kinds.each_with_object({}) do |kind, memo|
      memo[kind] = normalize(stats_data(@animes.select { |v| v.kind == kind }.map(&:mapped_genres).flatten, :genre, @genres), 4)[:series].map { |v| v[:name] }
    end

    data = @rating_kinds.each_with_object({}) do |kind, memo|
      memo[kind] = stats_data(@animes.select { |v| v.kind == kind }.map(&:mapped_genres).flatten, :genre, @genres)
    end

    # отключаем второстепенные жанры
    data.each do |kind,stats|
      stats[:series].each do |stat|
        stat[:visible] = (top_genres[kind].include?(stat[:name]) && stat[:name] != 'Детское') || (kind == 'tv' && stat[:name] == 'Гарем')
      end
    end

    data
  end

  # статистика по студиям
  def stats_by_studio
    animes_10 = @tv.select { |v| v.aired_on >= Time.zone.parse("#{Time.zone.now.year}-01-01") - 10.years }
    #top_studios = normalize(stats_data(animes_10.map { |v| v[:mapped_studios] }.flatten, :studio, @studios), 0.75)[:series].map { |v| v[:name] }

    data = stats_data(animes_10.map(&:mapped_studios).flatten, :studio, @studios + ['Прочее'])
    other = {
      name: 'Прочее',
      data: [0,0,0,0,0,0,0,0,0,0,0],
      visible: false
    }
    data[:series].select! do |stat|
      if stat[:data].sum > 10
        true
      else
        stat[:data].each_with_index do |v,k|
          other[:data][k] += v
        end
        false
      end
    end
    data[:series].insert -1, other

    data
  end

  # статистика по типам
  def stats_by_kind
    stats_data(@animes, :kind, @kinds)
  end

  # подготовка общих данных
  def prepare
    @genres = Genre.order(:position).all.map {|v| UsersHelper.localized_name v, current_user }
    @studios_by_id = Studio.all.each_with_object({}) do |v, memo|
      memo[v.id] = v
    end
    @studios = @studios_by_id.select { |v| v.real? }.map { |k,v| v.filtered_name }

    start_on = Time.zone.parse("#{Time.zone.now.year}-01-01") - YEARS_AGO
    finish_on = Time.zone.parse("#{Time.zone.now.year}-01-01") - 1.day + 1.year

    @animes = Anime
      .where.not(aired_on: nil)
      .where('aired_on >= ?', start_on)
      .where('aired_on <= ?', finish_on)
      .where(kind: @kinds)
      .select([:id, :aired_on, :kind, :rating, :score])
      .order(:aired_on)
      .eager_load(:genres, :studios) # не использовать includes для HABTM ассоциаций!!! оно дико тормозит на больших объёмах данных
      .each do |anime|
        anime.singleton_class.class_eval do
          attr_accessor :mapped_genres, :mapped_studios
        end
      end

    @animes.each do |entry|
      entry.mapped_genres = entry.genres.map do |genre|
        {
          genre: UsersHelper.localized_name(genre, current_user),
          aired_on: entry.aired_on
        }
      end
      entry.mapped_studios = entry.real_studios.map do |studio|
        {
          studio: Studio::Merged.include?(studio.id) ? @studios_by_id[Studio::Merged[studio.id]].filtered_name : studio.filtered_name,
          aired_on: entry.aired_on
        }
      end
    end
    @tv = @animes.select(&:kind_tv?)
  end

  # выборка статистики
  def stats_data(animes, grouping, categories)
    years = animes.group_by { |v| Russian.strftime(v[:aired_on], '%Y') }.keys

    groups = categories.each_with_object({}) do |group, memo|
      memo[group] = nil
    end

    data = animes
      .group_by {|v| v.respond_to?(grouping) ? v.send(grouping) : v[grouping] }
      .each_with_object(groups) do |entry,data|
        next unless data.include? entry[0]
        data[entry[0]] = years.each_with_object({}) { |v, memo| memo[v] = 0 }

        entry[1].group_by { |v| Russian.strftime(v[:aired_on], '%Y') }.each do |k,v|
          data[entry[0]][k] = v.size
        end
      end
      .select { |k,v| v.present? }

    {
      categories: years,
      series: data.map do |k,v|
        {
          name: [:kind, :rating].include?(grouping) ? I18n.t("enumerize.anime.#{grouping}.#{k}") : k,
          data: v.values
        }
      end
    }
  end

  # приведение статистики к нормальному виду
  def normalize(data, minimum)
    new_series = data[:series].map do |entry|
      {
        name: entry[:name],
        data: entry[:data].each_with_index.map do |number,i|
          number * 100.0 / data[:series].sum { |entry| entry[:data][i] }
        end
      }
    end

    data[:series] = new_series.select do |stat|
      stat[:data].any? { |v| v >= minimum }
    end

    data
  end
end
