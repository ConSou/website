require 'test_helper'

class API::SolutionResponderTest < ActiveSupport::TestCase
  test "basic to_hash" do
    solution = create :solution
    user_track = create :user_track, user: solution.user, track: solution.exercise.track
    responder = API::SolutionResponder.new(solution, solution.user)
    expected = {
      solution: {
        id: solution.uuid,
        url: "https://exercism.io/my/solutions/#{solution.uuid}",
        user: {
          handle: solution.user.handle,
          is_requester: true
        },
        exercise: {
          id: solution.exercise.slug,
          instructions_url: "https://exercism.io/my/solutions/#{solution.uuid}",
          track: {
            id: solution.exercise.track.slug
          }
        },
        files: [],
        iteration: nil
      }
    }

    assert_equal expected, responder.to_hash
  end

  test "to_hash with different requester" do
    user = create :user
    solution = create :solution
    user_track = create :user_track, user: solution.user, track: solution.exercise.track

    responder = API::SolutionResponder.new(solution, user)
    refute responder.to_hash[:solution][:user][:is_requester]
  end

  test "handle is alias on anonymous track" do
    handle = "foosa1111"
    user = create :user
    track = create :track
    create :user_track, user: user, track: track, anonymous: true, handle: handle
    solution = create :solution, user: user, exercise: create(:exercise, track: track)

    responder = API::SolutionResponder.new(solution, user)
    assert_equal handle, responder.to_hash[:solution][:user][:handle]
  end

  test "iteration is represented correctly" do
    solution = create :solution
    user_track = create :user_track, user: solution.user, track: solution.exercise.track
    responder = API::SolutionResponder.new(solution, solution.user)

    created_at = Time.now.getutc - 1.week
    iteration = create :iteration, solution: solution, created_at: created_at
    assert_equal created_at.to_i, responder.to_hash[:solution][:iteration][:submitted_at].to_i
  end

  test "solution_url should be /mentor/solutions if mentor" do
    solution = create :solution
    user_track = create :user_track, user: solution.user, track: solution.exercise.track
    mentor = create :user
    create :track_mentorship, user: mentor, track: solution.exercise.track
    responder = API::SolutionResponder.new(solution, mentor)
    assert_equal "https://exercism.io/mentor/solutions/#{solution.uuid}", responder.to_hash[:solution][:url]
  end

  test "instructions_url should be /my/solutions for solution user if published" do
    solution = create :solution, published_at: DateTime.now - 1.week
    track = solution.exercise.track
    user_track = create :user_track, user: solution.user, track: track
    responder = API::SolutionResponder.new(solution, solution.user)
    assert_equal "https://exercism.io/my/solutions/#{solution.uuid}", responder.to_hash[:solution][:url]
  end

  test "instructions_url should be /solutions for other user if published" do
    solution = create :solution, published_at: DateTime.now - 1.week
    track = solution.exercise.track
    user_track = create :user_track, user: solution.user, track: track
    responder = API::SolutionResponder.new(solution, create(:user))
    assert_equal "https://exercism.io/tracks/#{track.slug}/exercises/#{solution.exercise.slug}/solutions/#{solution.uuid}", responder.to_hash[:solution][:url]
  end

  test "instructions_url should be /solutions if mentor and published" do
    solution = create :solution, published_at: DateTime.now - 1.week
    track = solution.exercise.track
    user_track = create :user_track, user: solution.user, track: solution.exercise.track
    mentor = create :user
    create :track_mentorship, user: mentor, track: solution.exercise.track
    responder = API::SolutionResponder.new(solution, mentor)
    assert_equal "https://exercism.io/tracks/#{track.slug}/exercises/#{solution.exercise.slug}/solutions/#{solution.uuid}", responder.to_hash[:solution][:url]
  end
end