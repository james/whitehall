module Whitehall::DocumentFilter
  class Filterer
    attr_reader :page, :per_page, :direction, :date, :keywords, :people_ids
    class << self
      attr_accessor :number_of_documents_per_page
    end
    self.number_of_documents_per_page = 20

    def initialize(params = {})
      @params = params
      @per_page = params[:per_page] || Whitehall::DocumentFilter::Filterer.number_of_documents_per_page
      @page = params[:page]
      @direction = params[:direction]
      @date = parse_date(@params[:date]) if @params[:date].present?
      @keywords = params[:keywords]
      @people_ids = @params[:people_id]
    end

    def selected_topics
      find_by_slug(Topic, @params[:topics])
    end

    def selected_organisations
      find_by_slug(Organisation, @params[:departments])
    end

    def selected_publication_filter_option
      filter_option = @params[:publication_filter_option] || @params[:publication_type]
      Whitehall::PublicationFilterOption.find_by_slug(filter_option)
    end

    def selected_announcement_type_option
      filter_option = @params[:announcement_type_option] || @params[:announcement_type]
      Whitehall::AnnouncementFilterOption.find_by_slug(filter_option)
    end

    def selected_consultation_type_option
      @params[:consultation_type_option] unless @params[:consultation_type_option] == "all"
    end

    def selected_people_option
      @people_ids
    end

    def selected_locations
      if @params[:locations].present? && @params[:locations] != ["all"]
        @params[:locations].reject! {|l| l == "all"}
        WorldLocation.find_all_by_slug(@params[:locations])
      else
        []
      end
    end

    def keywords
      if @keywords.present?
        @keywords.strip.split(/\s+/)
      else
        []
      end
    end

    def relevant_to_local_government
      @params[:relevant_to_local_government].present? && @params[:relevant_to_local_government].to_s == '1'
    end

    private

    def find_by_slug(klass, slugs)
      @selected ||= {}
      @selected[klass] ||= if slugs.present? && !slugs.include?("all")
        klass.where(slug: slugs)
      else
        []
      end
    end

    def parse_date(date)
      Date.parse(date)
      rescue ArgumentError => e
        if e.message[/invalid date/]
          return nil
        else
          raise e
      end
    end
  end
end