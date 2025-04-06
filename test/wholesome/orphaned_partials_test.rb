require "test_helper"

class OrphanedPartialsTest < ActionDispatch::IntegrationTest
  test "all partials should be rendered at least once" do
    # Get all partial files (files that start with _)
    partial_files = Dir.glob(Rails.root.join("app", "views", "**", "_*.erb")).map do |file|
      file.sub(Rails.root.join("app", "views").to_s + "/", "")
    end

    # Get all searchable files
    searchable_files = []

    # All view files (including partials)
    searchable_files += Dir.glob(Rails.root.join("app", "views", "**", "*.erb"))

    # JavaScript files
    searchable_files += Dir.glob(Rails.root.join("app", "javascript", "**", "*.js"))

    # Controller files
    searchable_files += Dir.glob(Rails.root.join("app", "controllers", "**", "*.rb"))

    # Helper files
    searchable_files += Dir.glob(Rails.root.join("app", "helpers", "**", "*.rb"))

    # Component files
    searchable_files += Dir.glob(Rails.root.join("app", "components", "**", "*.rb"))

    # Read all content into one big string
    all_content = searchable_files.map { |file| File.read(file) }.join("\n")

    # Track which partials are rendered
    rendered_partials = {}
    partial_files.each do |partial|
      # Get just the partial name without the leading underscore and extensions
      partial_name = File.basename(partial, ".html.erb")[1..-1]
      # Get the full path without the leading underscore
      full_path = partial.sub(/\/_/, "/")
      # Remove the extension
      full_path = full_path.sub(/\.html\.erb$/, "")

      # Look for either the full path or just the name
      rendered_partials[partial] = all_content.include?(full_path) || all_content.include?(partial_name)
    end

    # Get list of orphaned partials
    orphaned_partials = rendered_partials.select { |_, rendered| !rendered }.keys

    # Fail test with an informative message if orphaned partials exist
    assert orphaned_partials.empty?,
           "The following partials are not rendered in any view: \n#{orphaned_partials.join("\n")}"
  end
end
