 # -*- encoding : utf-8 -*-
module Import
  class Multiarch
    include DataMapper::Resource
    storage_names[:default] = 'multiarch'

    property :id, Integer, :key => true
    property :typ_rekordu, String
    property :nr_podpodzespolu, Integer
    property :nr_podzespolu, Integer
    property :nr_w_podpodzespole, Integer
    property :nr_w_podzespole, Integer
    property :nr_w_zespole, Integer
    property :nr_zespolu, Integer, :key => true

    class << self

      def logger
        @logger ||= Logger.new("#{Rails.root}/log/#{Rails.env}_relics_import.log")
      end

      def import_from_xlsx
        headers = [
          "id",
          "typ_rekordu",
          "nr_podpodzespolu",
          "nr_podzespolu",
          "nr_w_podpodzespole",
          "nr_w_podzespole",
          "nr_w_zespole",
          "nr_zespolu"
        ]
        files = Dir.glob("#{Rails.root}/vendor/multiarch/*.xlsx")
        for file in files
          logger.info "Importing: #{file}"
          table = RemoteTable.new file
          table.rows.each do |row|
            attrs = Hash[headers.zip(row.values)]
            puts attrs.inspect
            Multiarch.create attrs
          end
        end
      end

      def import_ancestry
        Multiarch.all(:conditions => {:typ_rekordu => 'ZE'}).batch(1000) do |ze|
          logger.info "Importing ZE: #{ze.id}"
          ze.descendants.map do |child|
            begin
              child.relic.update_attributes :parent => ze.relic
            rescue => ex
              logger.error "cant' assign parent for: #{child.id}, error: #{ex.message}"
            end
          end
        end
      end
    end

    def relic
      ::Relic.find_by_nid_id(self.id.to_s)
    end

    # def parent
    #   return nil if ['ZE'].include? typ_rekordu
    #   Multiarch.first(:conditions => {:id.not => self.id, :typ_rekordu => ['ZZ', 'ZE'], :nr_zespolu => nr_zespolu})
    # end

    # def children
    #   return nil if ['OZ', 'SA'].include? typ_rekordu
    #   Multiarch.all(:conditions => {:id.not => [self.id, parent.try(:id)].compact, :nr_zespolu => nr_zespolu}, :order => [:nr_w_zespole, :nr_podzespolu, :nr_w_podzespole, :nr_podpodzespolu, :nr_w_podpodzespole])
    # end

    def descendants
      Multiarch.all(:conditions => {:id.not => self.id, :nr_zespolu => nr_zespolu}, :order => :nr_w_zespole)
    end

  end
end
