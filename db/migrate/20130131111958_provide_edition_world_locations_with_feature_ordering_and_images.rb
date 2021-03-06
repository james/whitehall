class ProvideEditionWorldLocationsWithFeatureOrderingAndImages < ActiveRecord::Migration
  def change
    # NOTE: once we add the fields below, the existing featured items
    # aren't valid anymore.  At time of writing there were 5 so it seems
    # ok to remove them.
    execute('DELETE from edition_world_locations WHERE featured = true')

    create_table :edition_world_location_image_data, force: true do |t|
      t.string   :carrierwave_image
      t.timestamps
    end

    change_table :edition_world_locations do |t|
      t.integer  :ordering
      t.integer  :edition_world_location_image_data_id
      t.string   :alt_text
    end

    # NOTE: default index names generated by rails are too long, hence
    # the explicit names here.
    add_index :edition_world_locations, [:edition_id, :world_location_id], name: 'idx_edition_world_locations_on_edition_and_world_location_ids', unique: true
    add_index :edition_world_locations, [:edition_world_location_image_data_id], name: 'idx_edition_world_locs_on_edition_world_location_image_data_id'
  end
end
