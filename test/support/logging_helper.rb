# frozen_string_literal: true

module LoggingHelper
  def initialize(*args)
    super
    @log_entries = []
  end

  def setup
    super
    @log_entries = []
    @test_logger = ActiveSupport::Logger.new(StringIO.new)
    that = self
    @test_logger.formatter = ->(severity, time, progname, msg) {
      that.instance_variable_get(:@log_entries) << msg if msg.is_a?(Hash)
    }
    Rails.logger = @test_logger
  end

  def teardown
    # Don't reset to STDOUT in test environment to keep logs quiet
    Rails.logger = ActiveSupport::Logger.new(STDOUT) unless Rails.env.test?
    super
  end

  private

  def fetch_last_log_entry
    @log_entries.last
  end

  def assert_logged(message:, **fields)
    log_entry = fetch_last_log_entry
    assert_not_nil log_entry, "No log entry found"
    assert_equal message, log_entry[:message], "Wrong message"
    fields.each do |key, value|
      if value.is_a?(StandardError)
        assert_equal value.message, log_entry[:error], "Wrong error message"
      else
        assert_equal value, log_entry[key], "Wrong #{key}"
      end
    end
  end
end
