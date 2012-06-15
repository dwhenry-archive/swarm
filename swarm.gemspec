# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{swarm}
  s.version = "0.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["David Henry"]
  s.date = %q{2012-06-15}
  s.description = %q{TODO: longer description of your gem}
  s.email = %q{dw_henry@yahoo.com.au}
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    ".rspec",
    ".rvmrc",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "lib/rails_support_hacks.rb",
    "lib/swarm.rb",
    "lib/swarm/comms.rb",
    "lib/swarm/database.rb",
    "lib/swarm/database/mysql.rb",
    "lib/swarm/database/sqlite3.rb",
    "lib/swarm/directive.rb",
    "lib/swarm/drone.rb",
    "lib/swarm/files.rb",
    "lib/swarm/formatter/base.rb",
    "lib/swarm/formatter/fail_fast_progress_formatter.rb",
    "lib/swarm/formatter/yaml_formatter.rb",
    "lib/swarm/handler.rb",
    "lib/swarm/pilot/base.rb",
    "lib/swarm/pilot/feature_pilot.rb",
    "lib/swarm/pilot/spec_pilot.rb",
    "lib/swarm/queen.rb",
    "lib/swarm/record.rb",
    "lib/swarm/runner/feature.rb",
    "lib/swarm/runner/spec.rb",
    "lib/swarm/utilities/output_helper.rb",
    "lib/swarm/utilities/util.rb",
    "lib/swarm/utilities/voice.rb",
    "lib/tasks/swarm.rake",
    "main",
    "old_lib/lib/swarm.rb",
    "old_lib/lib/swarm/directive.rb",
    "old_lib/lib/swarm/drone.rb",
    "old_lib/lib/swarm/feature_formatter.rb",
    "old_lib/lib/swarm/formatter/base.rb",
    "old_lib/lib/swarm/formatter/fail_fast_progress_formatter.rb",
    "old_lib/lib/swarm/formatter/yaml_formatter.rb",
    "old_lib/lib/swarm/output_helper.rb",
    "old_lib/lib/swarm/pilot/base.rb",
    "old_lib/lib/swarm/pilot/feature_pilot.rb",
    "old_lib/lib/swarm/pilot/spec_pilot.rb",
    "old_lib/lib/swarm/queen.rb",
    "old_lib/lib/swarm/queen_feature_formatter.rb",
    "old_lib/lib/swarm/queen_spec_formatter.rb",
    "old_lib/lib/swarm/spec_formatter.rb",
    "old_lib/lib/swarm/util.rb",
    "old_lib/lib/swarm/voice.rb",
    "spec/spec_helper.rb",
    "spec/swarm/comms_spec.rb",
    "spec/swarm/directive_spec.rb",
    "spec/swarm_spec.rb",
    "swarm.gemspec",
    "test_app/.gitignore",
    "test_app/Gemfile",
    "test_app/Gemfile.lock",
    "test_app/README",
    "test_app/Rakefile",
    "test_app/app/assets/images/rails.png",
    "test_app/app/assets/javascripts/application.js",
    "test_app/app/assets/stylesheets/application.css",
    "test_app/app/controllers/application_controller.rb",
    "test_app/app/helpers/application_helper.rb",
    "test_app/app/mailers/.gitkeep",
    "test_app/app/models/.gitkeep",
    "test_app/app/views/layouts/application.html.erb",
    "test_app/config.ru",
    "test_app/config/application.rb",
    "test_app/config/boot.rb",
    "test_app/config/database.yml",
    "test_app/config/environment.rb",
    "test_app/config/environments/development.rb",
    "test_app/config/environments/production.rb",
    "test_app/config/environments/test.rb",
    "test_app/config/initializers/backtrace_silencers.rb",
    "test_app/config/initializers/inflections.rb",
    "test_app/config/initializers/mime_types.rb",
    "test_app/config/initializers/secret_token.rb",
    "test_app/config/initializers/session_store.rb",
    "test_app/config/initializers/wrap_parameters.rb",
    "test_app/config/locales/en.yml",
    "test_app/config/routes.rb",
    "test_app/db/schema.rb",
    "test_app/db/seeds.rb",
    "test_app/lib/assets/.gitkeep",
    "test_app/lib/tasks/.gitkeep",
    "test_app/log/.gitkeep",
    "test_app/public/404.html",
    "test_app/public/422.html",
    "test_app/public/500.html",
    "test_app/public/favicon.ico",
    "test_app/public/index.html",
    "test_app/public/robots.txt",
    "test_app/script/rails",
    "test_app/spec/multiple_pass/pass_1_spec.rb",
    "test_app/spec/multiple_pass/pass_2_spec.rb",
    "test_app/spec/multiple_passes/pass_1_spec.rb",
    "test_app/spec/multiple_passes/pass_2_spec.rb",
    "test_app/spec/multiple_passes/pass_3_spec.rb",
    "test_app/spec/multiple_passes/pass_4_spec.rb",
    "test_app/spec/multiple_passes/pass_5_spec.rb",
    "test_app/spec/multiple_passes/pass_6_spec.rb",
    "test_app/spec/pass_and_fail/fail_spec.rb",
    "test_app/spec/pass_and_fail/pass_spec.rb",
    "test_app/spec/single_fail/test_spec.rb",
    "test_app/spec/single_pass/test_spec.rb",
    "test_app/test/fixtures/.gitkeep",
    "test_app/test/functional/.gitkeep",
    "test_app/test/integration/.gitkeep",
    "test_app/test/performance/browsing_test.rb",
    "test_app/test/test_helper.rb",
    "test_app/test/unit/.gitkeep",
    "test_app/vendor/assets/stylesheets/.gitkeep",
    "test_app/vendor/plugins/.gitkeep"
  ]
  s.homepage = %q{http://github.com/dwhenry/swarm}
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{TODO: one-line summary of your gem}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rails>, ["= 3.1.3"])
      s.add_development_dependency(%q<sqlite3>, [">= 0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.8.0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.6.2"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
      s.add_development_dependency(%q<ruby-debug19>, [">= 0"])
      s.add_development_dependency(%q<cucumber>, [">= 0"])
    else
      s.add_dependency(%q<rails>, ["= 3.1.3"])
      s.add_dependency(%q<sqlite3>, [">= 0"])
      s.add_dependency(%q<rspec>, ["~> 2.8.0"])
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.6.2"])
      s.add_dependency(%q<rcov>, [">= 0"])
      s.add_dependency(%q<ruby-debug19>, [">= 0"])
      s.add_dependency(%q<cucumber>, [">= 0"])
    end
  else
    s.add_dependency(%q<rails>, ["= 3.1.3"])
    s.add_dependency(%q<sqlite3>, [">= 0"])
    s.add_dependency(%q<rspec>, ["~> 2.8.0"])
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.6.2"])
    s.add_dependency(%q<rcov>, [">= 0"])
    s.add_dependency(%q<ruby-debug19>, [">= 0"])
    s.add_dependency(%q<cucumber>, [">= 0"])
  end
end

