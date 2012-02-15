require "test_helper"

class CountryTest < ActiveSupport::TestCase
  test "should be valid when built from the factory" do
    country = build(:country)
    assert country.valid?
  end

  test "should be invalid without a name" do
    country = build(:country, name: nil)
    refute country.valid?
  end

  test 'should set a slug from the country name' do
    country = create(:country, name: 'Costa Rica')
    assert_equal 'costa-rica', country.slug
  end

  test 'should not change the slug when the country name is changed' do
    country = create(:country, name: 'New Holland')
    country.update_attributes(name: 'Australia')
    assert_equal 'new-holland', country.slug
  end

  test 'should not be featured' do
    country = create(:country, name: 'Cascadia')
    refute country.featured?
  end

  test 'should be featured if name matches hard-coded list' do
    %w[ Spain USA Uganda ].each do |name|
      assert create(:country, name: name).featured?
    end
  end

  test 'should return featured countries' do
    %w[ Spain USA Uganda Cascadia Virginia ].each do |name|
      create(:country, name: name)
    end
    assert_equal 3, Country.featured.length
  end
end
