# -*- encoding : utf-8 -*-
class RelicsController < ApplicationController
  expose(:relics) do
    p1 = params.merge(:corrected_relic_ids => current_user.try(:corrected_relic_ids))
    if p1[:corrected_relic_ids].blank?
      Rails.cache.fetch(uniq_cache_key, :expires_in => 15.minutes) do
        Relic.search p1.slice(:q1, :page, :location)
      end
    else
      Relic.search(p1)
    end
  end
  expose(:suggestion) { Suggestion.new(:relic_id => params[:id]) }
  expose(:relic) do
    if id = params[:relic_id] || params[:id]
      Relic.find(id).tap do |r|
        r.attributes = params[:relic] unless request.get?
      end
    else
      Relic.new(params[:relic])
    end
  end

  helper_method :search_params, :location_breadcrumbs, :need_captcha

  before_filter :current_user!, :only => [:edit, :create, :update, :gonext, :thank_you]

  def show
    redirect_to edit_relic_path(params[:id]) and return
  end

  def index
    SearchTerm.store(params[:q1])
    session[:search_params] = params.slice(:q1, :location)
    gon.highlighted_tags = relics.highlighted_tags

    idx = relics.results.index {|r| r.corrected?(current_user) }
    if idx
      @pending, @corrected = relics.take(idx), relics.drop(idx)
    else
      @pending, @corrected = relics, []
    end
  end

  def edit

    if current_user && current_user.suggestions.roots.where(:relic_id => params[:id], :skipped => false).count > 0
      redirect_to thank_you_relic_path(params[:id]), :notice => "Już poprawiłeś ten zabytek, dziękujemy!" and return
    end

    if relic.suggestions.not_skipped.count >= 3
      redirect_to corrected_relic_path(params[:id]), :notice => "Ten zabytek został już przejrzany. Zapraszamy za miesiąc." and return
    end

    suggestion.fill_subrelics
  end

  def update

    suggestion.user_id = current_user.id
    suggestion.ip_address = request.remote_ip
    suggestion.attributes = params[:suggestion]

    if need_captcha
      if verify_recaptcha(:model => suggestion, :timeout => 30)
        Rails.cache.delete("need_captcha_#{request.remote_ip}")
      else
        render "edit_captcha" and return
      end
    end

    if suggestion.save
      if suggestion.is_skipped?
        redirect_to [:gonext, suggestion.relic]
      else
        redirect_to [:thank_you, suggestion.relic]
      end
    else
      flash[:error] = suggestion.errors.full_messages
      render "edit"
    end

  end

  def gonext
    current_user.mark_relic_as_seen(params[:id])
    redirect_to [:edit, ensure_not_seen_relic]
  end

  def thank_you
    if current_user && current_user.suggestions.count >= 3 && current_user.email.blank?
      @request_email = true
    end

    @next_relic = ensure_not_seen_relic
  end

  def corrected
    @next_relics = Relic.next_few_for(current_user, search_params[:search_params], 3)
  end

  def suggester
    query = params[:q1].to_s.strip
    render :json => [] and return unless query.present?

    cached_json = Rails.cache.fetch(uniq_cache_key("suggester"), :expires_in => 1.day) do
      results = Relic.suggester(query)
      navigators_json = []
      navigators_json << {
        :label => "cała Polska (#{results.total_count})",
        :value => query,
        :path  => relics_path(search_params)
      } unless results.total_count.zero?

      results.terms('voivodeships', false, true).each do |hash|
        obj = hash['obj']
        navigators_json << {
          :label => "<strong>#{query}</strong> - woj. #{obj.name} (#{hash['count']})",
          :value => query,
          :path  => relics_path(search_params.merge(:location => obj.id))
        }
      end if results.terms('districts').size > 1

      results.terms('districts', false, true).each do |hash|
        obj = hash['obj']
        navigators_json << {
          :label => "<strong>#{query}</strong> - woj. #{obj.voivodeship.name}, pow. #{obj.name} (#{hash['count']})",
          :value => query,
          :path  => relics_path(search_params.merge(:location => [obj.voivodeship_id, obj.id].join('-')))
        }
      end if results.terms('communes').size > 1

      results.terms('communes', false, true).each do |hash|
        obj = hash['obj']
        navigators_json << {
          :label => "<strong>#{query}</strong> - woj. #{obj.district.voivodeship.name}, pow. #{obj.district.name}, gm. #{obj.name} (#{hash['count']})",
          :value => query,
          :path  => relics_path(search_params.merge(:location => [obj.district.voivodeship_id, obj.district_id, obj.id].join('-')))
        }
      end if results.terms('places').size > 1

      results.terms('places', false, true).each do |hash|
        obj = hash['obj']
        navigators_json << {
          :label => "<strong>#{query}</strong> - #{obj.name}, woj. #{obj.commune.district.voivodeship.name}, pow. #{obj.commune.district.name}, gm. #{obj.commune.name} (#{hash['count']})",
          :value => query,
          :path  => relics_path(search_params.merge(:location => [obj.commune.district.voivodeship_id, obj.commune.district_id, obj.commune_id, obj.id].join('-')))
        }
      end
      navigators_json
    end
    render :json => cached_json
  end

  def download
    file_path = Rails.root.join('public', 'system', 'relics_history.csv')

    if File.exists?(file_path)
      @export_url = '/system/relics_history.csv'
      @export_date = File.atime(file_path)
      @export_size = (File.size(file_path) / 1024.0 / 1024.0).round(2)
    end
  end

  protected
    def ensure_not_seen_relic
      possible_next = Relic.next_for(current_user, session[:search_params])
      if current_user.seen_relic_ids.include?(possible_next.id.to_i)
        location = session[:search_params][:location].to_s.split('-').map {|l| l.split(':') }
        location = relic.get_parent_ids if location.blank?

        conds = Hash[
          [:voivodeship_id, :district_id, :commune_id, :place_id].zip(location)
        ].inject({}) { |mem, (k, v)| mem[k] = v if v; mem }

        next_relic = Relic.next_random_in(conds)
        next_relic = Relic.next_random_in(conds.slice(:voivodeship_id, :district_id, :commune_id)) if current_user.seen_relic_ids.include?(next_relic.id)
        next_relic = Relic.next_random_in(conds.slice(:voivodeship_id, :district_id)) if current_user.seen_relic_ids.include?(next_relic.id)
        next_relic = Relic.next_random_in(conds.slice(:voivodeship_id)) if current_user.seen_relic_ids.include?(next_relic.id)
        next_relic = Relic.next_random_in({}) if current_user.seen_relic_ids.include?(next_relic.id)
        session[:search_params] = { :q1 => nil, :location => location.map{|l| l.instance_of?(Array) ? l.join(':') : l }.join('-') }
        next_relic
      else
        possible_next
      end
    end

    def uniq_cache_key namespace = nil
      sliced_params = params[:q1].to_s.split.sort + params.slice(:page, :location).values
      cache_key =  (Digest::SHA1.new << sliced_params.compact.join(' ')).to_s
      if cache_key.blank?
        "blank-search-query"
      elsif namespace
        "#{namespace}-#{cache_key}"
      else
        cache_key
      end
    end

    def search_params
      params.slice(:q1)
    end

    def location_breadcrumbs
      return @location_breadcrumbs if defined? @location_breadcrumbs
      @location_breadcrumbs = [ {:path => relics_path(search_params), :label => 'Cała Polska'} ]
      klasses = [Voivodeship, District, Commune, Place]
      location_arry = params[:location].to_s.split('-')

      location_arry.each_with_index do |id,i|
        l = Rails.cache.fetch("#{klasses[i].to_s.downcase}_#{id}", :expires_in => 1.day) do
          klasses[i].find(id.split(':').first)
        end
        @location_breadcrumbs << {:path => relics_path(search_params.merge(:location =>location_arry.first(i+1).join('-'))), :label => l.name }
      end if location_arry.present?
      @location_breadcrumbs
    end

  private

    def need_captcha
      if Rails.cache.read("need_captcha_#{request.remote_ip}")
        Rails.logger.info("Require captcha because of cache value for #{request.remote_ip}")
        return true
      end
      suggestion_count = Suggestion.roots.not_skipped.where(:ip_address => request.remote_ip).where('created_at >= ?', 1.minute.ago).count
      # puts "Suggestion count: #{suggestion_count}"
      if suggestion_count > 60
        Rails.cache.write("need_captcha_#{request.remote_ip}", 1)
        true
      else
        false
      end
    end

end
