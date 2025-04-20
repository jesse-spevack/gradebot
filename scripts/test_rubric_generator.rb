# Test script for Rubric::GeneratorService
# Run with: rails runner scripts/test_rubric_generator.rb

# RubricTestHelper encapsulates logging, object tracking, and cleanup
class RubricTestHelper
  attr_reader :log, :created_objects, :timings

  def initialize
    @log = setup_logger
    @created_objects = {
      grading_task: nil,
      assignment_prompt: nil,
      rubric: nil,
      raw_rubric: nil,
      criteria: [],
      levels: [],
      kickoff_task: nil,
      kickoff_prompt: nil,
      kickoff_rubric: nil,
      kickoff_raw_rubric: nil
    }
    @timings = {}
  end

  def setup_logger
    logger = Logger.new(STDOUT)
    logger.level = Logger::INFO
    logger.formatter = proc do |severity, _, _, msg|
      "#{severity}: #{msg}\n"
    end
    logger
  end

  # Safely execute a block with error handling and timing
  def safely_execute(description)
    log.info(description)
    start_time = Time.now

    begin
      result = yield
      end_time = Time.now
      duration = (end_time - start_time).round(2)
      @timings[description] = duration
      log.info("#{description} completed in #{duration} seconds")
      result
    rescue StandardError => e
      end_time = Time.now
      duration = (end_time - start_time).round(2)
      @timings[description] = duration
      log.error("\nError in #{description} after #{duration} seconds:")
      log.error("#{e.class.name}: #{e.message}")
      log.error(e.backtrace[0..5].join("\n"))

      handle_specific_errors(e)
      false
    end
  end

  # Handle specific error types with custom diagnostics
  def handle_specific_errors(error)
    if error.message.include?("Position has already been taken")
      log.error("\nPosition conflict detected. Current positions:")

      if @created_objects[:rubric]
        Criterion.where(rubric_id: @created_objects[:rubric].id).each do |c|
          log.error("Criterion ID: #{c.id}, Position: #{c.position}, Title: #{c.title}")
        end

        Level.joins(:criterion).where(criteria: { rubric_id: @created_objects[:rubric].id }).each do |l|
          log.error("Level ID: #{l.id}, Criterion ID: #{l.criterion_id}, Position: #{l.position}, Title: #{l.title}")
        end
      end
    end
  end

  # Clean up any existing test objects that might conflict
  def cleanup_existing_objects
    safely_execute("Cleaning up any existing test objects...") do
      existing_grading_tasks = GradingTask.where(status: "created").where("created_at > ?", 1.day.ago)

      if existing_grading_tasks.any?
        log.info("Found #{existing_grading_tasks.count} existing test grading tasks to clean up")

        existing_grading_tasks.each do |gt|
          log.info("Cleaning up GradingTask ##{gt.id} and dependencies...")
          delete_grading_task_with_dependencies(gt)
        end
      else
        log.info("No existing test objects found to clean up")
      end
    end
  end

  # Deletes a grading task and all its related objects
  def delete_grading_task_with_dependencies(gt)
    # Get associated objects before deletion
    prompt = gt.assignment_prompt
    rubric = gt.rubric

    # Find and delete levels first (deepest dependency)
    if rubric
      log.info("  Finding criteria and levels for Rubric ##{rubric.id}")
      criteria = rubric.criteria

      criteria.each do |criterion|
        log.info("    Cleaning up Criterion ##{criterion.id} and its levels")
        criterion.levels.each do |level|
          log.info("      Deleting Level ##{level.id}")
          level.delete
        end
        log.info("    Deleting Criterion ##{criterion.id}")
        criterion.delete
      end

      # Delete raw rubric if it exists
      if raw_rubric = RawRubric.find_by(rubric_id: rubric.id)
        log.info("  Deleting RawRubric ##{raw_rubric.id}")
        raw_rubric.delete
      end
    end

    # Delete assignment prompt
    if prompt
      log.info("  Deleting AssignmentPrompt ##{prompt.id}")
      prompt.delete
    end

    # Delete grading task
    log.info("  Deleting GradingTask ##{gt.id}")
    gt.delete

    # Delete rubric last
    if rubric
      log.info("  Deleting Rubric ##{rubric.id}")
      rubric.delete
    end
  end

  # Clean up all test objects created during the test
  def cleanup_test_objects
    safely_execute("\nCleaning up test objects...") do
      ActiveRecord::Base.transaction do
        # Delete in reverse order of dependencies

        # Delete levels first
        @created_objects[:levels].each do |level|
          next unless level && level.persisted?
          log.info("Deleting Level ##{level.id}")
          level.delete
        end

        # Delete criteria
        @created_objects[:criteria].each do |criterion|
          next unless criterion && criterion.persisted?
          log.info("Deleting Criterion ##{criterion.id}")
          criterion.delete
        end

        # Clean up objects from KickOffService test if they exist
        if @created_objects[:kickoff_raw_rubric]
          log.info("Deleting KickOff RawRubric ##{@created_objects[:kickoff_raw_rubric].id}")
          @created_objects[:kickoff_raw_rubric].delete
        end

        if @created_objects[:kickoff_prompt]
          log.info("Deleting KickOff AssignmentPrompt ##{@created_objects[:kickoff_prompt].id}")
          @created_objects[:kickoff_prompt].delete
        end

        if @created_objects[:kickoff_task]
          log.info("Deleting KickOff GradingTask ##{@created_objects[:kickoff_task].id}")
          @created_objects[:kickoff_task].delete
        end

        if @created_objects[:kickoff_rubric]
          log.info("Deleting KickOff Rubric ##{@created_objects[:kickoff_rubric].id}")
          @created_objects[:kickoff_rubric].delete
        end

        # Delete raw rubric if it exists
        if @created_objects[:raw_rubric]
          log.info("Deleting RawRubric ##{@created_objects[:raw_rubric].id}")
          @created_objects[:raw_rubric].delete
        elsif raw_rubric = RawRubric.find_by(rubric_id: @created_objects[:rubric]&.id)
          log.info("Deleting RawRubric ##{raw_rubric.id}")
          raw_rubric.delete
        end

        # Delete assignment prompt
        if @created_objects[:assignment_prompt]
          log.info("Deleting AssignmentPrompt ##{@created_objects[:assignment_prompt].id}")
          @created_objects[:assignment_prompt].delete
        end

        # Delete grading task
        if @created_objects[:grading_task]
          log.info("Deleting GradingTask ##{@created_objects[:grading_task].id}")
          @created_objects[:grading_task].delete
        end

        # Delete rubric last
        if @created_objects[:rubric]
          log.info("Deleting Rubric ##{@created_objects[:rubric].id}")
          @created_objects[:rubric].delete
        end

        log.info("Cleanup completed successfully")
      end
    rescue StandardError => e
      log.error("\nError cleaning up test objects:")
      log.error("#{e.class.name}: #{e.message}")
      log.error(e.backtrace[0..5].join("\n"))

      # Try alternative cleanup strategy for foreign key errors
      try_alternative_cleanup if e.is_a?(ActiveRecord::InvalidForeignKey)
    end
  end

  # Alternative cleanup strategy when transactions fail
  def try_alternative_cleanup
    safely_execute("\nAttempting alternative cleanup strategy...") do
      # Use SQL to disable foreign key checks temporarily
      ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = OFF;")

      # Try deleting objects again
      [ @created_objects[:levels], @created_objects[:criteria] ].flatten.compact.each do |obj|
        next unless obj.persisted?
        log.info("Deleting #{obj.class.name} ##{obj.id}")
        obj.class.where(id: obj.id).delete_all
      end

      # Delete remaining objects
      [ @created_objects[:raw_rubric], @created_objects[:assignment_prompt],
       @created_objects[:grading_task], @created_objects[:rubric],
       @created_objects[:kickoff_raw_rubric], @created_objects[:kickoff_prompt],
       @created_objects[:kickoff_task], @created_objects[:kickoff_rubric] ].compact.each do |obj|
        next unless obj.persisted?
        log.info("Deleting #{obj.class.name} ##{obj.id}")
        obj.class.where(id: obj.id).delete_all
      end

      # Re-enable foreign key checks
      ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = ON;")

      log.info("Alternative cleanup completed")
    end
  end

  # Verify all test objects were properly cleaned up
  def verify_cleanup
    safely_execute("\nVerifying cleanup - current database state:") do
      all_cleaned_up = true

      # Check if any of our test objects still exist
      if @created_objects[:rubric] && Rubric.exists?(@created_objects[:rubric].id)
        log.warn("Rubric ##{@created_objects[:rubric].id} still exists")
        all_cleaned_up = false
      end

      if @created_objects[:grading_task] && GradingTask.exists?(@created_objects[:grading_task].id)
        log.warn("GradingTask ##{@created_objects[:grading_task].id} still exists")
        all_cleaned_up = false
      end

      if @created_objects[:assignment_prompt] && AssignmentPrompt.exists?(@created_objects[:assignment_prompt].id)
        log.warn("AssignmentPrompt ##{@created_objects[:assignment_prompt].id} still exists")
        all_cleaned_up = false
      end

      # Check KickOffService objects
      if @created_objects[:kickoff_rubric] && Rubric.exists?(@created_objects[:kickoff_rubric].id)
        log.warn("KickOff Rubric ##{@created_objects[:kickoff_rubric].id} still exists")
        all_cleaned_up = false
      end

      if @created_objects[:kickoff_task] && GradingTask.exists?(@created_objects[:kickoff_task].id)
        log.warn("KickOff GradingTask ##{@created_objects[:kickoff_task].id} still exists")
        all_cleaned_up = false
      end

      if @created_objects[:kickoff_prompt] && AssignmentPrompt.exists?(@created_objects[:kickoff_prompt].id)
        log.warn("KickOff AssignmentPrompt ##{@created_objects[:kickoff_prompt].id} still exists")
        all_cleaned_up = false
      end

      criteria_exist = @created_objects[:criteria].any? { |c| c && Criterion.exists?(c.id) }
      levels_exist = @created_objects[:levels].any? { |l| l && Level.exists?(l.id) }

      if criteria_exist
        log.warn("Some criteria still exist")
        all_cleaned_up = false
      end

      if levels_exist
        log.warn("Some levels still exist")
        all_cleaned_up = false
      end

      if all_cleaned_up
        log.info("All test objects successfully cleaned up!")
      end
    end
  end

  # Logs summary of all timings
  def log_timing_summary
    log.info("\n=== Timing Summary ===")
    @timings.each do |description, duration|
      log.info("#{description}: #{duration} seconds")
    end
    total_time = @timings.values.sum.round(2)
    log.info("Total execution time: #{total_time} seconds")
  end
end

# RubricFormatter handles displaying a rubric in a readable format
class RubricFormatter
  # Helper method to truncate strings
  def self.truncate_str(str, length)
    return str unless str && str.length > length
    str[0...(length-3)] + "..."
  end

  # Format a rubric as a table and print it
  def self.format_as_table(rubric)
    # Define column widths
    criterion_col_width = 25
    level_col_width = 18
    points_col_width = 8
    description_col_width = 45
    total_width = criterion_col_width + level_col_width + points_col_width + description_col_width + 13

    # Print table header
    puts "\n#{'=' * total_width}"
    puts "| #{'GENERATED RUBRIC'.center(total_width - 4)} |"
    puts "#{'=' * total_width}"
    puts "| #{'CRITERION'.center(criterion_col_width)} | #{'LEVEL'.center(level_col_width)} | #{'POINTS'.center(points_col_width)} | #{'DESCRIPTION'.center(description_col_width)} |"
    puts "#{'=' * total_width}"

    # Print each criterion and its levels
    rubric.criteria.each do |criterion|
      # Print criterion row
      puts "| #{truncate_str(criterion.title, criterion_col_width - 2).center(criterion_col_width)} | #{''.center(level_col_width)} | #{criterion.points.to_s.center(points_col_width)} | #{truncate_str(criterion.description, description_col_width - 2).ljust(description_col_width)} |"
      puts "|#{'-' * (criterion_col_width + 2)}|#{'-' * (level_col_width + 2)}|#{'-' * (points_col_width + 2)}|#{'-' * (description_col_width + 2)}|"

      # Print level rows for this criterion
      criterion.levels.order(:position).each do |level|
        puts "| #{''.center(criterion_col_width)} | #{truncate_str(level.title, level_col_width - 2).center(level_col_width)} | #{level.points.to_s.center(points_col_width)} | #{truncate_str(level.description, description_col_width - 2).ljust(description_col_width)} |"
        if level != criterion.levels.order(:position).last
          puts "| #{''.center(criterion_col_width)} |#{'-' * (level_col_width + 2)}|#{'-' * (points_col_width + 2)}|#{'-' * (description_col_width + 2)}|"
        end
      end

      # Separator between criteria
      puts "#{'=' * total_width}" unless criterion == rubric.criteria.last
    end

    puts "#{'=' * total_width}"
    puts "Total Points: #{rubric.criteria.sum(&:points)}"
  end
end

# Test runner for GradingTask::KickOffService
class KickOffServiceTester
  def initialize(helper)
    @helper = helper
    @log = helper.log
    @created_objects = helper.created_objects
  end

  def run_test
    @helper.safely_execute("Testing GradingTask::KickOffService") do
      # Create params for KickOffService
      start_time = Time.now
      @log.info("Building KickOffService params...")
      kickoff_params = {
        user: User.first,
        assignment_prompt: {
          title: "Expository Essay",
          subject: "English",
          grade_level: "10",
          word_count: 1200,
          content: "<div>Write an expository essay explaining the impact of technology on modern education.</div>"
        },
        rubric: {
          title: "Expository Essay",
          raw_text: "Content: 35%, Organization: 25%, Grammar: 20%, Citations: 20%"
        }
      }
      param_time = Time.now
      @log.info("Params built in #{(param_time - start_time).round(2)} seconds")

      # Call the orchestration service
      @log.info("Calling KickOffService...")
      kickoff_task = GradingTask::KickOffService.call(kickoff_params)
      service_time = Time.now
      @log.info("KickOffService completed in #{(service_time - param_time).round(2)} seconds")
      @log.info("KickOffService created GradingTask ##{kickoff_task.id}")

      # Verify the results
      @log.info("Verifying KickOffService results:")
      @log.info("- GradingTask: #{kickoff_task.persisted? ? 'Created ✓' : 'Failed ✗'}")
      @log.info("- Assignment Prompt: #{kickoff_task.assignment_prompt.persisted? ? 'Created ✓' : 'Failed ✗'}")
      @log.info("- Rubric: #{kickoff_task.rubric.persisted? ? 'Created ✓' : 'Failed ✗'}")
      @log.info("- RawRubric: #{kickoff_task.rubric.raw_rubric.persisted? ? 'Created ✓' : 'Failed ✗'}")

      # Add to cleanup list
      @created_objects[:kickoff_task] = kickoff_task
      @created_objects[:kickoff_prompt] = kickoff_task.assignment_prompt
      @created_objects[:kickoff_rubric] = kickoff_task.rubric
      @created_objects[:kickoff_raw_rubric] = kickoff_task.rubric.raw_rubric

      verify_time = Time.now
      @log.info("Result verification completed in #{(verify_time - service_time).round(2)} seconds")
      @log.info("KickOffService test completed successfully!")
    end
  end
end

# Test runner for Rubric::GeneratorService
class GeneratorServiceTester
  def initialize(helper)
    @helper = helper
    @log = helper.log
    @created_objects = helper.created_objects
  end

  def run_test
    @helper.safely_execute("Testing Rubric::GeneratorService") do
      create_test_objects
      dump_existing_positions
      create_raw_rubric
      run_generator
      display_results
    end
  end

  private

  def create_test_objects
    start_time = Time.now
    @log.info("Creating test objects...")

    # Create a user
    user = User.first
    @log.info("Using user: #{user.name} (ID: #{user.id})")

    # Create a rubric using CreationService
    rubric_start = Time.now
    @created_objects[:rubric] = Rubric::CreationService.call(
      user: user,
      title: "Literary Analysis Essay"
    )
    rubric_time = Time.now
    @log.info("Created Rubric in #{(rubric_time - rubric_start).round(2)} seconds: #{@created_objects[:rubric].title} (ID: #{@created_objects[:rubric].id})")

    # Create a grading task with the rubric using CreationService
    task_start = Time.now
    @created_objects[:grading_task] = GradingTask::CreationService.call(
      user: user,
      rubric: @created_objects[:rubric]
    )
    task_time = Time.now
    @log.info("Created GradingTask in #{(task_time - task_start).round(2)} seconds (ID: #{@created_objects[:grading_task].id})")

    # Create an assignment prompt using CreationService
    prompt_start = Time.now
    @created_objects[:assignment_prompt] = AssignmentPrompt::CreationService.call(
      grading_task: @created_objects[:grading_task],
      title: "Literary Analysis Essay",
      subject: "English",
      grade_level: "10",
      word_count: 1500,
      content: "<div>Write a literary analysis essay on the themes of power and corruption in Shakespeare's Macbeth.</div>"
    )
    prompt_time = Time.now
    @log.info("Created Assignment Prompt in #{(prompt_time - prompt_start).round(2)} seconds: #{@created_objects[:assignment_prompt].title} (ID: #{@created_objects[:assignment_prompt].id})")

    end_time = Time.now
    @log.info("\nCreated all test objects in #{(end_time - start_time).round(2)} seconds:")
    @log.info("Assignment Prompt: #{@created_objects[:assignment_prompt].title} (ID: #{@created_objects[:assignment_prompt].id})")
    @log.info("Grading Task ID: #{@created_objects[:grading_task].id})")
    @log.info("Rubric: #{@created_objects[:rubric].title} (ID: #{@created_objects[:rubric].id})")
  end

  def dump_existing_positions
    @log.info("\nExisting criteria positions:")
    Criterion.where(rubric_id: @created_objects[:rubric].id).each do |c|
      @log.info("Criterion ID: #{c.id}, Position: #{c.position}, Title: #{c.title}")
    end

    @log.info("\nExisting level positions:")
    Level.joins(:criterion).where(criteria: { rubric_id: @created_objects[:rubric].id }).each do |l|
      @log.info("Level ID: #{l.id}, Criterion ID: #{l.criterion_id}, Position: #{l.position}, Title: #{l.title}")
    end
  end

  def create_raw_rubric
    # Create raw rubric text
    start_time = Time.now
    raw_rubric_text = "Content: 40%, Structure: 30%, Grammar: 30%"
    @created_objects[:raw_rubric] = Rubric::RawRubricCreationService.call(
      rubric: @created_objects[:rubric],
      raw_text: raw_rubric_text,
      grading_task: @created_objects[:grading_task]
    )
    end_time = Time.now
    @log.info("Created RawRubric in #{(end_time - start_time).round(2)} seconds (ID: #{@created_objects[:raw_rubric].id})")
  end

  def run_generator
    # Call the generator service
    @log.info("\nCalling Rubric::GeneratorService...")
    start_time = Time.now
    @rubric = Rubric::GeneratorService.new(
      assignment_prompt: @created_objects[:assignment_prompt],
      rubric: @created_objects[:rubric],
      grading_task: @created_objects[:grading_task]
    ).generate
    end_time = Time.now
    generation_time = (end_time - start_time).round(2)

    # Track created criteria and levels for cleanup
    @created_objects[:criteria] = @rubric.criteria.to_a
    @created_objects[:criteria].each do |criterion|
      @created_objects[:levels] += criterion.levels.to_a
    end

    @log.info("\nRubric generation completed in #{generation_time} seconds!")
  end

  def display_results
    # Format and display the generated rubric
    RubricFormatter.format_as_table(@rubric)
  end
end

# Main test runner
def run_rubric_generator_tests
  helper = RubricTestHelper.new

  # Record start time
  start_time = Time.now

  # Execute test phases
  helper.cleanup_existing_objects

  helper.log.info("\n=== Starting test of Rubric::GeneratorService ===\n")

  # Test KickOffService
  kickoff_tester = KickOffServiceTester.new(helper)
  kickoff_start = Time.now
  kickoff_tester.run_test
  kickoff_end = Time.now
  helper.log.info("Total KickOffService test time: #{(kickoff_end - kickoff_start).round(2)} seconds")

  # Test GeneratorService
  generator_tester = GeneratorServiceTester.new(helper)
  generator_start = Time.now
  generator_tester.run_test
  generator_end = Time.now
  helper.log.info("Total GeneratorService test time: #{(generator_end - generator_start).round(2)} seconds")

  # Clean up and verify
  helper.cleanup_test_objects
  helper.verify_cleanup

  # Record end time and log total duration
  end_time = Time.now
  total_duration = (end_time - start_time).round(2)
  helper.log.info("\n=== Test of Rubric::GeneratorService completed in #{total_duration} seconds ===\n")

  # Log timing summary
  helper.log_timing_summary
end

# Execute the tests
run_rubric_generator_tests
