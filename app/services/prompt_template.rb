class PromptTemplate
  class TemplateNotFoundError < StandardError; end

  # Base path for templates
  TEMPLATE_PATH = Rails.root.join("app", "views", "prompts")

  def self.render(template_name, variables = {})
    template_path = find_template(template_name)

    # Read the template content
    template_content = File.read(template_path)

    # Create a binding with the variables
    context = OpenStruct.new(variables).instance_eval { binding }

    # Render the ERB template with the variables
    ERB.new(template_content, trim_mode: "-").result(context)
  end

  def self.find_template(template_name)
    # Try to find the template with different extensions
    %w[.txt.erb .erb .txt].each do |ext|
      path = TEMPLATE_PATH.join("#{template_name}#{ext}")
      return path if File.exist?(path)
    end

    # If we get here, the template was not found
    raise TemplateNotFoundError, "Could not find template: #{template_name}"
  end

  # Helper method to escape special characters in template content
  def self.escape_special_chars(text)
    return "" unless text

    # Replace line breaks, quotes, and other special characters
    text.to_s
      .gsub("\\", "\\\\")  # Escape backslashes
      .gsub('"', '\\"')    # Escape double quotes
  end
end
