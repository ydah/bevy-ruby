# frozen_string_literal: true

require_relative 'lib/bevy/version'

Gem::Specification.new do |spec|
  spec.name = 'bevy'
  spec.version = Bevy::VERSION
  spec.authors = ['Yudai Takada']
  spec.email = ['t.yudai92@gmail.com']

  spec.summary = 'Ruby bindings for the Bevy game engine'
  spec.description = 'Ruby bindings for Bevy Engine, providing ECS architecture and game development capabilities'
  spec.homepage = 'https://github.com/ydah/bevy-ruby'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir[
    'lib/**/*.rb',
    'ext/**/*.{rs,rb,toml}',
    'crates/**/*.{rs,toml}',
    'Cargo.toml',
    'Cargo.lock',
    'LICENSE*',
    'README.md'
  ]
  spec.require_paths = ['lib']
  spec.extensions = ['ext/bevy/extconf.rb']

  spec.add_dependency 'rb_sys', '>= 0.9'
end
