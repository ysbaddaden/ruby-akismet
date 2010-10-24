require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require File.expand_path("../lib/akismet.rb", __FILE__)

task :default => :test

desc 'Run tests.'
Rake::TestTask.new('test') do |t|
  t.libs << 'test'
  t.test_files = Dir['test/*_test.rb']
#  t.verbose = true
end

desc 'Generate documentation for ruby-akismet.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'ruby-akismet'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/*.rb')
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    root_files = FileList["README.rdoc"]
    s.name = "ruby-akismet"
    s.version = Akismet::VERSION.dup
    s.summary = "Ruby library for the Akismet anti-spam service."
    s.email = "ysbaddaden@gmail.com"
    s.homepage = "http://github.com/ysbaddaden/ruby-akismet"
    s.description = "Ruby library for Akismet and Typepad Antispam with simplified integration into a Rails application."
    s.authors = ['Julien Portalier']
    s.files =  root_files + FileList["{lib}/*"]
    s.extra_rdoc_files = root_files
  end

  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler, or one of its dependencies, is not available. Install it with: gem install jeweler"
end

