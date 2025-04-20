# frozen_string_literal: true

# This service handles broadcasting rubric state changes to the UI
# It's responsible for updating the DOM via Turbo Streams when a rubric's status changes
class Rubric::BroadcasterService
  attr_reader :rubric

  # Initialize with a rubric
  # @param rubric [Rubric] The rubric to broadcast
  def initialize(rubric)
    @rubric = rubric.reload
  end

  # Broadcast the current state of the rubric to update the UI
  # @param template [String] Optional alternative template path
  # @return [Boolean] Whether the broadcast was successful
  def broadcast(template = nil)
    Rails.logger.info("\n================================================")
    Rails.logger.info(" RUBRIC BROADCASTER SERVICE DETAILED DIAGNOSTIC  ")
    Rails.logger.info("================================================")
    Rails.logger.info("🔄 Broadcasting rubric #{rubric.id} state change to UI")
    Rails.logger.info("📊 Rubric status: #{rubric.status}, display_status: #{rubric.display_status}")
    Rails.logger.info("📡 Broadcasting to channel: #{channel_name}")
    Rails.logger.info("🎯 Targeting container: #{container_dom_id}")
    Rails.logger.info("🎯 Targeting status badge: #{status_badge_dom_id}")
    Rails.logger.info("🔍 Checking ActionCable configuration...")

    # Verify ActionCable is functioning
    begin
      actioncable_running = defined?(ActionCable) && ActionCable.server.pubsub
      Rails.logger.info("✅ ActionCable server available: #{actioncable_running}")

      # Check if Turbo is configured
      turbo_configured = defined?(Turbo::StreamsChannel)
      Rails.logger.info("✅ Turbo::StreamsChannel available: #{turbo_configured}")
    rescue => e
      Rails.logger.error("❌ Error checking ActionCable: #{e.message}")
    end

    begin
      # First broadcast a debug message to tell us what's happening
      broadcast_debug_message("Starting broadcast for rubric #{rubric.id} - status: #{rubric.status}")

      if template
        # Use a custom template for broadcasting
        Rails.logger.info("🧩 Using custom template: #{template}")

        # Try broadcasting with custom template
        Rails.logger.info("📡 Broadcasting with custom template using Turbo::StreamsChannel.broadcast_render_to...")
        response = Turbo::StreamsChannel.broadcast_render_to(
          channel_name,
          template: template,
          locals: { rubric: rubric }
        )
        Rails.logger.info("📤 Custom template broadcast result: #{response.inspect}")
      else
        # Update the rubric container in the UI
        Rails.logger.info("📡 Broadcasting replace to container...")
        response1 = broadcast_replace_to(
          target: container_dom_id,
          partial: "grading_tasks/rubric_card",
          locals: {
            rubric: rubric
          }
        )
        Rails.logger.info("📤 Container broadcast result: #{response1.inspect}")

        # Also update any status badges that show the rubric status
        Rails.logger.info("📡 Broadcasting replace to status badge...")
        response2 = broadcast_replace_to(
          target: status_badge_dom_id,
          partial: "shared/status_badge",
          locals: {
            status: rubric.display_status,
            size: "sm",
            hide_processing_spinner: false
          }
        )
        Rails.logger.info("📤 Status badge broadcast result: #{response2.inspect}")
      end

      # Broadcast a final debug message
      broadcast_debug_message("Completed broadcast for rubric #{rubric.id}")

      Rails.logger.info("Broadcast complete")
      true
    rescue StandardError => e
      Rails.logger.error("Failed to broadcast rubric update: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      false
    end
  end

  # Class method to broadcast a rubric update
  # @param rubric [Rubric] The rubric to broadcast
  # @param template [String] Optional alternative template path
  # @return [Boolean] Whether the broadcast was successful
  def self.broadcast(rubric, template = nil)
    new(rubric).broadcast(template)
  end

  private

  # Special debug method to broadcast a console message
  # @param message [String] The message to broadcast
  def broadcast_debug_message(message)
    Rails.logger.info("Broadcasting debug message: #{message}")

    # Create a safe JavaScript message that will show in the browser console
    js_code = "console.log('TURBO DEBUG: #{message.gsub("'", "\\'")}');"

    # Send as an append operation to not disrupt other streams
    Turbo::StreamsChannel.broadcast_append_to(
      channel_name,
      target: "rubric_container_#{rubric.id}",
      html: "<div style='display:none' data-debug='true'><script>#{js_code}</script></div>"
    )
  end

  # Helper to broadcast a replace operation to the Turbo Stream
  # @param target [String] The DOM ID to target
  # @param partial [String] The partial to render
  # @param locals [Hash] Local variables for the partial
  def broadcast_replace_to(target:, partial:, locals: {})
    Rails.logger.info("Broadcasting replace to target: #{target}, partial: #{partial}")
    Turbo::StreamsChannel.broadcast_replace_to(
      channel_name,
      target: target,
      partial: partial,
      locals: locals
    )
  end

  # Get the Turbo Stream channel name for this rubric
  # @return [String] The channel name
  def channel_name
    "rubric_#{rubric.id}"
  end

  # Get the DOM ID for the rubric container
  # @return [String] The DOM ID
  def container_dom_id
    "rubric_container_#{rubric.id}"
  end

  # Get the DOM ID for the rubric status badge
  # @return [String] The DOM ID
  def status_badge_dom_id
    "rubric_status_badge_#{rubric.id}"
  end
end
