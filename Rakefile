require 'rake'
require 'rake/testtask'
require File.expand_path("../lib/akismet.rb", __FILE__)

task :default => :test

desc 'Run tests.'
Rake::TestTask.new('test') do |t|
  t.libs << 'test'
  t.test_files = Dir['test/*_test.rb']
#  t.verbose = true
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    root_files = FileList["README.rdoc"]
    s.name = "ruby-akismet"
    s.version = Akismet::VERSION.dup
    s.summary = "Ruby library for the Akismet service."
    s.email = "ysbaddaden@gmail.com"
    s.homepage = "http://github.com/ysbaddaden/ruby-akismet"
    s.description = "Akismet is basically a big machine that sucks up all the data it possibly can, looks for patterns, and learns from its mistakes. Thus far it has been highly effective at stopping spam and adapting to new techniques and attempts to evade it, and time will tell how it stands up."
    s.authors = ['Julien Portalier']
    s.files =  root_files + FileList["{lib}/*"]
    s.extra_rdoc_files = root_files
  end

  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler, or one of its dependencies, is not available. Install it with: gem install jeweler"
end

