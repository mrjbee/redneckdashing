require 'net/http'
require 'json'
require 'openssl'

class GerritServerAccess

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
      _get("/projects/#{project_id}/merge_request/#{merge_request_id}/comments")
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
            #Isn DCL working for Ruby?
            unless @json
               @json = @getter_proc.call
            end
         }
      end
      @json
   end

end

class GerritUser

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

class GerritMergeRequestCommit

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

class GerritMergeRequestComment

   def initialize(server_access, mr, resource)
      @server_access = server_access
      @mr = mr
      @resource = resource
   end

   def author
      @resource.json['author']? GerritUser.new(Resource.new(@resource.json['author'])):nil
   end

   def method_missing(method, *args, &block)
      if args.size != 0 || block
         raise "Unsupported method = #{method} args = #{args} or block = #{block}"
      end
      @resource.json["#{method}"]
   end

end


class GerritMergeRequest

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
      @resource.json['author']? GerritUser.new(Resource.new(@resource.json['author'])):nil
   end

   def assignee
      @resource.json['assignee']? GerritUser.new(Resource.new(@resource.json['assignee'])):nil
   end

   def comments
      @lock_comments.synchronize{
         unless @comments
            @comments = @access.merge_request_comments(@project.id, id).map{|merge_request_commit|
               GerritMergeRequestComment.new(@access, self, Resource.new(merge_request_commit))
            }
         end
      }
      @comments
   end

   def commits
      @lock_commits.synchronize{
         unless @commits
            @commits = @access.merge_request_commits(@project.id, id).map{|commit|
               GerritMergeRequestCommit.new(@access, self, Resource.new(commit))
            }
         end
      }
      @commits
   end

   def latest_comment
      comments
      comments[0] if comments.any?
   end

   def method_missing(method, *args, &block)
      if args.size != 0 || block
         raise "Unsupported method = #{method} args = #{args} or block = #{block}"
      end
      @resource.json["#{method}"]
   end

end

class GerritProject

   # @param server_access [GerritServerAccess]
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
            @open_merge_requests = @access.merge_requests(@id, 'open').map{|merge_request|
               GerritMergeRequest.new(@access, self, Resource.new(merge_request))
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


module Gerrit
   def Gerrit.project(project_id, server_url, user_auth )
      access = GerritServerAccess.new(server_url, user_auth)
      access.has_access
      project = GerritProject.new(access, project_id)
      return project
   end
end
