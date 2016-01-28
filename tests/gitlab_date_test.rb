require 'test/unit'
require_relative '../lib/gitlab'

class GitlabDateTest < Test::Unit::TestCase

  # Date string example '2016-01-27T20:50:13.322Z'

  def test_should_return_second_ago
    assert_equal 'few seconds ago', to_ago_s(ago_iso8601_s(0,0,0,5))
  end

  def test_should_return_just_second
    assert_equal 'few seconds ago', to_ago_s(ago_iso8601_s(0,0,0,1))
  end

  def test_should_return_just_few_minute_ago
    assert_equal 'few minutes ago', to_ago_s(ago_iso8601_s(0,0,1,1))
  end

  def test_should_return_just_20_minute_ago
    assert_equal '21 min(s) ago', to_ago_s(ago_iso8601_s(0,0,21,1))
  end

  def test_should_return_yesterday
    assert_equal 'yesterday', to_ago_s(ago_iso8601_s(1))
  end

  def test_should_return_2_days_ago
    assert_equal 'the day before', to_ago_s(ago_iso8601_s(2))
  end

  def test_should_return_3_days_ago
    assert_equal '3 days ago', to_ago_s(ago_iso8601_s(3))
  end

  def to_ago_s(iso8601)
    Gitlab.date_iso_8601_to_ago_date(iso8601)
  end

  def ago_iso8601_s(days=0, hours=0, minutes=0, seconds=0)
    (Time.now - (days * (60*60*24) + hours * (60*24) + minutes*(60) + seconds)).iso8601.to_s
  end

end