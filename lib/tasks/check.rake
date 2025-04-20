namespace :check do
  desc "Run tests, Rubocop autocorrect, and Brakeman security scan"
  task all: :environment do
    puts "\n---> Running tests..."
    system("bin/rails test")
    unless $?.success?
      puts "\n[FAIL] Tests failed. Aborting check."
      exit(1)
    end

    puts "\n---> Running Rubocop autocorrect..."
    system("bundle exec rubocop -a")
    unless $?.success?
      puts "\n[WARN] Rubocop failed or had issues. Continuing check..."
      # Decide if Rubocop failure should abort. For now, we continue.
    end

    puts "\n---> Running Brakeman security scan..."
    system("bin/brakeman")
    unless $?.success?
      puts "\n[FAIL] Brakeman scan failed or found critical issues. Aborting check."
      exit(1) # Exit with non-zero status if Brakeman fails
    end

    puts "\n---> Check completed successfully."
  end
end

# Optional: Make `check:all` the default when running `rails check`
desc "Alias for check:all"
task check: [ "check:all" ]
