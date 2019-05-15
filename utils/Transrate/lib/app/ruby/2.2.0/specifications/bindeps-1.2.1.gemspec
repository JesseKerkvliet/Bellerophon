# -*- encoding: utf-8 -*-
# stub: bindeps 1.2.1 ruby lib

Gem::Specification.new do |s|
  s.name = "bindeps"
  s.version = "1.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Richard Smith-Unna", "Chris Boursnell"]
  s.date = "2016-04-03"
  s.description = "binary dependency management for ruby gems"
  s.email = ["rds45@cam.ac.uk"]
  s.homepage = "https://github.com/Blahah/bindeps"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.6"
  s.summary = "binary dependency management for ruby gems"

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<fixwhich>, [">= 1.0.2", "~> 1.0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.3"])
      s.add_development_dependency(%q<rake>, [">= 10.3.2", "~> 10.3"])
      s.add_development_dependency(%q<turn>, [">= 0.9.7", "~> 0.9"])
      s.add_development_dependency(%q<minitest>, [">= 4.7.5", "~> 4"])
      s.add_development_dependency(%q<simplecov>, [">= 0.8.2", "~> 0.8"])
      s.add_development_dependency(%q<shoulda-context>, [">= 1.2.1", "~> 1.2"])
      s.add_development_dependency(%q<coveralls>, ["~> 0.7"])
    else
      s.add_dependency(%q<fixwhich>, [">= 1.0.2", "~> 1.0"])
      s.add_dependency(%q<bundler>, ["~> 1.3"])
      s.add_dependency(%q<rake>, [">= 10.3.2", "~> 10.3"])
      s.add_dependency(%q<turn>, [">= 0.9.7", "~> 0.9"])
      s.add_dependency(%q<minitest>, [">= 4.7.5", "~> 4"])
      s.add_dependency(%q<simplecov>, [">= 0.8.2", "~> 0.8"])
      s.add_dependency(%q<shoulda-context>, [">= 1.2.1", "~> 1.2"])
      s.add_dependency(%q<coveralls>, ["~> 0.7"])
    end
  else
    s.add_dependency(%q<fixwhich>, [">= 1.0.2", "~> 1.0"])
    s.add_dependency(%q<bundler>, ["~> 1.3"])
    s.add_dependency(%q<rake>, [">= 10.3.2", "~> 10.3"])
    s.add_dependency(%q<turn>, [">= 0.9.7", "~> 0.9"])
    s.add_dependency(%q<minitest>, [">= 4.7.5", "~> 4"])
    s.add_dependency(%q<simplecov>, [">= 0.8.2", "~> 0.8"])
    s.add_dependency(%q<shoulda-context>, [">= 1.2.1", "~> 1.2"])
    s.add_dependency(%q<coveralls>, ["~> 0.7"])
  end
end
