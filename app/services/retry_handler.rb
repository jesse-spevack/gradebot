# frozen_string_literal: true

# Handles retrying operations that may fail temporarily
class RetryHandler
  def self.with_retry(error_class: ApiOverloadError, max_retries: 3, base_delay: 1)
    retry_count = 0

    begin
      yield
    rescue error_class => e
      if retry_count < max_retries
        # Use retry_after from the error if available, otherwise calculate exponential backoff
        if e.respond_to?(:retry_after) && e.retry_after
          delay = e.retry_after
          Rails.logger.info("Retrying after #{delay} seconds as specified by API (attempt #{retry_count + 1}/#{max_retries})")
        else
          delay = base_delay * (2 ** retry_count)
          Rails.logger.info("Retrying after #{delay} seconds (attempt #{retry_count + 1}/#{max_retries})")
        end

        retry_count += 1
        sleep delay
        retry
      else
        Rails.logger.error("Max retries (#{max_retries}) exceeded for #{error_class.name}")
        raise e
      end
    end
  end
end
