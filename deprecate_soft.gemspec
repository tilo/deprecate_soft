# frozen_string_literal: true

require_relative "lib/deprecate_soft/version"

Gem::Specification.new do |spec|
  spec.name = "deprecate_soft"
  spec.version = DeprecateSoft::VERSION
  spec.authors = ["Tilo Sloboda"]
  spec.email = ["tilo.sloboda@gmail.com"]

  spec.summary     = "Soft deprecation wrapper for Ruby methods with customizable tracking hooks"
  spec.description = <<~DESC
    DeprecateSoft is a lightweight Ruby gem that lets you softly deprecate methods
    in your codebase without breaking functionality. It wraps existing instance or
    class methods and lets you plug in custom before/after hooks for tracking usage
    via logging, Redis, DataDog, or any other observability tools.

    This is especially useful in large codebases where you want to safely remove
    legacy methods, but first need insight into whether and where they're still
    being called.

    Hooks are configured once globally and apply project-wide. Fully compatible
    with Rails or plain Ruby applications.
  DESC
  spec.homepage = "https://github.com/tilo/deprecate_soft"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/tilo/deprecate_soft/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
