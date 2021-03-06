# encoding: utf-8

require 'test_helper'

class DocumentHelperTest < ActionView::TestCase
  test "#edition_organisation_class returns the slug of the first organisation of the edition" do
    organisations = [create(:organisation), create(:organisation)]
    edition = create(:edition, organisations: organisations)
    assert_equal organisations.first.slug, edition_organisation_class(edition)
  end

  test '#edition_organisation_class returns "no_organisation" if doc has no organisation' do
    edition = build(:edition)
    edition.organisations = []
    assert_equal 'unknown_organisation', edition_organisation_class(edition)
  end

  test "should generate a national statistics logo for a national statistic" do
    publication = create(:publication, publication_type_id: PublicationType::NationalStatistics.id)
    assert_match /National Statistic/, national_statistics_logo(publication)
  end

  test "should generate no national statistics logo for an edition that is not a national statistic" do
    publication = create(:publication)
    refute_match /National Statistic/, national_statistics_logo(publication)
  end

  test "should generate list of links to inapplicable nations with alternative URL" do
    publication = create(:publication, nation_inapplicabilities: [create(:nation_inapplicability, nation: Nation.scotland, alternative_url: "http://scotland.com")])
    html = list_of_links_to_inapplicable_nations(publication.nation_inapplicabilities)
    assert_select_within_html html, "a[href='http://scotland.com']", text: "Scotland"
  end

  test "should generate list of inapplicable nations without alternative URL" do
    publication = create(:publication, nation_inapplicabilities: [create(:nation_inapplicability, nation: Nation.wales, alternative_url: nil)])
    assert_equal "Wales", list_of_links_to_inapplicable_nations(publication.nation_inapplicabilities)
  end

  test "#see_alternative_urls_for_inapplicable_nations lists names and links if any alternative urls exist" do
    publication = create(:publication, nation_inapplicabilities: [create(:nation_inapplicability, nation: Nation.scotland, alternative_url: "http://scotland.com")])
    html = see_alternative_urls_for_inapplicable_nations(publication)
    assert_select_within_html html, "a[href='http://scotland.com']", text: "Scotland"
    assert html.starts_with?(" (see publication for ")
  end

  test "#see_alternative_urls_for_inapplicable_nations skips nations without alternative urls" do
    publication = create(:publication, nation_inapplicabilities: [create(:nation_inapplicability, nation: Nation.scotland, alternative_url: "http://scotland.com"), create(:nation_inapplicability, nation: Nation.wales, alternative_url: "")])
    html = see_alternative_urls_for_inapplicable_nations(publication)
    refute_match /Wales/, html
  end

  test "#see_alternative_urls_for_inapplicable_nations returns nothing if no alternative urls exist" do
    publication = create(:publication)
    html = see_alternative_urls_for_inapplicable_nations(publication)
    assert_nil html
  end

  test "should return nil for humanized content type when file extension is nil" do
    assert_nil humanized_content_type(nil)
  end

  test "should return PDF Document for humanized content type" do
    assert_equal '<abbr title="Portable Document Format">PDF</abbr>', humanized_content_type("pdf")
    assert_equal '<abbr title="Portable Document Format">PDF</abbr>', humanized_content_type("PDF")
  end

  test "should return CSV Document for humanized content type" do
    assert_equal '<abbr title="Comma-separated Values">CSV</abbr>', humanized_content_type("csv")
  end

  test "should return RTF Document for humanized content type" do
    assert_equal '<abbr title="Rich Text Format">RTF</abbr>', humanized_content_type("rtf")
  end

  test "should return PNG Image for humanized content type" do
    assert_equal '<abbr title="Portable Network Graphic">PNG</abbr>', humanized_content_type("png")
  end

  test "should return JPEG Document for humanized content type" do
    assert_equal "JPEG", humanized_content_type("jpg")
  end

  test "should return MS Word Document for humanized content type" do
    assert_equal "MS Word Document", humanized_content_type("doc")
    assert_equal "MS Word Document", humanized_content_type("docx")
  end

  test "should return MS Excel Spreadsheet for humanized content type" do
    assert_equal "MS Excel Spreadsheet", humanized_content_type("xls")
    assert_equal "MS Excel Spreadsheet", humanized_content_type("xlsx")
  end

  test "should return MS Powerpoint Presentation for humanized content type" do
    assert_equal "MS Powerpoint Presentation", humanized_content_type("ppt")
    assert_equal "MS Powerpoint Presentation", humanized_content_type("pptx")
  end

  test "should return Zip archive for humanized content type" do
    assert_equal '<abbr title="Zip archive">ZIP</abbr>', humanized_content_type("zip")
  end

  test "should return native language name for locale" do
    assert_equal "English", native_language_name_for(:en)
    assert_equal "Español", native_language_name_for(:es)
  end
end
