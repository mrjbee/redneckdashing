require 'net/http'
require 'json'
require 'openssl'

class GitlabServerAccess

   def initialize(url, user_auth)
      @url = URI.parse(url)
      @user_auth = user_auth
   end

   def has_access
      #TODO implement access check for earlier error debugging
   end


   def _get(resource_urn)
      resource_url = URI::encode("/api/v3#{resource_urn}")
      http = Net::HTTP.new(@url.host, @url.port)
      request = Net::HTTP::Get.new(resource_url)
      request.add_field('PRIVATE-TOKEN', @user_auth)
      if @url.scheme == 'https'
         http.use_ssl = true
         http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      response = http.request(request)
      # puts "[HTTP] #{resource_url} response with #{response.inspect}"
      case response
         when Net::HTTPSuccess then
            JSON.parse(response.body)
         else
            raise " Invalid response for resource_url = #{@url + resource_url} is #{response}"
      end
   end

   def project(id)
      _get("/projects/#{id}")
   end

   def merge_requests(project_id, state)
      _get("/projects/#{project_id}/merge_requests?state=#{state}")
   end

   def merge_request_comments(project_id, merge_request_id)
      _get("/projects/#{project_id}/merge_requests/#{merge_request_id}/notes")
   end

   def merge_request_comment(project_id, merge_request_id, comment_id)
      _get("/projects/#{project_id}/merge_request/#{merge_request_id}/notes/#{comment_id}")
   end

   def merge_request_commits(project_id, merge_request_id)
      _get("/projects/#{project_id}/merge_request/#{merge_request_id}/commits")
   end

end

class Resource
   def initialize(json)
      @json = json
   end

   def json
      @json
   end
end

class LazyResource

   def initialize(get_proc)
      @json = nil
      @getter_proc = get_proc
      @lock = Mutex.new
   end

   def json
      unless @json
         @lock.synchronize{
            #If DCL working for Ruby?
            unless @json
               @json = @getter_proc.call
            end
         }
      end
      @json
   end

end

class GitlabUser

   def initialize(resource)
      @resource = resource
   end

   def method_missing(method, *args, &block)
      if args.size != 0 || block
         raise "Unsupported args = #{args} or block = #{block}"
      end
      @resource.json["#{method}"]
   end

end

class GitlabMergeRequestCommit

   def initialize(server_access, mr, resource)
      @server_access = server_access
      @mr = mr
      @resource = resource
   end

   def method_missing(method, *args, &block)
      if args.size != 0 || block
         raise "Unsupported args = #{args} or block = #{block}"
      end
      @resource.json["#{method}"]
   end

end

class GitlabComment

   def initialize(server_access, mr, resource)
      @server_access = server_access
      @mr = mr
      @resource = resource
   end

   def author
      @resource.json['author']? GitlabUser.new(Resource.new(@resource.json['author'])):nil
   end

   def method_missing(method, *args, &block)
      if args.size != 0 || block
         raise "Unsupported method = #{method} args = #{args} or block = #{block}"
      end
      @resource.json["#{method}"]
   end
   def to_json
      @resource.json
   end

end


class GitlabMergeRequest

   def initialize(server_access, project, resource)
      @access = server_access
      @project = project
      @resource = resource
      @lock_commits = Mutex.new
      @lock_comments = Mutex.new
      @comments = nil
      @commits = nil
   end

   def author
      @resource.json['author']? GitlabUser.new(Resource.new(@resource.json['author'])):nil
   end

   def assignee
      @resource.json['assignee']? GitlabUser.new(Resource.new(@resource.json['assignee'])):nil
   end

   def comments
      @lock_comments.synchronize{
         unless @comments
            @comments = @access.merge_request_comments(@project.id, id)
            .sort {|left, right| (Gitlab.date_iso_8601_to_seconds left['created_at']) <=> (Gitlab.date_iso_8601_to_seconds right['created_at'])}
            .map{|merge_request_commit|
               GitlabComment.new(@access, self, Resource.new(merge_request_commit))
            }
         end
      }
      @comments
   end

   def commits
      @lock_commits.synchronize{
         unless @commits
            @commits = @access.merge_request_commits(@project.id, id).map{|commit|
               GitlabMergeRequestCommit.new(@access, self, Resource.new(commit))
            }
         end
      }
      @commits
   end

   def latest_comment
      comments.last if comments.any?
   end

   def method_missing(method, *args, &block)
      if args.size != 0 || block
         raise "Unsupported method = #{method} args = #{args} or block = #{block}"
      end
      @resource.json["#{method}"]
   end

end

class GitlabProject

   # @param server_access [GitlabServerAccess]
   def initialize (server_access, project_id)
      @access = server_access
      @id = project_id
      @resource = LazyResource.new proc {server_access.project(project_id)}
      @open_merge_requests = nil
      @lock = Mutex.new
   end

   def id
      @id
   end

   def open_merge_requests
      @lock.synchronize{
         unless @open_merge_requests
            @open_merge_requests = @access.merge_requests(@id, 'opened').map{|merge_request|
               GitlabMergeRequest.new(@access, self, Resource.new(merge_request))
            }
         end
      }
      @open_merge_requests
   end

   def method_missing(method, *args, &block)
      if args.size != 0 || block
         raise "Unsupported method = #{method} args = #{args} or block = #{block}"
      end
      @resource.json["#{method}"]
   end
end


module Gitlab
   #@return GitlabProject
   def Gitlab.project(project_id, server_url, user_auth )
      access = GitlabServerAccess.new(server_url, user_auth)
      access.has_access
      project = GitlabProject.new(access, project_id)
      return project
   end

   def Gitlab.date_iso_8601_to_seconds(date_string)
      Time.iso8601(date_string).to_i
   end

   def Gitlab.date_iso_8601_to_ago_date(date_string)
      date_time = Time.iso8601(date_string)
      seconds_ago = Time.now.to_i - date_time.to_i

      days_ago = seconds_ago / (60 * 60 * 24)
      seconds_ago -= days_ago * (60 * 60 * 24)
      hours_ago = seconds_ago/(60 * 60)
      seconds_ago -= hours_ago * (60 * 60)
      minutes_ago = seconds_ago/60
      seconds_ago -= minutes_ago * 60

      if days_ago > 0
         "#{days_ago} day(s) ago"
         return case days_ago
                   when 1
                      'yesterday'
                   when 2
                      'the day before'
                   else
                     "#{days_ago} days ago"
                end
      end

      if hours_ago > 0
         return "#{hours_ago} hr ago"
      end

      if minutes_ago > 0
         return case minutes_ago
                   when 0..10
                      'few minutes ago'
                   else
                      "#{minutes_ago} min(s) ago"
                end
      end
      return 'few seconds ago'
   end
end
