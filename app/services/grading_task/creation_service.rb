class GradingTask::CreationService
  def self.call(user:, rubric:, feedback_tone: nil)
    new(user: user, rubric: rubric, feedback_tone: feedback_tone).call
  end

  def initialize(user:, rubric:, feedback_tone: nil)
    @user = user
    @rubric = rubric
    @feedback_tone = feedback_tone
  end

  def call
    GradingTask.create!(
      user: @user,
      rubric: @rubric,
      status: :pending,
      feedback_tone: @feedback_tone
    )
  end
end
