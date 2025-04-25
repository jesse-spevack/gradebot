require "test_helper"

# Playwright setup lifted from:
# https://justin.searls.co/posts/running-rails-system-tests-with-playwright-instead-of-selenium/
Capybara.register_driver :my_playwright do |app|
  Capybara::Playwright::Driver.new(
    app,
    browser: ENV["PLAYWRIGHT_BROWSER"]&.to_sym || :chromium,
    headless: (false unless ENV["CI"] || ENV["PLAYWRIGHT_HEADLESS"])
  )
end

# Increase timeout for better stability
Capybara.default_max_wait_time = 15
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :my_playwright
end
