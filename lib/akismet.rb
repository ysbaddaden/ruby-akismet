require 'net/http'

# Akismet compatible library for checking spams.
# 
# Before calling any method, you must configure a blog (your website
# homepage) and your Akismet or Typepad Antispam API key.
# 
#   Akismet.key  = '123456789'
#   Akismet.blog = 'http://example.com'
# 
class Akismet
  # Raised whenever a command is issued but the API key hasn't been configured.
  class MissingKey < StandardError
  end

  VERSION     = '1.0.0.rc'.freeze
  API_VERSION = '1.1'.freeze

  class << self
    # Configure an alternate API host server (defaults to
    # <tt>'rest.akismet.com'</tt>).
    def host=(host)
      @@host = host
    end

    def host
      @@host
    end

    # Configure your API key (required).
    def key=(key)
      @@key = key
    end

    def key
      @@key
    end

    # Configure your homepage URL (required).
    def blog=(blog)
      @@blog = blog
    end

    def blog
      @@blog
    end

    def logger=(logger)
      @@logger = logger
    end

    def logger
      @@logger
    end

    # Configure an Array of extra HTTP headers to pass to the Akismet server
    # to extract from the request object.
    # 
    # Defaults to:
    # 
    #   [
    #     'HTTP_REMOTE_ADDR',
    #     'HTTP_CLIENT_IP',
    #     'HTTP_X_FORWARDED_FOR',
    #     'HTTP_CONNECTION'
    #   ]
    # 
    # Examples:
    # 
    #   # replaces the actual list:
    #   Akismet.extra_headers = ['HTTP_REMOTE_ADDR']
    #   
    #   # appends a header to the list:
    #   Akismet.extra_headers << 'HTTP_ACCEPT_CHARSET'
    #   
    #   # appends multiple headers to the list:
    #   Akismet.extra_headers << ['HTTP_ACCEPT_CHARSET', 'HTTP_ACCEPT_LANGUAGE']
    # 
    def extra_headers=(headers)
      @@extra_headers = headers
    end

    def extra_headers
      @@extra_headers.flatten!
      @@extra_headers.uniq!
      @@extra_headers
    end

    # Checks if a key is valid or not.
    def valid_key?(key)
      call('verify-key', :key => key) == "valid"
    end

    # Checks if a comment is spam.
    # 
    # Required attributes:
    # 
    # - <tt>:permalink</tt>
    # - <tt>:comment_author</tt>
    # - <tt>:comment_author_url</tt>
    # - <tt>:comment_author_email</tt>
    # - <tt>:comment_content</tt>
    # 
    # Those are also required, but will be extracted from the
    # +request+ object if available:
    # 
    # - <tt>:user_ip</tt>
    # - <tt>:user_agent</tt>
    # - <tt>:referrer</tt> (check spelling!)
    # 
    # Plus more relevant HTTP headers from extra_headers.
    # 
    # Note that request is supposed to be an instance of
    # ActionDispatch::Request or ActionController::Request. If not, the object
    # must respond to +remote_ip+ (IP as string) and +headers+
    # (an array of HTTP headers).
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
    # Takes the same attributes than spam?.
    def submit_ham(attributes)
      call('submit-ham', attributes)
    end

    private
      def call(command, attributes, request = nil)
        new(command, attributes, request).call
      end
  end

  self.host   = 'rest.akismet.com'
  self.key    = nil
  self.blog   = nil
  self.logger = nil
  self.extra_headers = [
    'HTTP_REMOTE_ADDR',
    'HTTP_CLIENT_IP',
    'HTTP_X_FORWARDED_FOR',
    'HTTP_CONNECTION'
  ]

  def initialize(command, attributes, request = nil)
    @command    = command
    @attributes = attributes
    @request    = request
  end

  def call
    self.class.logger.debug { "  AKISMET  #{@command} #{post_attributes}" } if self.class.logger
    
    http = Net::HTTP.new(http_host, 80)
    http.post(http_path, post_attributes, http_headers).body
  end

  private
    def attributes
      @attributes[:blog] ||= self.class.blog
      
      unless @command == 'verify-key'
        @attributes[:comment_type] ||= 'comment'
        
        unless @request.nil?
          @attributes[:user_ip]    = @request.remote_ip
          @attributes[:user_agent] = @request.headers["HTTP_USER_AGENT"]
          @attributes[:referrer]   = @request.headers["HTTP_REFERER"]
          
          self.class.extra_headers.each do |h|
            @attributes[h] = @request.headers[h]
          end
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
        raise MissingKey.new("Required Akismet.key is nil.") unless self.class.key
        "#{self.class.key}.#{self.class.host}"
      else
        "#{self.class.host}"
      end
    end

    def http_path
      "/#{API_VERSION}/#{@command}"
    end
end
