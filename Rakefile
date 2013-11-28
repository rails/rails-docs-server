require 'rake/testtask'

task :default => :test

Rake::TestTask.new do |t|
  t.test_files = Dir.glob('test/test_*.rb') - %w(test/test_helper.rb)
end

namespace :test do
  desc 'run all the suite, including docs generation (takes a long time)'
  task :all do
    ENV['TEST_DOCS_GENERATION'] = '1'
    Rake::Task['test'].invoke
  end
end
