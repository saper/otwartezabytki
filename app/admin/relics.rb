# encoding: utf-8

ActiveAdmin.register Relic do
  menu :label => "Zabytki", :parent => "Zasoby", :priority => 1

  controller.authorize_resource

  filter :identification
  filter :group

  filter :voivodeship, :input_html => { :class => "select2", :style => "width: 241px" }, :label => "Województwo"
  filter :district, :input_html => { :class => "select2", :style => "width: 241px" }, :label => "Powiat"
  filter :commune, :input_html => { :class => "select2", :style => "width: 241px" }, :label => "Miejscowość"

  index do
    column :register_number
    column :voivodeship
    column :district
    column :commune
    column :identification
    default_actions
  end

  form do |f|
    f.inputs do
      f.input :identification, :as => :string
      f.input :description
      f.input :place_id
      f.input :group
      f.input :number
      f.input :materail
      f.input :dating_of_obj
      f.input :street
      f.input :register_number, :as => :string
      f.input :nid_id
      f.input :latitude
      f.input :longitude
      f.input :ancestry
      f.input :kind
      f.input :approved
      f.input :categories, :as => :check_boxes,
              :collection => Category.all.invert, :label => "",
              :input_html => { :multiple => true }
      f.input :tags, :input_html => { :value => relic.tags.join(','), :style => "width: 680px", :multiple => true }
      f.input :country_code
      f.input :fprovince
      f.input :fplace
      f.input :documents_info
      f.input :links_info
      f.input :group

      f.buttons
    end

  end

  action_item :only => :show do
    link_to t('buttons.show_history'), history_admin_relic_path(resource)
  end

  action_item :only => :show  do
    unless resource.live?
      link_to t('buttons.revert_this_version'), revert_admin_relic_path(resource, :version => params[:version]),
        :method => :put, :data => { :confirm => t('messages.are_you_sure') }
    end
  end

  controller do
    def show
      @relic = Relic.find(params[:id])

      if params[:version]
        @relic = @relic.versions.where(:id => params[:version]).last.reify
      end

      super
    end
  end
end
