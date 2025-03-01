# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module LLM
  module Anthropic
    # Client for interacting with Anthropic's Claude API
    #
    # This client provides methods to interact with Anthropic's Claude API,
    # allowing the application to send prompts and receive completions.
    #
    # @example Basic usage
    #   client = LLM::Anthropic::Client.new("claude-3-5-sonnet")
    #   response = client.generate(prompt: "Explain quantum computing")
    #   puts response[:content]
    #
    class Client < LLM::BaseClient
      API_BASE_URL = "https://api.anthropic.com".freeze
      API_VERSION = "2023-06-01".freeze
      DEFAULT_MAX_TOKENS = 1024

      # Cost per million tokens (in USD)
      PRICING = {
        "claude-3-7-sonnet-20250219" => { input: 15.00, output: 75.00 },
        "claude-3-5-sonnet-20241022" => { input: 8.00, output: 24.00 },
        "claude-3-5-haiku-20241022" => { input: 1.25, output: 3.75 },
        "claude-3-5-sonnet-20240620" => { input: 8.00, output: 24.00 },
        "claude-3-haiku-20240307" => { input: 1.25, output: 3.75 },
        "claude-3-opus-20240229" => { input: 15.00, output: 75.00 },
        "claude-3-sonnet-20240229" => { input: 8.00, output: 24.00 },
        "claude-2.1" => { input: 8.00, output: 24.00 },
        "claude-2.0" => { input: 8.00, output: 24.00 }
      }.freeze

      # Default pricing for models not explicitly listed
      DEFAULT_PRICING = { input: 8.00, output: 24.00 }.freeze

      attr_reader :model_name, :max_tokens, :temperature
      attr_accessor :api_key

      # Initialize a new Anthropic client
      #
      # @param model_name [String] the name of the model to use
      # @param options [Hash] additional options for the client
      # @option options [Integer] :max_tokens (1024) The maximum number of tokens to generate
      # @option options [Float] :temperature (0.7) The sampling temperature
      # @option options [String] :api_key (nil) Override the default API key
      def initialize(model_name, options = {})
        @model_name = model_name
        @max_tokens = options[:max_tokens] || DEFAULT_MAX_TOKENS
        @temperature = options[:temperature] || 0.7
        @api_key = options[:api_key] || fetch_api_key
      end

      # Execute a request to the Anthropic API
      #
      # @param input_object [Hash] The input for the LLM
      # @return [Hash] The response from the LLM
      def execute_request(input_object)
        # Extract prompt from input object
        prompt = input_object[:prompt]

        # Prepare request body
        request_body = {
          model: resolve_model_name(model_name),
          max_tokens: max_tokens,
          temperature: temperature,
          messages: [
            { role: "user", content: prompt }
          ]
        }

        # Make HTTP request
        uri = URI.parse("#{API_BASE_URL}/v1/messages")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Post.new(uri.path)
        request["Content-Type"] = "application/json"
        request["x-api-key"] = api_key
        request["anthropic-version"] = API_VERSION
        request.body = request_body.to_json

        response = http.request(request)

        # Handle response
        if response.code.to_i == 200
          parsed_response = JSON.parse(response.body, symbolize_names: true)

          # Extract content from response
          content = parsed_response[:content].first[:text]

          # Extract token usage
          input_tokens = parsed_response[:usage][:input_tokens]
          output_tokens = parsed_response[:usage][:output_tokens]
          total_tokens = input_tokens + output_tokens

          {
            content: content,
            metadata: {
              tokens: {
                prompt: input_tokens,
                completion: output_tokens,
                total: total_tokens
              },
              model: model_name,
              raw_response: parsed_response
            }
          }
        else
          # Handle error
          error_body = JSON.parse(response.body, symbolize_names: true) rescue { error: response.body }
          error_msg = error_body[:error][:message] rescue "Unknown API error"

          raise "Anthropic API error (#{response.code}): #{error_msg}"
        end
      end

      # Calculate the token count for an input
      #
      # @param input_object [Hash] The input to calculate tokens for
      # @return [Integer] The token count
      def calculate_token_count(input_object)
        # This is an approximation, as the exact token count would require Anthropic's tokenizer
        # A reasonable approximation is ~4 characters per token
        prompt = input_object[:prompt].to_s
        (prompt.length / 4.0).ceil
      end

      # Calculate the cost estimate based on token count
      #
      # @param token_count [Integer] The token count to calculate cost for
      # @return [Float] The estimated cost in USD
      def calculate_cost_estimate(token_count)
        # Get pricing for this model, or fallback to default
        resolved_model = resolve_model_name(model_name).to_s
        pricing = PRICING[resolved_model] || DEFAULT_PRICING

        # Since we don't know the input/output split at this point,
        # assume 30% input tokens and 70% output tokens
        input_tokens = (token_count * 0.3).ceil
        output_tokens = token_count - input_tokens

        # Calculate cost
        input_cost = (input_tokens / 1_000_000.0) * pricing[:input]
        output_cost = (output_tokens / 1_000_000.0) * pricing[:output]

        input_cost + output_cost
      end

      # Validate the API key by attempting a minimal API call
      #
      # @return [Boolean] true if the API key is valid
      def validate_api_key
        uri = URI.parse("#{API_BASE_URL}/v1/models")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Get.new(uri.path)
        request["x-api-key"] = api_key
        request["anthropic-version"] = API_VERSION

        response = http.request(request)
        response.code.to_i == 200
      rescue
        false
      end

      private

      # Fetch the API key from environment variables
      #
      # @return [String] The API key
      # @raise [RuntimeError] If the API key is not configured
      def fetch_api_key
        # Check common environment variable names for the API key
        if ENV["ANTHROPIC_API_KEY"].present?
          return ENV["ANTHROPIC_API_KEY"]
        elsif ENV["anthropic_api_key"].present?
          return ENV["anthropic_api_key"]
        end

        # If we get here, we couldn't find the API key
        raise "Anthropic API key not configured. Please set the ANTHROPIC_API_KEY environment variable."
      end

      # Resolve a generic model name to its fully specified version
      #
      # Maps generic model names like "claude-3-5-sonnet" to their latest
      # fully specified versions like "claude-3-5-sonnet-20241022"
      #
      # @param generic_model_name [String] The generic model name
      # @return [String] The fully specified model name
      def resolve_model_name(generic_model_name)
        # Return as-is if it's already a fully specified model
        return generic_model_name if generic_model_name.to_s.match?(/\d{8}$/)

        # Map of generic models to their latest versions
        model_mappings = {
          "claude-3-7-sonnet" => "claude-3-7-sonnet-20250219",
          "claude-3-5-sonnet" => "claude-3-5-sonnet-20241022",
          "claude-3-5-haiku" => "claude-3-5-haiku-20241022",
          "claude-3-opus" => "claude-3-opus-20240229",
          "claude-3-sonnet" => "claude-3-sonnet-20240229",
          "claude-3-haiku" => "claude-3-haiku-20240307"
        }

        # Look up the fully specified version, or return the original if not found
        model_mappings[generic_model_name.to_s] || generic_model_name
      end
    end
  end
end
