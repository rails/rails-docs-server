#!/usr/bin/env ruby

$:.unshift(File.expand_path('../lib', __dir__))

require 'lock_file'
require 'docs_generator'
require 'git_manager'
require 'fileutils'

if ARGV.size > 1 || ARGV.first == "-h" || ARGV.first == "--help"
  puts "USAGE: bin/generate_docs.rb [CHECKOUT_PATH]"
  exit
end

CHECKOUT_PATH = ARGV.first || File.join(File.dirname(__FILE__), '../checkout')

unless Dir.exists?(CHECKOUT_PATH)
  FileUtils.mkdir(CHECKOUT_PATH)
end

LockFile.acquiring('docs_generation.lock') do
  git_manager = GitManager.new(CHECKOUT_PATH)
  git_manager.update_master

  generator = DocsGenerator.new(CHECKOUT_PATH, git_manager)
  generator.generate
end
