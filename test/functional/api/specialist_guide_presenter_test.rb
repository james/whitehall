require 'test_helper'

class Api::SpecialistGuidePresenterTest < PresenterTestCase
  setup do
    @guide = stub_edition(:specialist_guide)
    @guide.stubs(:organisations).returns([])
    @guide.stubs(:published_related_specialist_guides).returns([])
    @presenter = Api::SpecialistGuidePresenter.decorate(@guide)
  end

  test ".paginate returns a decorated page of results" do
    stubs_helper_method(:params).returns(page: 1)
    page = stub('page')
    decorated_results = stub('decorated-results')
    Api::SpecialistGuidePresenter::Paginator.stubs(:paginate).with([@guide], page: 1).returns(page)
    Api::SpecialistGuidePresenter.stubs(:decorate).with(page).returns(decorated_results)
    assert_equal Api::SpecialistGuidePresenter.paginate([@guide]), Api::SpecialistGuidePresenter::PagePresenter.new(decorated_results)
  end

  test "json includes document title" do
    @guide.stubs(:title).returns('guide-title')
    assert_equal 'guide-title', @presenter.as_json[:title]
  end

  test "json includes the main guide url as web_url" do
    assert_equal specialist_guide_url(@guide.document), @presenter.as_json[:web_url]
  end

  test "json includes the document body as html" do
    stubs_helper_method(:govspeak_edition_to_html).with(@guide).returns('html-body')
    assert_equal 'html-body', @presenter.as_json[:details][:body]
  end

  test "json includes related specialist guides as related artefacts" do
    related_guide = stub_edition(:specialist_guide)
    @guide.stubs(:published_related_specialist_guides).returns([related_guide])
    guide_json = {
      title: related_guide.title,
      web_url: specialist_guide_url(related_guide.document)
    }
    assert_equal [guide_json], @presenter.as_json[:related_artefacts]
  end
end

class Api::SpecialistGuidePresenter::PagePresenterTest < PresenterTestCase
  setup do
    stubs_helper_method(:params).returns(action: "index", controller: "api/specialist_guides")
    @first_result = "a"
    @second_result = "b"
    @page = Kaminari.paginate_array([@first_result, @second_result]).page(1).per(10)
    @page.stubs(last_page?: false, first_page?: false, current_page: 2)
    @presenter = Api::SpecialistGuidePresenter::PagePresenter.new(@page)
  end

  test "json includes each result in page" do
    @first_result.stubs(:as_json).returns({first: :result})
    @second_result.stubs(:as_json).returns({second: :result})
    assert_equal [{first: :result}, {second: :result}], @presenter.as_json[:results]
  end

  test "json includes next page url if next page available" do
    @page.stubs(:last_page?).returns(false)
    assert_equal api_specialist_guides_url(page: 3), @presenter.as_json[:next_page_url]
  end

  test "json excludes next page url if no next page" do
    @page.stubs(:last_page?).returns(true)
    assert_nil @presenter.as_json[:next_page_url]
  end

  test "json includes previous page url if next page available" do
    @page.stubs(:first_page?).returns(false)
    assert_equal api_specialist_guides_url(page: 1), @presenter.as_json[:previous_page_url]
  end

  test "json excludes previous page url if no next page" do
    @page.stubs(:first_page?).returns(true)
    assert_nil @presenter.as_json[:previous_page_url]
  end
end