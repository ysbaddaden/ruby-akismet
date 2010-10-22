require 'net/http'

# Akismet compatible library for checking spams. Works with Typepad Antispam
# by default, but should be useable with any Akismet compatible server.
# 
# = Usage
# 
# First you need an Akismet (or Typepad Antispam) API key. Then you need
# to setup a few configuration variable.
# 
#   Akismet.key  = '123456789'
#   Akismet.blog = 'http://example.com'
# 
# To use Typepad Antispam, just set the host:
# 
#   Akismet.host = 'api.antispam.typepad.com'
# 
# Then you need to call any of the methods with a few attributes,
# and possibly an ActionDispatch::Request object.
# 
# = Integrate with Ruby on Rails (3.0+)
# 
# Add this gem to your Gemfile:
# 
#   gem 'ruby-akismet', :require => 'akismet',
#     :git => 'git://github.com/ysbaddaden/ruby-akismet.git'
# 
# Create an initializer file like <code>config/initializers/akismet.rb</code>
# with your configuration:
# 
#   Akismet.key  = '123456789'
#   Akismet.blog = 'http://example.com'
# 
# Then in your controller call the appropriate methods:
# 
#   class CommentsController < ApplicationController
#     before_filter :set_post
#     respond_to :html, :xml
#     
#     def create
#       @comment = @post.comments.new(params[:comment])
#       @comment.spam = Akismet.spam?(akismet_attributes, request)
#       @comment.save
#       respond_with(@comment, :location => @post)
#     end
#     
#     def spam
#       @comment = Comment.find(params[:id])
#       @comment.update_attribute(:spam, false)
#       Akismet.submit_spam(akismet_attributes)
#       respond_with(@comment, :location => @post)
#     end
#     
#     def ham
#       @comment = Comment.find(params[:id])
#       @comment.update_attribute(:spam, false)
#       Akismet.submit_ham(akismet_attributes)
#       respond_with(@comment, :location => @post)
#     end
#     
#     private
#       def akismet_attributes
#         {
#           :comment_author       => @comment.author,
#           :comment_author_url   => @comment.author_url,
#           :comment_author_email => @comment.author_email,
#           :comment_content      => @comment.body,
#           :permalink            => post_url(@post)
#         }
#       end
#       
#       def set_post
#         @post = Post.find(params[:post_id])
#       end
#   end
# 
class Akismet
  VERSION     = '0.9'.freeze
  API_VERSION = '1.1'.freeze

  @@host = 'rest.akismet.com'
  @@key  = nil
  @@blog = nil

  class << self
    def host=(host)
      @@host = host
    end

    def key=(key)
      @@key = key
    end

    def blog=(blog)
      @@blog = blog
    end

    def valid_key?(key)
      call('verify-key', :key => key) == "valid"
    end

    # Checks wether a comment is spam or not.
    # 
    # Required attributes:
    # 
    # - <code>:permalink</code>
    # - <code>:comment_author</code>
    # - <code>:comment_author_url</code>
    # - <code>:comment_author_email</code>
    # - <code>:comment_content</code>
    # 
    # Those are also required, but will be extracted from the request object:
    # 
    # - <code>:user_ip</code>
    # - <code>:user_agent</code>
    # - <code>:referer</code>
    # - plus any more relevant HTTP header.
    # 
    def spam?(attributes, request = nil)
      call('comment-check', attributes, request) == "true"
    end

    # Returns true unless comment is spam. Accepts the same arguments than spam.
    def ham?(attributes, request = nil)
      call('comment-check', attributes, request) == "false"
    end

    # Submits a spam comment to Akismet that hadn't been recognized
    # as spam. Takes the same attributes than spam.
    def submit_spam(attributes)
      call('submit-spam', attributes)
    end

    # Submits a false-positive comment as non-spam to Akismet.
    # Takes the same attributes than spam.
    def submit_ham(attributes)
      call('submit-ham', attributes)
    end

    private
      def call(command, attributes, request = nil)
        new(command, attributes, request).call
      end
  end

  def initialize(command, attributes, request = nil) # :nodoc:
    @command    = command
    @attributes = attributes
    @request    = request
  end

  def call # :nodoc:
    http = Net::HTTP.new(http_host, 80)
    http.post(http_path, post_attributes, http_headers).body
  end

  private
    def attributes
      @attributes[:blog] ||= @@blog
      
      unless @command == 'verify-key'
        @attributes[:comment_type] ||= 'comment'
        
        unless @request.nil?
          @attributes[:user_ip]    ||= @request.remote_ip
          @attributes[:user_agent] ||= @request.headers["User-Agent"]
          @attributes[:referrer]   ||= @request.headers["Http-Referer"]
        end
      end
      
      @attributes
    end

    def post_attributes
      post = attributes.map { |k,v| "#{k}=#{v}" }.join("&")
      URI.escape(post)
    end

    def http_headers
      {
        "User-Agent" => "RubyAkismet/#{VERSION} | Akismet/#{API_VERSION}",
        "Content-Type" => "application/x-www-form-urlencoded"
      }
    end

    def http_host
      unless @command == 'verify-key'
        "#{@@key}.#{@@host}"
      else
        "#{@@host}"
      end
    end

    def http_path
      "/#{API_VERSION}/#{@command}"
    end
end
