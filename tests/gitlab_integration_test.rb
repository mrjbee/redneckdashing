require 'test/unit'
require_relative '../lib/gitlab'

class GitlabIntegrationTest < Test::Unit::TestCase

  # Sorry but this test require real server
  # with real user, repo and merge commits

    def self.startup
      @@private_key = 'ypVMW57neff_QFN1zqkR'
      @@server_url = 'https://gitlab.com'

      # Use following url for discover PROJECT ids
      # https://gitlab.com/api/v3/projects/owned?private_token=EauLbCh3Y-es32QGfxAK

      @@project_id = 785506
      @@expected_project_name = "Gitlab Playground"
      @@expected_merge_request_count = 2
      @@expected_merge_request_comments_total_count = 6
      @@expected_merge_request_commits_total_count = 3

      @@project = Gitlab.project(@@project_id, @@server_url, @@private_key)
    end


  def test_explore_project
    assert_equal @@expected_project_name, @@project.name
  end

  def test_explore_open_merge_requests
    assert_equal @@expected_merge_request_count, @@project.open_merge_requests.size
    puts " [GANGNAM ASSERT] >> Merge requests titles = #{@@project.open_merge_requests.map{|mr| mr.title }}"
  end

  def test_explore_open_merge_requests_comments
    all = @@project.open_merge_requests.inject([]){|sum, mr| sum + mr.comments}
    puts " [GANGNAM ASSERT] >> Merge request comment notes = #{all.map{|mr| mr.to_json }}"
    assert_equal @@expected_merge_request_comments_total_count, all.size
  end

  def test_explore_open_merge_requests_commits
    all = @@project.open_merge_requests.inject([]){|sum, mr| sum + mr.commits}
    puts " [GANGNAM ASSERT] >> Merge request comment notes = #{all.map{|mr| mr.short_id }}"
    assert_equal @@expected_merge_request_commits_total_count, all.size
  end

  def test_explore_author
      author = @@project.open_merge_requests[0].author
      puts " [GANGNAM ASSERT] >> Author = #{author.name}"
      assert_not_nil author
  end

  def test_explore_assignee
    assignee_0 = @@project.open_merge_requests[0].assignee
    assignee_1 = @@project.open_merge_requests[1].assignee
    puts " [GANGNAM ASSERT] >> Author = #{assignee_1.name}"
    assert_not_nil assignee_1
    assert_nil assignee_0
  end

  def test_latest_mr_comment
    comment = @@project.open_merge_requests[0].latest_comment.to_json
    puts " [GANGNAM ASSERT] >> Latest comment = #{comment}"
    assert_not_nil comment
  end

end