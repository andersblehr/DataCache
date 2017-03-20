Pod::Spec.new do |s|
  s.name         = "DataCache"
  s.version      = "1.0.0"
  s.summary      = "JSON to Core Data and back."
  s.description  = <<-DESC
                   DataCache is a thin layer on top of Core Data that seamlessly consumes, persists and produces JSON data, converting between `snake_case` and `camelCase` as needed while establishing and preserving relationships between Core Data objects created from JSON records.
                   DESC
  s.homepage     = "https://github.com/andersblehr/DataCache"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Anders Blehr" => "anders@andersblehr.co" }
  s.social_media_url   = "http://twitter.com/andersblehr"
  s.platform     = :ios, "9.3"

  #  When using multiple platforms
  # s.ios.deployment_target = "5.0"
  # s.osx.deployment_target = "10.7"
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"

  s.source       = { :git => "https://github.com/andersblehr/DataCache.git", :tag => "#{s.version}" }
  s.source_files  = "DataCache/**/*.{h,swift}"
  s.requires_arc = true
end
