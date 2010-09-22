require 'test_helper'

class QuestionTest < ActiveSupport::TestCase
  fixtures :questions

  # Replace this with your real tests.
  def test_should_get_refkyo_search
    result = Question.search_porta('Yahoo', {:dpid => 'refkyo'})
    assert result.items.size > 0
    assert_not_nil result.channel.totalResults
  end

  def test_should_get_crd_search
    result = Question.search_crd(:query_01 => 'Yahoo')
    assert result
    assert result.total_entries > 0
  end

  test "should respond to last_updated_at" do
    assert questions(:question_00001).last_updated_at
  end
end
