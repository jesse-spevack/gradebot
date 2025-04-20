class Rubric::CreationService
  def self.call(user:, title:)
    new(user: user, title: title).call
  end

  def initialize(user:, title:)
    @user = user
    @title = "#{title} Rubric"
  end

  def call
    Rubric.create!(
      title: @title,
      user: @user,
      total_points: 100,
      status: :pending
    )
  end
end
