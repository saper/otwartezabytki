# -*- encoding : utf-8 -*-
module ApplicationHelper

  def users_statistics
    # registered users are those with username
    registered = User.where('username IS NOT NULL').count

    # count only users if less of 200 of them are registered from the same ip
    non_registered = User.group(:last_sign_in_ip).select('count(id) as ids')
    .having('count(id) < 200').where('username IS NULL')
    .map(&:ids).map(&:to_i).sum

    [registered + non_registered, registered, non_registered]
  end

  def users_activity_statistics
    ranges = [
      [5, 8, "przed śniadaniem"],
      [8, 17, "w godzinach pracy"],
      [17, 20, "przed kolacją"],
      [20, 0, "po wieczornym wydaniu wiadomości"],
      [0, 5, "przez sen :)"]
    ]

    ranges.each do |range|
      a,b = range[0], range[1]-1
      b += 24 if b < 0 # 0 - 1 = -1 => -1 + 24 = 23
      range[3] = Suggestion.roots.where(["date_part('hour', suggestions.created_at AT TIME ZONE 'GMT') BETWEEN ? AND ?", a, b-1]).count
    end

    ranges.reject! {|e| e[3] == 0 }
    ranges.sort_by! {|e| e[3] }

    all = Suggestion.roots.count

    ranges.each do |range|
      range[4] = (range[3].to_f * 100 / all).ceil
    end

    [ranges.pop, ranges.first].reverse
  end

  def relics_statistics
    [Relic.count] + [1,2,3].map do |i|
      sql = Suggestion.select("relic_id").group(:relic_id).having(["COUNT(relic_id) >= ?", i]).to_sql
      Suggestion.from("(#{sql}) AS stats").count
    end
  end

  def random_search_suggestions
    types = SuggestedType.order("RANDOM()").map {|e| e.name }
    places = Relic.roots.select("place_id, COUNT(id) as cnt").group(:place_id).having("COUNT(id) > 5").order("RANDOM()").limit(5).includes(:place).map {|r| r.place.name }
    suggestions = []

    first = types.shift
    count = Relic.search(:q1 => first).total_count
    suggestions[0] = [first, count]

    first = places.shift
    count = Relic.search(:q1 => first).total_count
    suggestions[2] = [first, count]

    types.each do |type|
      places.each do |place|
        q = type + " " + place
        count = Relic.search(:q1 => q).total_count
        if count > 0
          suggestions[1] = [q, count]
          break
        end
      end
    end

    suggestions.map do |label, count|
      link_to "#{label} <span>(#{count})</span>".html_safe, relics_path(:q1 => label)
    end.join(", ").html_safe
  end

  def link_to_facet obj, location, deep, &block
    name, id  = obj['term'].split('_')
    selected  = location[deep] == id
    label     = "#{name} <span>#{obj['count']}</span>".html_safe
    link      = link_to label, relics_path(search_params.merge(:location => (location.first(deep) << id).join('-')))
    output = []
    if selected
      output << content_tag(:div, :class => 'selected') do
        if location.size == (deep + 1)
          content_tag(:p, label)
        else
          link
        end
      end
    else
      output <<  link
    end
    if selected and block_given?
      output.join.html_safe + capture(&block)
    else
      output.join.html_safe
    end
  end

end
