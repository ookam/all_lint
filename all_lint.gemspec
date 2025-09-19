require_relative "lib/all_lint/version"

Gem::Specification.new do |spec|
  spec.name          = "all_lint"
  spec.version       = AllLint::VERSION
  spec.authors       = ["ookam"]
  spec.email         = [""]

  spec.summary       = "Run multiple linters sequentially from one YAML"
  spec.description   = "Minimal runner that reads .all-lint.yml and runs each linter's command with filtered files."
  spec.homepage      = "https://example.com/"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*", "exe/*", "README.md", "LICENSE"]
  spec.bindir        = "exe"
  spec.executables   = ["all_lint"]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.1"

  spec.metadata = {
    "source_code_uri" => "",
    "changelog_uri" => ""
  }
end
