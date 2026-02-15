# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rb_sys/extensiontask'

RSpec::Core::RakeTask.new(:spec)

GEMSPEC = Gem::Specification.load('bevy.gemspec')

RbSys::ExtensionTask.new('bevy', GEMSPEC) do |ext|
  ext.lib_dir = 'lib/bevy'
end

task build: :compile

task default: %i[compile spec]
