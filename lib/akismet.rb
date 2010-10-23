require 'net/http'

# Akismet compatible library for checking spams.
class Akismet
  VERSION     = '0.9.3'.freeze
  API_VERSION = '1.1'.freeze

  @@host = 'rest.akismet.com'
  @@key  = nil
  @@blog = nil
  @@extra_headers = [
    'HTTP_REMOTE_ADDR',
    'HTTP_CLIENT_IP',
    'HTTP_X_FORWARDED_FOR',
    'HTTP_CONNECTION'
  ]

  class << self
    # Configure an alternate API server.
    def host=(host)
      @@host = host
    end

    # Configure your API key (required).
    def key=(key)
      @@key = key
    end

    # Configure your homepage URL (optional).
    def blog=(blog)
      @@blog = blog
    end

    # Configure an array of extra HTTP headers to pass to Akismet from
    # the request.
    # 
    # Example:
    # 
    #   Akismet.extra_headers = ['HTTP_REMOTE_ADDR', 'HTTP_CLIENT_IP', 'HTTP_X_FORWARDED_FOR']
    def extra_headers=(headers)
      @@extra_headers = headers
    end

    # Checks if a key is valid or not.
    def valid_key?(key)
      call('verify-key', :key => key) == "valid"
    end

    # Checks if a comment is spam.
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

    # Checks if a comment is ham. Takes the same arguments than spam?.
    def ham?(attributes, request = nil)
      call('comment-check', attributes, request) == "false"
    end

    # Submits a spam comment to Akismet that hadn't been recognized
    # as spam. Takes the same attributes than spam?.
    def submit_spam(attributes)
      call('submit-spam', attributes)
    end

    # Submits a false-positive comment as non-spam to Akismet.
    # Takes the same attributes than +spam+.
    def submit_ham(attributes)
      call('submit-ham', attributes)
    end

    private
      def call(command, attributes, request = nil)
        new(command, attributes, request).call
      end
  end

  def initialize(command, attributes, request = nil)
    @command    = command
    @attributes = attributes
    @request    = request
  end

  def call
    http = Net::HTTP.new(http_host, 80)
    http.post(http_path, post_attributes, http_headers).body
  end

  private
    def attributes
      @attributes[:blog] ||= @@blog
      
      unless @command == 'verify-key'
        @attributes[:comment_type] ||= 'comment'
        
        unless @request.nil?
          @attributes[:user_ip]    = @request.remote_ip
          @attributes[:user_agent] = @request.headers["HTTP_USER_AGENT"]
          @attributes[:referrer]   = @request.headers["HTTP_REFERER"]
          @@extra_headers.each { |h| @attributes[h] = @request.headers[h] }
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
