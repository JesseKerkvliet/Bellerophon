# -*- encoding: utf-8 -*-
# stub: crb-blast 0.6.6 ruby lib

Gem::Specification.new do |s|
  s.name = "crb-blast"
  s.version = "0.6.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Chris Boursnell", "Richard Smith-Unna"]
  s.date = "2015-05-19"
  s.description = "See summary"
  s.email = "cmb211@cam.ac.uk"
  s.executables = ["crb-blast"]
  s.files = ["bin/crb-blast"]
  s.homepage = "https://github.com/cboursnell/crb-blast"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.6"
  s.summary = "Run conditional reciprocal best blast"

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<trollop>, ["~> 2.0"])
      s.add_runtime_dependency(%q<bio>, [">= 1.4.3", "~> 1.4"])
      s.add_runtime_dependency(%q<fixwhich>, [">= 1.0.2", "~> 1.0"])
      s.add_runtime_dependency(%q<threach>, [">= 0.2.0", "~> 0.2"])
      s.add_runtime_dependency(%q<bindeps>, [">= 1.0.3", "~> 1.0"])
      s.add_development_dependency(%q<rake>, [">= 10.3.2", "~> 10.3"])
      s.add_development_dependency(%q<turn>, [">= 0.9.7", "~> 0.9"])
      s.add_development_dependency(%q<simplecov>, [">= 0.8.2", "~> 0.8"])
      s.add_development_dependency(%q<shoulda-context>, [">= 1.2.1", "~> 1.2"])
      s.add_development_dependency(%q<coveralls>, ["~> 0.7"])
    else
      s.add_dependency(%q<trollop>, ["~> 2.0"])
      s.add_dependency(%q<bio>, [">= 1.4.3", "~> 1.4"])
      s.add_dependency(%q<fixwhich>, [">= 1.0.2", "~> 1.0"])
      s.add_dependency(%q<threach>, [">= 0.2.0", "~> 0.2"])
      s.add_dependency(%q<bindeps>, [">= 1.0.3", "~> 1.0"])
      s.add_dependency(%q<rake>, [">= 10.3.2", "~> 10.3"])
      s.add_dependency(%q<turn>, [">= 0.9.7", "~> 0.9"])
      s.add_dependency(%q<simplecov>, [">= 0.8.2", "~> 0.8"])
      s.add_dependency(%q<shoulda-context>, [">= 1.2.1", "~> 1.2"])
      s.add_dependency(%q<coveralls>, ["~> 0.7"])
    end
  else
    s.add_dependency(%q<trollop>, ["~> 2.0"])
    s.add_dependency(%q<bio>, [">= 1.4.3", "~> 1.4"])
    s.add_dependency(%q<fixwhich>, [">= 1.0.2", "~> 1.0"])
    s.add_dependency(%q<threach>, [">= 0.2.0", "~> 0.2"])
    s.add_dependency(%q<bindeps>, [">= 1.0.3", "~> 1.0"])
    s.add_dependency(%q<rake>, [">= 10.3.2", "~> 10.3"])
    s.add_dependency(%q<turn>, [">= 0.9.7", "~> 0.9"])
    s.add_dependency(%q<simplecov>, [">= 0.8.2", "~> 0.8"])
    s.add_dependency(%q<shoulda-context>, [">= 1.2.1", "~> 1.2"])
    s.add_dependency(%q<coveralls>, ["~> 0.7"])
  end
end
