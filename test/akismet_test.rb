require 'test/unit'
require 'logger'
require File.expand_path("../../lib/akismet.rb", __FILE__)

# TODO: Test with an ActionDispatch::TestRequest object.
class AkismetTest < Test::Unit::TestCase
  def setup
    Akismet.host = 'api.antispam.typepad.com'
    Akismet.key  = '123456789'
    Akismet.blog = 'http://www.example.com/'
    
    Akismet.logger = Logger.new(File.expand_path("../test.log", __FILE__))
    Akismet.logger.level = Logger::DEBUG
  end

  def valid_attributes
    {
      :user_ip              => '127.0.0.1',
      :user_agent           => 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X 10.5; en-US; rv:1.9.0.3) Gecko/2008092414 Firefox/3.0.3',
      :referrer             => 'http://www.example.com/posts',
      :permalink            => 'http://www.example.com/posts/1',
      :comment_author       => 'Julien Portalier',
      :comment_author_url   => 'http://ysbaddaden.wordpress.com/',
      :comment_author_email => 'julien@example.com',
      :comment_content      => 'this is a normal comment',
    }
  end

  def invalid_attributes
    invalid = valid_attributes.dup
    invalid[:comment_author] = 'viagra-test-123'
    invalid
  end

  def test_valid_key
    assert Akismet.valid_key?('123456789')
  end

#  def test_invalid_key
#    assert !Akismet.valid_key?('abc123')
#  end

  def test_should_not_fail_with_no_logger
    Akismet.logger = nil
    assert Akismet.valid_key?('123456789')
  end

  def test_should_raise_missing_key
    Akismet.key = nil
    assert_raise(Akismet::MissingKey) { Akismet.spam?(valid_attributes) }
  end

  def test_should_not_raise_missing_key_for_valid_key
    Akismet.key = nil
    assert_nothing_raised { Akismet.valid_key?('123456789') }
  end

  def test_spam
    assert Akismet.spam?(invalid_attributes)
  end

  def test_not_spam
    assert !Akismet.spam?(valid_attributes)
  end

  def test_ham
    assert Akismet.ham?(valid_attributes)
  end

  def test_not_ham
    assert !Akismet.ham?(invalid_attributes)
  end

  def test_submit_spam
  end

  def test_submit_ham
  end
end
