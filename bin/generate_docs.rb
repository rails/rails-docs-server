#!/usr/bin/env ruby

$:.unshift(File.expand_path('../lib', __dir__))

require 'lock_file'
require 'docs_generator'
require 'git_manager'
require 'fileutils'
require 'optparse'

options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: bin/generate_docs.rb [options]"

  opts.on("-v", "--verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end

  opts.on(
    "-tTARGET",
    "--target=TARGET",
    "Target directory where to checkout the code, defaults to HOME"
  ) do |t|
    options[:target] = t
  end

  opts.on(
    "--tags=TAGS",
    "Comma-separated git tags (e.g. Rails versions) to checkout (format: vX.X.X, edge)"
  ) do |t|
    options[:tags] = t
  end
end.parse!

options[:verbose] = false if options[:verbose].nil?
options[:target] ||= Dir.home
options[:target].gsub!(/\/$/, '')

unless Dir.exists?(options[:target])
  FileUtils.mkdir(options[:target])
end

LockFile.acquiring('docs_generation.lock') do
  git_manager = GitManager.new(options[:target], verbose: options[:verbose])
  git_manager.update_master

  generator = DocsGenerator.new(
    options[:target],
    git_manager,
    verbose: options[:verbose],
    tags: options[:tags]
  )

  generator.generate
end
