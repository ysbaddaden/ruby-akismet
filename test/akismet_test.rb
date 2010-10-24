require 'test/unit'
require 'logger'

require 'rubygems'
gem 'actionpack'
gem 'rack'
require 'action_dispatch'

require File.expand_path("../../lib/akismet.rb", __FILE__)

class AkismetTest < Test::Unit::TestCase
  def setup
    Akismet.host = 'api.antispam.typepad.com'
    Akismet.key  = '123456789'
    Akismet.blog = 'http://www.example.com/'
    
    Akismet.logger = Logger.new(File.expand_path("../test.log", __FILE__))
    Akismet.logger.level = Logger::DEBUG
  end

  def test_valid_key
    assert Akismet.valid_key?(Akismet.key)
  end

#  def test_invalid_key
#    assert !Akismet.valid_key?('abc123')
#  end

  def test_should_not_fail_with_no_logger
    Akismet.logger = nil
    assert Akismet.valid_key?(Akismet.key)
  end

  def test_should_raise_missing_key
    Akismet.key = nil
    assert_raise(Akismet::MissingKey) { Akismet.spam?(full_spam_attributes) }
  end

  def test_should_not_raise_missing_key_for_valid_key
    Akismet.key = nil
    assert_nothing_raised { Akismet.valid_key?('123456789') }
  end

  def test_extra_headers
    Akismet.extra_headers = ['HTTP_REMOTE_ADDR']
    assert_equal ['HTTP_REMOTE_ADDR'], Akismet.extra_headers
    
    Akismet.extra_headers << 'HTTP_CLIENT_IP'
    assert_equal ['HTTP_REMOTE_ADDR', 'HTTP_CLIENT_IP'], Akismet.extra_headers
    
    Akismet.extra_headers << ['HTTP_X_FORWARDED_FOR', 'HTTP_CONNECTION']
    assert_equal ['HTTP_REMOTE_ADDR', 'HTTP_CLIENT_IP', 'HTTP_X_FORWARDED_FOR', 'HTTP_CONNECTION'],
      Akismet.extra_headers
  end

  def test_spam_with_actiondispatch_request
    assert Akismet.spam?(spam_attributes, actiondispatch_request)
  end

  def test_ham_with_actiondispatch_request
    assert !Akismet.spam?(ham_attributes, actiondispatch_request)
  end

  def test_spam
    assert Akismet.spam?(full_spam_attributes)
  end

  def test_not_spam
    assert !Akismet.spam?(full_ham_attributes)
  end

  def test_ham
    assert Akismet.ham?(full_ham_attributes)
  end

  def test_not_ham
    assert !Akismet.ham?(full_spam_attributes)
  end

  def test_submit_spam
    assert Akismet.submit_spam(spam_attributes)
  end

  def test_submit_ham
    assert Akismet.submit_ham(ham_attributes)
  end

  protected
    def ham_attributes
      {
        :permalink            => 'http://www.example.com/posts/1',
        :comment_author       => 'Julien Portalier',
        :comment_author_url   => 'http://ysbaddaden.wordpress.com/',
        :comment_author_email => 'julien@example.com',
        :comment_content      => 'this is a normal comment'
      }
    end

    def spam_attributes
      ham_attributes.merge(:comment_author => 'viagra-test-123')
    end

    def additional_attributes
      {
        :user_ip    => '127.0.0.1',
        :user_agent => 'Mozilla/5.0 (X11; U; Linux i686; fr-FR) AppleWebKit/534.7 (KHTML, like Gecko) Ubuntu/10.04 Chromium/7.0.517.41 Chrome/7.0.517.41 Safari/534.7',
        :referrer   => 'http://www.example.com/posts'
      }
    end

    def full_spam_attributes
      spam_attributes.merge(additional_attributes)
    end

    def full_ham_attributes
      ham_attributes.merge(additional_attributes)
    end

    def actiondispatch_request
      request = ActionDispatch::TestRequest.new(
        'HTTP_REFERER'     => 'http://www.example.com/posts/1',
        'HTTP_REMOTE_ADDR' => '127.0.0.1',
        'HTTP_USER_AGENT'  => 'Mozilla/5.0 (X11; U; Linux i686; fr-FR) AppleWebKit/534.7 (KHTML, like Gecko) Ubuntu/10.04 Chromium/7.0.517.41 Chrome/7.0.517.41 Safari/534.7',
        'HTTP_CONNECTION'  => 'close'
      )
      request.remote_addr = '127.0.0.1'
      request
    end
end
