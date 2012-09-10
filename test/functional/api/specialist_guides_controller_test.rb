require 'test_helper'

class Api::SpecialistGuidesControllerTest < ActionController::TestCase
  disable_database_queries
  should_be_a_public_facing_controller

  test "show responds with JSON representation of found guide" do
    specialist_guide = stub_edition(:specialist_guide)
    SpecialistGuide.stubs(:published_as).with(specialist_guide.slug).returns(specialist_guide)
    presenter = Api::SpecialistGuidePresenter.decorate(specialist_guide)
    presenter.stubs(:as_json).returns(json: :representation)
    Api::SpecialistGuidePresenter.stubs(:new).with(specialist_guide).returns(presenter)

    get :show, id: specialist_guide.slug, format: 'json'
    assert_equal ActiveSupport::JSON.encode(json: :representation), response.body
  end

  test "show responds with 404 if published guide not found" do
    SpecialistGuide.stubs(:published_as).returns(nil)
    get :show, id: 'unknown'
    assert_response :not_found
  end

  test "index paginates published specialist guides" do
    presenter = Api::SpecialistGuidePresenter::PagePresenter.new([])
    presenter.stubs(:as_json).returns(paged: :representation)
    Api::SpecialistGuidePresenter.stubs(:paginate).with(SpecialistGuide.published.alphabetical).returns(presenter)

    get :index, format: 'json'

    assert_equal ActiveSupport::JSON.encode(paged: :representation), response.body
  end
end