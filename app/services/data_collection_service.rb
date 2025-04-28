# frozen_string_literal: true

# Service responsible for collecting data required for LLM processing
class DataCollectionService
  # Collect data for a specific processable and process type
  # @param processable [Object] The object being processed (StudentWork, Rubric, etc.)
  # @param process_type [String] The type of processing
  # @return [Hash] Data needed for processing
  def self.for(processable, process_type)
    case [ processable.class.name, process_type ]
    when [ "StudentWork", "grade_student_work" ]
      collect_student_work_data(processable)
    when [ "Rubric", "generate_rubric" ]
      collect_rubric_data(processable)
    when [ "Assignment", "generate_summary_feedback" ]
      collect_assignment_summary_data(processable)
    else
      raise ArgumentError, "Unsupported combination: #{processable.class.name}##{process_type}"
    end
  end

  # Collect data for student work grading
  # @param student_work [StudentWork] The student work to grade
  # @return [Hash] Data for grading
  def self.collect_student_work_data(student_work)
    assignment = student_work.assignment
    {
      title: assignment.title,
      description: assignment.description,
      instructions: assignment.instructions,
      grade_level: assignment.grade_level,
      subject: assignment.subject,
      rubric: assignment.rubric.to_prompt,
      student_work: student_work.content
    }
  end

  # Collect data for rubric generation
  # @param rubric [Rubric] The rubric to generate
  # @return [Hash] Data for rubric generation
  def self.collect_rubric_data(rubric)
    assignment = rubric.assignment
    data = {
      title: assignment.title,
      description: assignment.description,
      instructions: assignment.instructions,
      grade_level: assignment.grade_level,
      subject: assignment.subject
    }

    data.merge!(raw_rubric_text: assignment.raw_rubric_text) if assignment.raw_rubric_text.present?

    data
  end

  # Collect data for assignment summary feedback
  # @param assignment [Assignment] The assignment to summarize
  # @return [Hash] Data for summary generation
  def self.collect_assignment_summary_data(assignment)
    {
      title: assignment.title,
      description: assignment.description,
      instructions: assignment.instructions,
      grade_level: assignment.grade_level,
      subject: assignment.subject,
      rubric: assignment.rubric&.to_prompt,
      student_works: assignment.student_works
    }
  end
end
