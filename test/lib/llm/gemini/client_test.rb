# frozen_string_literal: true

require "test_helper"
require "webmock/minitest" # Required for stubbing HTTP requests
require "llm/gemini/client"
require "llm/errors"
# require "llm_request" # Removed - test_helper loads Rails env

module LLM
  module Gemini
    class ClientTest < ActiveSupport::TestCase
      # Include WebMock assertions
      include WebMock::API
      WebMock.enable!

      setup do
        @api_key = "test-api-key"
        ENV["GOOGLE_AI_KEY"] = @api_key

        @client = Client.new

        # Use one of the newly added models for testing
        @test_model_key = "gemini-2.0-flash"
        @mapped_model_id = Client::MODEL_MAPPING[@test_model_key] # models/gemini-2.0-flash

        # Standard LLMRequest for most tests
        @llm_request = LLMRequest.new(
          prompt: "Why is the sky blue?",
          llm_model_name: @test_model_key,
          temperature: 0.7,
          max_tokens: 150,
          top_p: 0.9,
          request_type: "test_generation"
        )

        @base_url = Client::BASE_URL
        @generate_endpoint = "#{@base_url}#{@mapped_model_id}:generateContent?key=#{@api_key}"
        # Count tokens endpoint uses the model name without 'models/' prefix
        @count_tokens_endpoint = "#{@base_url}models/#{@test_model_key}:countTokens?key=#{@api_key}"

        # Ensure no real HTTP requests are made
        WebMock.disable_net_connect!(allow_localhost: true)

        # Setup default stubs needed for all tests
        # Always stub token count for the standard test LLMRequest
        # This is critical since BaseClient calls calculate_token_count before execute_request
        token_count_request_body = {
          contents: [{ role: "user", parts: [{ text: @llm_request.prompt }] }]
        }.to_json
        
        stub_gemini_request(
          endpoint: @count_tokens_endpoint,
          request_body: token_count_request_body,
          response_status: 200,
          response_body: { totalTokens: 5 }
        )
        
        # Also provide a generic fallback stub for any other token count requests
        # with a lower precedence than the specific stub above
        stub_request(:post, /.*:countTokens/).with(headers: { 'Content-Type' => 'application/json' })
          .to_return(status: 200, body: { totalTokens: 10 }.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      teardown do
        ENV.delete("GOOGLE_AI_KEY")
        WebMock.reset!
        WebMock.allow_net_connect!
      end

      # --- Helper Methods ---

      def stub_gemini_request(endpoint:, request_body:, response_status:, response_body:)
        # Support both string bodies, procs, and hashes for the request body
        body_matcher = if request_body.is_a?(Proc)
          request_body
        elsif request_body.is_a?(String)
          request_body
        else
          ->(body) { body == request_body }
        end

        # Handle response body format
        body_response = if response_body.is_a?(String)
          response_body
        else
          response_body.to_json
        end

        # Create the request stub with correct matcher and headers
        stub_request(:post, endpoint)
          .with(
            headers: { 
              'Accept' => '*/*', 
              'Accept-Encoding' => /.*/, 
              'Content-Type' => 'application/json', 
              'User-Agent' => 'GradeBot/1.0 (LLM::Gemini::Client)' 
            },
            body: body_matcher
          )
          .to_return(
            status: response_status,
            body: body_response,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      # --- generate Tests ---

      test "#generate successfully calls API and returns formatted response" do
        # Setup
        response_body = {
          candidates: [
            {
              content: {
                parts: [
                  { text: "The sky is blue due to Rayleigh scattering." }
                ],
                role: "model"
              },
              finishReason: "STOP",
              index: 0,
              safetyRatings: [
                { category: "HARM_CATEGORY_SEXUALLY_EXPLICIT", probability: "NEGLIGIBLE" },
                { category: "HARM_CATEGORY_HATE_SPEECH", probability: "NEGLIGIBLE" },
                { category: "HARM_CATEGORY_HARASSMENT", probability: "NEGLIGIBLE" },
                { category: "HARM_CATEGORY_DANGEROUS_CONTENT", probability: "NEGLIGIBLE" }
              ]
            }
          ],
          usageMetadata: { promptTokenCount: 5, candidatesTokenCount: 9, totalTokenCount: 14 }
        }

        # Expected request body with all required parameters
        expected_request_body = {
          contents: [{ role: "user", parts: [{ text: @llm_request.prompt }] }],
          generationConfig: {
            temperature: @llm_request.temperature,
            maxOutputTokens: @llm_request.max_tokens,
            topP: @llm_request.top_p
          },
          safetySettings: Client::DEFAULT_SAFETY_SETTINGS
        }

        # Stub the generate request with exact body matching
        stub_gemini_request(
          endpoint: @generate_endpoint,
          request_body: expected_request_body.to_json,
          response_status: 200,
          response_body: response_body
        )

        # Exercise
        result = @client.generate(@llm_request)

        # Verify
        assert_equal "The sky is blue due to Rayleigh scattering.", result[:content]
        assert_includes result[:metadata].keys, :tokens
        assert_includes result[:metadata].keys, :model
        assert_includes result[:metadata].keys, :raw_response
        assert_equal 14, result[:metadata][:tokens][:total]
        assert_requested :post, @generate_endpoint, times: 1
      end

      test "#generate handles API error 400 (Bad Request)" do
        # Setup - expected request with full parameters
        expected_request_body = {
          contents: [{ role: "user", parts: [{ text: @llm_request.prompt }] }],
          generationConfig: {
            temperature: @llm_request.temperature,
            maxOutputTokens: @llm_request.max_tokens,
            topP: @llm_request.top_p
          },
          safetySettings: Client::DEFAULT_SAFETY_SETTINGS
        }
        
        # Stub the actual API error response
        stub_gemini_request(
          endpoint: @generate_endpoint,
          request_body: expected_request_body.to_json, # Exact request body matching
          response_status: 400,
          response_body: { error: { message: "Invalid request", status: "INVALID_ARGUMENT" } }
        )

        # Exercise & Verify
        exception = assert_raises(LLM::Errors::ApiError) do
          @client.generate(@llm_request)
        end
        
        # Verify error message and status code
        assert_match(/Gemini API Error \(400\): Invalid request/, exception.message)
        assert_equal 400, exception.status_code
      end

      test "#generate handles API error 429 (Rate Limit)" do
        # Setup - expected request with full parameters
        expected_request_body = {
          contents: [{ role: "user", parts: [{ text: @llm_request.prompt }] }],
          generationConfig: {
            temperature: @llm_request.temperature,
            maxOutputTokens: @llm_request.max_tokens,
            topP: @llm_request.top_p
          },
          safetySettings: Client::DEFAULT_SAFETY_SETTINGS
        }
        
        # Stub the rate limit error response
        stub_gemini_request(
          endpoint: @generate_endpoint,
          request_body: expected_request_body.to_json, # Exact request body matching
          response_status: 429,
          response_body: { error: { message: "Rate limit exceeded", status: "RESOURCE_EXHAUSTED" } }
        )

        # Exercise & Verify
        exception = assert_raises(LLM::Errors::ApiOverloadError) do
          @client.generate(@llm_request)
        end
        
        # Verify error details
        assert_match(/Rate limit exceeded/, exception.message)
        assert_equal 429, exception.status_code
      end

      test "#generate handles API error 500 (Server Error)" do
        # Setup - using @llm_request defined in setup
        
        # First stub the token count endpoint with a success response
        stub_request(:post, @count_tokens_endpoint)
          .with(
            headers: { 
              'Content-Type' => 'application/json'
            },
            query: { key: @api_key },
            body: ->(body) { JSON.parse(body).has_key?("contents") }
          )
          .to_return(
            status: 200,
            body: { totalTokenCount: 14 }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
        
        # Then stub the generate endpoint with a 500 error
        stub_request(:post, @generate_endpoint)
          .with(
            headers: { 'Content-Type' => 'application/json' },
            query: { key: @api_key },
            body: ->(body) { JSON.parse(body).to_s.include?(@llm_request.prompt) }
          )
          .to_return(
            status: 500,
            body: { error: { message: "Internal server error", status: "INTERNAL" } }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        # Exercise & Verify
        exception = assert_raises(LLM::Errors::ApiError) do
          @client.generate(@llm_request)
        end
        
        # Verify error details
        assert_match(/Gemini API Error \(500\): Internal server error/, exception.message)
        assert_equal 500, exception.status_code
      end

      test "#generate handles JSON parsing error" do
        # Setup - expected request with full parameters
        expected_request_body = {
          contents: [{ role: "user", parts: [{ text: @llm_request.prompt }] }],
          generationConfig: {
            temperature: @llm_request.temperature,
            maxOutputTokens: @llm_request.max_tokens,
            topP: @llm_request.top_p
          },
          safetySettings: Client::DEFAULT_SAFETY_SETTINGS
        }
        
        # Stub invalid JSON response
        stub_gemini_request(
          endpoint: @generate_endpoint,
          request_body: expected_request_body.to_json, # Exact request body matching
          response_status: 200,
          response_body: "this is not valid JSON"
        )

        # Exercise & Verify
        exception = assert_raises(LLM::Errors::ApiError) do
          @client.generate(@llm_request)
        end
        
        # Verify proper error message
        assert_match(/Failed to parse Gemini API response/, exception.message)
      end

      test "#generate raises configuration error if API key is missing" do
        ENV.delete("GOOGLE_AI_KEY")
        client = Client.new # Re-initialize without API key

        exception = assert_raises(LLM::Errors::ConfigurationError) do
          client.generate(@llm_request)
        end
        assert_equal "GOOGLE_AI_KEY is not set.", exception.message
      end
      
      test "#generate raises error for unsupported model" do
        unsupported_request = LLMRequest.new(
          prompt: "test", 
          llm_model_name: "gemini-ancient", 
          request_type: "test"
        )
        exception = assert_raises(LLM::Errors::UnsupportedModelError) do
          @client.generate(unsupported_request)
        end
        assert_match(/Unsupported\/Unknown Gemini model: 'gemini-ancient'/, exception.message)
      end

      # --- calculate_token_count Tests ---

      test "#calculate_token_count successfully calls API and returns count" do
        # Setup - Create a test request for token counting
        count_request = LLMRequest.new(
          prompt: "Count these tokens",
          llm_model_name: @test_model_key
        )

        # Stub the token count API with specific success response
        stub_gemini_request(
          endpoint: @count_tokens_endpoint,
          request_body: { contents: [ { role: "user", parts: [ { text: count_request.prompt } ] } ] }.to_json,
          response_status: 200,
          response_body: { totalTokens: 3 }
        )

        # Exercise & Verify
        token_count = @client.calculate_token_count(count_request)
        assert_equal 3, token_count
        assert_requested :post, @count_tokens_endpoint, times: 1
      end

       test "#calculate_token_count handles API error 400" do
        # Setup
        error_request = LLMRequest.new(prompt: "test prompt", llm_model_name: @test_model_key)

        # Stub token count API with 400 error
        stub_gemini_request(
          endpoint: @count_tokens_endpoint,
          request_body: { contents: [ { role: "user", parts: [ { text: error_request.prompt } ] } ] }.to_json,
          response_status: 400,
          response_body: { error: { message: "Bad request", status: "INVALID_ARGUMENT" } }
        )

        # Exercise & Verify
        exception = assert_raises(LLM::Errors::ApiError) do
          @client.calculate_token_count(error_request)
        end
        assert_match(/Failed to calculate Gemini token count/, exception.message)
        assert_match(/Bad request/, exception.message)
        assert_equal 400, exception.status_code
      end

       test "#calculate_token_count handles JSON parsing error" do
        # Setup
        json_error_request = LLMRequest.new(prompt: "test prompt", llm_model_name: @test_model_key)

        # Stub token count API with invalid JSON response
        stub_gemini_request(
          endpoint: @count_tokens_endpoint,
          request_body: { contents: [ { role: "user", parts: [ { text: json_error_request.prompt } ] } ] }.to_json,
          response_status: 200,
          response_body: "this is not valid JSON"
        )

        # Exercise & Verify
        exception = assert_raises(LLM::Errors::ApiError) do
          @client.calculate_token_count(json_error_request)
        end
        
        # Verify correct error message
        assert_match(/Failed to parse Gemini/, exception.message)
      end

      test "#calculate_token_count raises configuration error if API key is missing" do
        # Setup
        original_key = ENV.delete("GOOGLE_AI_KEY") # Clear ENV var and store original
        client_without_key = Client.new # Create client AFTER clearing ENV var

        config_error_request = LLMRequest.new(
          prompt: "This requires API key",
          llm_model_name: @test_model_key
        )

        # Exercise & Verify
        exception = assert_raises(LLM::Errors::ConfigurationError) do
          client_without_key.calculate_token_count(config_error_request)
        end
        assert_match(/GOOGLE_AI_KEY is not set/, exception.message)
      ensure
        ENV["GOOGLE_AI_KEY"] = original_key if original_key # Restore original key
      end

       test "#calculate_token_count raises error for unsupported model" do
         unsupported_model = "gemini-ancient"
         # Create LLMRequest for the unsupported model
         unsupported_request = LLMRequest.new(
           prompt: "test prompt",
           llm_model_name: unsupported_model
         )

         exception = assert_raises(LLM::Errors::UnsupportedModelError) do
           @client.calculate_token_count(unsupported_request) # Pass LLMRequest object
         end
         assert_match(/Unsupported\/Unknown Gemini model: '#{unsupported_model}'/, exception.message)
       end

    end
  end
end
