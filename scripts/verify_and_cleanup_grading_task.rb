#!/usr/bin/env ruby
# frozen_string_literal: true

# This script verifies the most recently created grading task and its associated records,
# then cleans up the data by deleting it.
#
# Usage:
#   rails runner scripts/verify_and_cleanup_grading_task.rb
#

require File.expand_path('../../config/environment', __FILE__)

class GradingTaskVerifier
  attr_reader :grading_task, :success

  def initialize
    @grading_task = find_most_recent_grading_task
    @success = false
    @issues = []
  end

  def verify_and_cleanup
    if @grading_task.nil?
      puts "No grading task found."
      return
    end

    puts "\n=== Verifying Grading Task ===\n"
    puts "ID: #{@grading_task.id} (#{@grading_task.prefix_id})"
    puts "Status: #{@grading_task.status_label}"
    puts "Created at: #{@grading_task.created_at}"
    puts "Feedback tone: #{@grading_task.feedback_tone}"
    puts "User ID: #{@grading_task.user_id}"

    verify_associations
    display_detailed_information

    if @issues.any?
      puts "\n❌ Verification failed with the following issues:"
      @issues.each { |issue| puts "  - #{issue}" }

      puts "\nSkipping cleanup due to verification failure."
    else
      @success = true
      puts "\n✅ Verification successful!"

      if confirm_cleanup
        perform_cleanup
        puts "\n🧹 Cleanup completed successfully."
      else
        puts "\nCleanup cancelled."
      end
    end
  end

  private

  def find_most_recent_grading_task
    task = GradingTask.order(created_at: :desc).first
    unless task
      puts "No grading tasks found in the database."
      return nil
    end

    puts "Using most recent grading task (created #{task.created_at.strftime('%Y-%m-%d %H:%M:%S')})"
    task
  end

  def verify_associations
    verify_association("Rubric", @grading_task.rubric)
    verify_association("Assignment Prompt", @grading_task.assignment_prompt)

    # Check for RawRubric if Rubric exists
    if @grading_task.rubric && @grading_task.rubric.respond_to?(:raw_rubric)
      verify_association("Raw Rubric", @grading_task.rubric.raw_rubric)
    end

    doc_selections = @grading_task.document_selections
    verify_count("Document Selections", doc_selections)

    student_submissions = @grading_task.student_submissions
    verify_count("Student Submissions", student_submissions)

    # Verify document selection fields
    if doc_selections.any?
      sample = doc_selections.first
      verify_field("Document ID", sample.document_id)
      verify_field("Document Name", sample.name)
      verify_field("Document URL", sample.url)
    end
  end

  def display_detailed_information
    puts "\n=== Detailed Information ===\n"

    # Display Rubric details
    if @grading_task.rubric
      rubric = @grading_task.rubric
      puts "\nRubric (ID: #{rubric.id}):"
      puts "  Title: #{rubric.title}"
      puts "  Total Points: #{rubric.total_points}"
      puts "  Status: #{rubric.status}"
      puts "  Created at: #{rubric.created_at}"

      # Display RawRubric details if it exists
      if rubric.respond_to?(:raw_rubric) && rubric.raw_rubric
        raw_rubric = rubric.raw_rubric
        puts "\nRaw Rubric (ID: #{raw_rubric.id}):"
        puts "  Created at: #{raw_rubric.created_at}"
        if raw_rubric.respond_to?(:raw_text)
          puts "  Raw Text: #{raw_rubric.raw_text.to_s[0...100]}#{raw_rubric.raw_text.to_s.length > 100 ? '...' : ''}"
        end
      end
    end

    # Display Assignment Prompt details
    if @grading_task.assignment_prompt
      ap = @grading_task.assignment_prompt
      puts "\nAssignment Prompt (ID: #{ap.id}):"
      puts "  Title: #{ap.title}"
      puts "  Subject: #{ap.subject}"
      puts "  Grade Level: #{ap.grade_level}"
      puts "  Word Count: #{ap.word_count}"
      puts "  Due Date: #{ap.due_date || 'Not set'}"
      puts "  Content: #{ap.content ? ap.content.to_s[0...100] : 'Not set'}"
    end

    # Display Document Selections
    puts "\nDocument Selections:"
    @grading_task.document_selections.each_with_index do |doc, index|
      puts "  #{index + 1}. #{doc.name} (ID: #{doc.id})"
      puts "     Document ID: #{doc.document_id}"
      puts "     URL: #{doc.url}"
    end

    # Display Student Submissions
    puts "\nStudent Submissions:"
    @grading_task.student_submissions.each_with_index do |sub, index|
      puts "  #{index + 1}. ID: #{sub.id} (Document: #{sub.document_selection_id})"
      puts "     Status: #{sub.status}"
      puts "     Created at: #{sub.created_at}"
    end
  end

  def verify_association(name, association)
    if association.nil?
      @issues << "Missing #{name}"
      puts "❌ #{name}: Missing"
    else
      puts "✓ #{name}: Present (ID: #{association.id})"
    end
  end

  def verify_count(name, collection)
    count = collection.count
    if count.zero?
      @issues << "No #{name} found"
      puts "❌ #{name}: None found"
    else
      puts "✓ #{name}: #{count} found"
    end
  end

  def verify_field(name, value)
    if value.blank?
      @issues << "#{name} is blank"
      puts "❌ #{name}: Blank"
    else
      puts "✓ #{name}: #{value.to_s.truncate(50)}"
    end
  end

  def confirm_cleanup
    print "\nDo you want to delete this grading task and all associated records? (y/n) "
    STDOUT.flush
    response = STDIN.gets.chomp.downcase
    response == 'y' || response == 'yes'
  end

  def perform_cleanup
    puts "\nDeleting grading task and associated records..."

    # Store IDs before deletion for reporting
    grading_task_id = @grading_task.id
    assignment_prompt_id = @grading_task.assignment_prompt&.id
    rubric_id = @grading_task.rubric&.id
    rubric = @grading_task.rubric # Save reference to rubric before deletion
    raw_rubric_id = rubric&.respond_to?(:raw_rubric) ? rubric.raw_rubric&.id : nil
    doc_selection_count = @grading_task.document_selections.count
    student_submission_count = @grading_task.student_submissions.count

    begin
      ActiveRecord::Base.transaction do
        # Delete the grading task (should cascade to associated records except rubric)
        @grading_task.destroy

        # Explicitly delete the rubric if it exists
        if rubric
          # The raw_rubric should be deleted when the rubric is deleted if there's a dependent: :destroy
          # But we'll check afterward to make sure
          rubric.destroy

          # Verify rubric deletion
          if Rubric.exists?(rubric_id)
            puts "❌ Warning: Failed to delete Rubric ID: #{rubric_id}"
          end

          # Verify raw_rubric deletion if it existed
          if raw_rubric_id && defined?(RawRubric) && RawRubric.exists?(raw_rubric_id)
            puts "❌ Warning: Failed to delete Raw Rubric ID: #{raw_rubric_id}"
            # Try to manually delete it
            RawRubric.find(raw_rubric_id).destroy rescue nil
          end
        end

        # Report what was deleted
        puts "Deleted Grading Task ID: #{grading_task_id}"
        puts "Deleted Assignment Prompt ID: #{assignment_prompt_id}" if assignment_prompt_id
        puts "Deleted Rubric ID: #{rubric_id}" if rubric_id
        puts "Deleted Raw Rubric ID: #{raw_rubric_id}" if raw_rubric_id
        puts "Deleted #{doc_selection_count} Document Selection(s)"
        puts "Deleted #{student_submission_count} Student Submission(s)"

        # Verify deletion
        raise "Failed to delete grading task" if GradingTask.exists?(grading_task_id)
      end
    rescue => e
      puts "❌ Error during cleanup: #{e.message}"
      raise e
    end
  end
end

# Run the verification and cleanup process
verifier = GradingTaskVerifier.new
verifier.verify_and_cleanup

exit(verifier.success ? 0 : 1)
