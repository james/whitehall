class WorldLocation < ActiveRecord::Base
  has_many :edition_world_locations
  has_many :editions,
            through: :edition_world_locations
  has_many :published_edition_world_locations,
            class_name: "EditionWorldLocation",
            include: :edition,
            conditions: { editions: { state: "published" } }
  has_many :published_editions,
            through: :published_edition_world_locations,
            source: :edition
  has_many :published_documents,
            through: :published_editions,
            source: :document
  has_many :worldwide_organisation_world_locations, dependent: :destroy
  has_many :worldwide_organisations, through: :worldwide_organisation_world_locations

  has_many :world_location_mainstream_links,
            dependent: :destroy
  has_many :mainstream_links,
            through: :world_location_mainstream_links,
            dependent: :destroy
  has_many :feature_lists, as: :featurable, dependent: :destroy

  accepts_nested_attributes_for :edition_world_locations
  accepts_nested_attributes_for :mainstream_links, allow_destroy: true, reject_if: :all_blank

  include TranslatableModel
  translates :name, :title, :mission_statement

  include Searchable
  searchable title: :name,
             link: :search_link,
             content: :mission_statement,
             only: :active,
             format: 'world_location'

  include Rails.application.routes.url_helpers
  def search_link
    world_location_path(slug)
  end

  after_update :remove_from_index_if_became_inactive
  def remove_from_index_if_became_inactive
    remove_from_search_index if self.active_changed? && !self.active
  end

  scope :ordered_by_name, ->() { with_translations(I18n.default_locale).order(:name) }

  def self.active
    where(active: true)
  end

  def self.with_announcements
    joins(:editions).where("editions.type" => Announcement.sti_names,
                           "editions.state" => "published"
                          ).select("DISTINCT world_locations.*")
  end

  def self.with_publications
    joins(:editions).where("editions.type" => Publicationesque.sti_names,
                           "editions.state" => "published"
                          ).select("DISTINCT world_locations.*")
  end

  def world_location_type
    WorldLocationType.find_by_id(world_location_type_id)
  end

  def world_location_type=(new_world_location_type)
    self.world_location_type_id = new_world_location_type && new_world_location_type.id
  end

  def feature_list_for_locale(locale)
    feature_lists.find_by_locale(locale) || feature_lists.build(locale: locale)
  end

  def display_type
    world_location_type.name
  end

  def display_type_key
    world_location_type.key
  end

  def self.all_by_type
    ordered_by_name.group_by(&:world_location_type).sort_by { |type, location| type.sort_order }
  end

  def self.countries
    where(world_location_type_id: WorldLocationType::WorldLocation.id).ordered_by_name
  end

  def self.geographical
    where(world_location_type_id: WorldLocationType.geographic.map(&:id)).ordered_by_name
  end

  validates_with SafeHtmlValidator
  validates :name, :world_location_type_id, presence: true

  extend FriendlyId
  friendly_id
end
