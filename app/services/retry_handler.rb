# frozen_string_literal: true

# Handles retrying operations that may fail temporarily
class RetryHandler
  def self.with_retry(error_class: ApiOverloadError, max_retries: 1, base_delay: 1)
    retry_count = 0

    begin
      yield
    rescue error_class => e
      if retry_count < max_retries
        delay = base_delay * (2 ** retry_count)
        retry_count += 1
        Rails.logger.info("Retrying after #{delay} seconds (attempt #{retry_count}/#{max_retries})")
        sleep delay
        retry
      else
        Rails.logger.error("Max retries (#{max_retries}) exceeded for #{error_class.name}")
        raise e
      end
    end
  end
end
