# frozen_string_literal: true

require_relative "lib/rpms_sql/version"

Gem::Specification.new do |spec|
  spec.name        = "rpms-sql"
  spec.version     = RpmsSql::VERSION
  spec.authors     = [ "Lakeraven LLC" ]
  spec.email       = [ "engineering@lakeraven.com" ]
  spec.summary     = "Ruby client for IRIS-projected RPMS data via PostgreSQL wire protocol"
  spec.description = "Companion to rpms-rpc. Talks SQL to InterSystems IRIS over the PostgreSQL " \
                     "wire protocol (via iris-pgwire) for high-throughput access to FileMan-projected " \
                     "tables. No Rails dependency."
  spec.homepage    = "https://github.com/lakeraven/rpms-sql"
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.4.0"

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"]   = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    %x[git ls-files -z].split("\x0").reject { |f| f.match(%r{^(test/|\.|Gemfile|Rakefile)}) }
  end
  spec.require_paths = [ "lib" ]

  spec.add_dependency "pg", "~> 1.5"
end
