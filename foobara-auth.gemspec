require_relative "version"

Gem::Specification.new do |spec|
  spec.name = "foobara-auth"
  spec.version = Foobara::Auth::VERSION
  spec.authors = ["Miles Georgi"]
  spec.email = ["azimux@gmail.com"]

  spec.summary = "Provides various auth domain commands and models"
  spec.homepage = "https://github.com/foobara/auth"
  spec.license = "Apache-2.0 OR MIT"
  spec.required_ruby_version = Foobara::Auth::MINIMUM_RUBY_VERSION

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir[
    "lib/**/*",
    "src/**/*",
    "LICENSE*.txt",
    "README.md",
    "CHANGELOG.md"
  ]

  spec.add_dependency "argon2"
  spec.add_dependency "jwt"

  spec.add_dependency "foobara", ">= 0.1.0", "< 2.0.0"

  spec.require_paths = ["lib"]
  spec.metadata["rubygems_mfa_required"] = "true"
end
