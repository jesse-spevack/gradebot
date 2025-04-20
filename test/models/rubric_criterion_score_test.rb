require "test_helper"

class RubricCriterionScoreTest < ActiveSupport::TestCase
  test "valid rubric_criterion_score with all attributes" do
    # Setup
    score = RubricCriterionScore.new(
      student_submission: student_submissions(:pending_submission),
      criterion: criteria(:content_criterion),
      points_earned: 20,
      level: levels(:excellent_level),
      reason: "The essay demonstrates excellent content development",
      evidence: "The introduction clearly establishes the thesis and each paragraph develops a supporting point."
    )

    # Exercise & Verify
    assert score.valid?
  end

  test "invalid without student_submission" do
    # Setup
    score = RubricCriterionScore.new(
      criterion: criteria(:content_criterion),
      points_earned: 20,
      level: levels(:excellent_level),
      reason: "The essay demonstrates excellent content development",
      evidence: "The introduction clearly establishes the thesis and each paragraph develops a supporting point."
    )

    # Exercise & Verify
    assert_not score.valid?
    assert_includes score.errors[:student_submission], "must exist"
  end

  test "invalid without criterion" do
    # Setup
    score = RubricCriterionScore.new(
      student_submission: student_submissions(:pending_submission),
      points_earned: 20,
      level: levels(:excellent_level),
      reason: "The essay demonstrates excellent content development",
      evidence: "The introduction clearly establishes the thesis and each paragraph develops a supporting point."
    )

    # Exercise & Verify
    assert_not score.valid?
    assert_includes score.errors[:criterion], "must exist"
  end

  test "invalid without points_earned" do
    # Setup
    score = RubricCriterionScore.new(
      student_submission: student_submissions(:pending_submission),
      criterion: criteria(:content_criterion),
      level: levels(:excellent_level),
      reason: "The essay demonstrates excellent content development",
      evidence: "The introduction clearly establishes the thesis and each paragraph develops a supporting point."
    )

    # Exercise & Verify
    assert_not score.valid?
    assert_includes score.errors[:points_earned], "can't be blank"
  end

  test "invalid without level" do
    # Setup
    score = RubricCriterionScore.new(
      student_submission: student_submissions(:pending_submission),
      criterion: criteria(:content_criterion),
      points_earned: 20,
      reason: "The essay demonstrates excellent content development",
      evidence: "The introduction clearly establishes the thesis and each paragraph develops a supporting point."
    )

    # Exercise & Verify
    assert_not score.valid?
    assert_includes score.errors[:level], "must exist"
  end

  test "invalid without reason" do
    # Setup
    score = RubricCriterionScore.new(
      student_submission: student_submissions(:pending_submission),
      criterion: criteria(:content_criterion),
      points_earned: 20,
      level: levels(:excellent_level),
      evidence: "The introduction clearly establishes the thesis and each paragraph develops a supporting point."
    )

    # Exercise & Verify
    assert_not score.valid?
    assert_includes score.errors[:reason], "can't be blank"
  end

  test "invalid without evidence" do
    # Setup
    score = RubricCriterionScore.new(
      student_submission: student_submissions(:pending_submission),
      criterion: criteria(:content_criterion),
      points_earned: 20,
      level: levels(:excellent_level),
      reason: "The essay demonstrates excellent content development"
    )

    # Exercise & Verify
    assert_not score.valid?
    assert_includes score.errors[:evidence], "can't be blank"
  end

  test "points_earned cannot exceed criterion points" do
    # Setup
    criterion = criteria(:content_criterion)
    score = RubricCriterionScore.new(
      student_submission: student_submissions(:pending_submission),
      criterion: criterion,
      points_earned: criterion.points + 5,
      level: levels(:excellent_level),
      reason: "The essay demonstrates excellent content development",
      evidence: "The introduction clearly establishes the thesis and each paragraph develops a supporting point."
    )

    # Exercise & Verify
    assert_not score.valid?
    assert_includes score.errors[:points_earned], "cannot exceed criterion points"
  end

  test "belongs to student_submission" do
    # Setup
    score = rubric_criterion_scores(:content_score)

    # Exercise & Verify
    assert_respond_to score, :student_submission
  end

  test "belongs to criterion" do
    # Setup
    score = rubric_criterion_scores(:content_score)

    # Exercise & Verify
    assert_respond_to score, :criterion
  end

  test "belongs to level" do
    # Setup
    score = rubric_criterion_scores(:content_score)

    # Exercise & Verify
    assert_respond_to score, :level
  end
end
