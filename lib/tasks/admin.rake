# frozen_string_literal: true

namespace :admin do
  desc "Set admin flag for user with email from ADMIN_EMAIL environment variable"
  task seed: :environment do
    admin_email = ENV["ADMIN_EMAIL"]

    raise "ADMIN_EMAIL environment variable must be set" if admin_email.blank?

    user = User.find_by(email: admin_email)
    raise "User with email '#{admin_email}' not found" unless user

    if user.admin?
      puts "User '#{admin_email}' is already an admin" unless Rails.env.test?
    else
      user.update!(admin: true)
      puts "User '#{admin_email}' has been granted admin privileges" unless Rails.env.test?
    end
  end
end
