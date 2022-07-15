# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ddtrace/version'

Gem::Specification.new do |spec|
  spec.name                  = 'ddtrace'
  spec.version               = DDTrace::VERSION::STRING
  spec.required_ruby_version = [">= #{DDTrace::VERSION::MINIMUM_RUBY_VERSION}",
                                "< #{DDTrace::VERSION::MAXIMUM_RUBY_VERSION}"]
  spec.required_rubygems_version = '>= 2.0.0'
  spec.authors               = ['Datadog, Inc.']
  spec.email                 = ['dev@datadoghq.com']

  spec.summary     = 'Datadog tracing code for your Ruby applications'
  spec.description = <<-DESC.gsub(/^\s+/, '')
    ddtrace is Datadog’s tracing client for Ruby. It is used to trace requests
    as they flow across web servers, databases and microservices so that developers
    have great visiblity into bottlenecks and troublesome requests.
  DESC

  spec.homepage = 'https://github.com/DataDog/dd-trace-rb'
  spec.license  = 'BSD-3-Clause'

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  # rubocop:disable all
  # DEV: `spec.files` is more problematic than a simple Rubocop pass.
  spec.files =
    `git ls-files -z`
    .split("\x0")
    .reject { |f| f.match(%r{^(test|spec|features|[.]circleci|[.]github|[.]dd-ci|benchmarks|gemfiles|integration|tasks|sorbet|yard)/}) }
    .reject do |f|
      ['.dockerignore', '.env', '.gitattributes', '.gitlab-ci.yml', '.rspec', '.rubocop.yml',
       '.rubocop_todo.yml', '.simplecov', 'Appraisals', 'Gemfile', 'Rakefile', 'docker-compose.yml', '.pryrc', '.yardopts'].include?(f)
    end
  # rubocop:enable all
  spec.executables   = ['ddtracerb']
  spec.require_paths = ['lib']

  # Used to serialize traces to send them to the Datadog Agent.
  spec.add_dependency 'msgpack'

  # Used by the profiler native extension to support older Rubies (see NativeExtensionDesign.md for notes)
  #
  # Most versions of this gem work for us, but 0.10.16 includes an important fix for Ruby 2.5.4 to 2.5.9
  # (https://github.com/ruby-debug/debase-ruby_core_source/pull/6) so we should keep that as a lower bound going
  # forward.
  #
  # we're pinning it at the latest available version and will manually bump the dependency as needed.
  spec.add_dependency 'debase-ruby_core_source', '= 0.10.16'

  # Used by appsec
  spec.add_dependency 'libddwaf', '~> 1.3.0.2.0'

  # Used by profiling (and possibly others in the future)
  spec.add_dependency 'libdatadog', '~> 0.7.0.1.0'

  spec.extensions = ['ext/ddtrace_profiling_native_extension/extconf.rb', 'ext/ddtrace_profiling_loader/extconf.rb']
end
