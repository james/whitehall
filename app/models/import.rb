require 'logger'

class Import < ActiveRecord::Base
  serialize :import_errors
  serialize :already_imported
  serialize :successful_rows
  has_many :document_sources

  belongs_to :creator, class_name: "User"

  TYPES = {
    consultation: [Whitehall::Uploader::ConsultationRow, Consultation],
    news_article: [Whitehall::Uploader::NewsArticleRow, NewsArticle],
    publication: [Whitehall::Uploader::PublicationRow, Publication],
    speech: [Whitehall::Uploader::SpeechRow, Speech],
    statistical_data_set: [Whitehall::Uploader::StatisticalDataSetRow, StatisticalDataSet]
  }

  validates :csv_data, presence: true
  validates :data_type, inclusion: { in: TYPES.keys.map(&:to_s), message: "%{value} is not a valid type" }
  validate :valid_csv_headings?

  def self.create_from_file(current_user, csv_file, data_type)
    Import.create(
      data_type: data_type,
      csv_data: csv_file.read,
      creator_id: current_user.id,
      original_filename: csv_file.original_filename,
      import_errors: [],
      already_imported: [],
      successful_rows: [],
      log: ""
    )
  end

  def enqueue!
    Delayed::Job.enqueue(Job.new(self.id))
  end

  def status
    if import_started_at.nil?
      :queued
    elsif import_finished_at.nil?
      :running
    elsif import_errors.any?
      :failed
    else
      :succeeded
    end
  end

  def perform(options = {})
    attachment_cache = options[:attachment_cache] || Whitehall::Uploader::AttachmentCache.new(Whitehall::Uploader::AttachmentCache.default_root_directory, logger)
    progress_logger = options[:progress_logger] || ProgressLogger.new(self)

    progress_logger.start(rows)
    rows.each_with_index do |data_row, ix|
      row_number = ix + 2
      row = row_class.new(data_row.to_hash, row_number, attachment_cache, logger)
      if DocumentSource.find_by_url(row.legacy_url)
        progress_logger.already_imported(row_number, row.legacy_url)
      else
        import_row(row, row_number, creator, progress_logger)
      end
    end
    progress_logger.finish
  end

  def import_row(row, row_number, creator, progress_logger)
    attributes = row.attributes.merge(creator: creator)
    model = model_class.new(attributes)
    if model.save
      ds = DocumentSource.create!(document: model.document, url: row.legacy_url, import: self, row_number: row_number)
      progress_logger.success(row_number, model)
    else
      model.errors.full_messages.each do |error_message|
        progress_logger.error(row_number, error_message)
      end
      attachment_errors = model.attachments.reject(&:valid?).each do |a|
        progress_logger.error(row_number, "Attachment '#{a.attachment_source.url}' error: #{a.errors.full_messages.to_s}")
      end
    end
  rescue => e
    progress_logger.error(row_number, e.to_s + "\n" + e.backtrace.join("\n"))
  end

  def logger
    @logger ||= Logger.new(ImportLogIo.new(self))
  end

  def rows
    @rows ||= CSV.parse(csv_data, headers: true, header_converters: :downcase)
  end

  def row_class
    data_type && TYPES[data_type.to_sym] && TYPES[data_type.to_sym][0]
  end

  def model_class
    data_type && TYPES[data_type.to_sym] && TYPES[data_type.to_sym][1]
  end

  def valid_csv_headings?
    return unless row_class && csv_data
    heading_validation_errors = row_class.heading_validation_errors(rows.headers)
    heading_validation_errors.each do |e|
      errors.add(:csv_data, e)
    end
  end

  class ImportLogIo
    def initialize(import)
      @import = import
    end

    def write(data)
      log = @import.log || ""
      log << data
      @import.update_column(:log, log)
    end

    def close
    end
  end

  class ProgressLogger
    def initialize(import)
      @import = import
    end

    def start(rows)
      @import.update_column(:total_rows, rows.size)
      @import.update_column(:import_started_at, Time.zone.now)
    end

    def finish
      @import.update_column(:import_finished_at, Time.zone.now)
    end

    def error(row_number, error_message)
      @import.import_errors ||= []
      @import.import_errors << {row_number: row_number, message: error_message}
      @import.save
    end

    def success(row_number, model_object)
      @import.update_column(:current_row, row_number)
    end

    def already_imported(row_number, url)
      @import.already_imported ||= []
      @import.already_imported << {row_number: row_number, url: url}
      @import.save
    end
  end

  class Job < Struct.new(:id)
    def perform
      import.perform
    end

    def error(delayed_job, error)
      puts error.to_s + error.backtrace.join("\n")
      import.logger.error(error.to_s + error.backtrace.join("\n"))
    end

  private
    def import
      @import ||= Import.find(self.id)
    end
  end
end