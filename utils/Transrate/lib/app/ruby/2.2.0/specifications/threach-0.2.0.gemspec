# -*- encoding: utf-8 -*-
# stub: threach 0.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "threach"
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Bill Dueber"]
  s.date = "2010-08-10"
  s.description = "An addition to the Enumerable module that allows easy use of threaded each and each-like iterators"
  s.email = "bill@dueber.com"
  s.extra_rdoc_files = ["LICENSE", "README.markdown"]
  s.files = ["LICENSE", "README.markdown"]
  s.homepage = "http://github.com/billdueber/threach"
  s.rdoc_options = ["--charset=UTF-8"]
  s.rubygems_version = "2.4.6"
  s.summary = "Threaded each"

  s.installed_by_version = "2.4.6" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<thoughtbot-shoulda>, [">= 0"])
      s.add_development_dependency(%q<yard>, [">= 0"])
      s.add_development_dependency(%q<cucumber>, [">= 0"])
    else
      s.add_dependency(%q<thoughtbot-shoulda>, [">= 0"])
      s.add_dependency(%q<yard>, [">= 0"])
      s.add_dependency(%q<cucumber>, [">= 0"])
    end
  else
    s.add_dependency(%q<thoughtbot-shoulda>, [">= 0"])
    s.add_dependency(%q<yard>, [">= 0"])
    s.add_dependency(%q<cucumber>, [">= 0"])
  end
end
