#!/usr/bin/env ruby
# Simple script to test if ActionCable is functioning correctly
# Usage: rails runner scripts/test_actioncable.rb CHANNEL_NAME

# Configure logging to display in console
Rails.logger = Logger.new($stdout)
Rails.logger.level = Logger::INFO

# Get channel name from arguments or use a test channel
channel_name = ARGV.first || "test_channel"

puts "="*80
puts "📡 ACTION CABLE DIAGNOSTIC TEST"
puts "="*80
puts "• Testing channel: #{channel_name}"
puts "• Time: #{Time.current}"
puts

# Check ActionCable configuration
begin
  if defined?(ActionCable)
    puts "✅ ActionCable is defined"

    if defined?(ActionCable.server)
      puts "✅ ActionCable.server is defined"

      if defined?(ActionCable.server.pubsub)
        puts "✅ ActionCable.server.pubsub is defined"
        puts "  - Implementation: #{ActionCable.server.pubsub.class.name}"
      else
        puts "❌ ActionCable.server.pubsub is not defined"
      end
    else
      puts "❌ ActionCable.server is not defined"
    end
  else
    puts "❌ ActionCable is not defined"
  end
rescue => e
  puts "❌ Error checking ActionCable configuration: #{e.message}"
end

puts

# Check Turbo configuration
begin
  if defined?(Turbo)
    puts "✅ Turbo is defined"

    if defined?(Turbo::StreamsChannel)
      puts "✅ Turbo::StreamsChannel is defined"
    else
      puts "❌ Turbo::StreamsChannel is not defined"
    end
  else
    puts "❌ Turbo is not defined"
  end
rescue => e
  puts "❌ Error checking Turbo configuration: #{e.message}"
end

puts

# Try sending a message through ActionCable
puts "📤 Testing broadcast..."
begin
  # Prepare test message
  test_message = {
    time: Time.current.strftime("%H:%M:%S"),
    message: "This is a test broadcast",
    timestamp: Time.current.to_i
  }

  # Broadcast through ActionCable directly
  puts "• Broadcasting to #{channel_name} using ActionCable.server.broadcast..."
  ActionCable.server.broadcast(channel_name, test_message)
  puts "✅ ActionCable broadcast sent"

  # Broadcast through Turbo::StreamsChannel if available
  if defined?(Turbo::StreamsChannel)
    puts "• Broadcasting to #{channel_name} using Turbo::StreamsChannel.broadcast_append_to..."
    html = "<div id='test_#{Time.current.to_i}'>Test message sent at #{Time.current.strftime('%H:%M:%S')}</div>"
    Turbo::StreamsChannel.broadcast_append_to(channel_name, target: "messages", html: html)
    puts "✅ Turbo::StreamsChannel broadcast sent"
  end

  puts "✅ Broadcasts completed successfully"
rescue => e
  puts "❌ Error broadcasting test message: #{e.message}"
  puts e.backtrace.join("\n")
end

puts
puts "="*80
puts "To verify these broadcasts, check your browser console or create a subscription to channel '#{channel_name}'"
puts "="*80
