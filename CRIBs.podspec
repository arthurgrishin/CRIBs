Pod::Spec.new do |s|
  s.name             = "CRIBs"
  s.version          = "1.0.0"
  s.summary          = "Apple Combine + Uber RIBs"
  s.homepage         = "https://github.com/arthurgrishin/CRIBs"
  s.license          = 'Apache 2.0'
  s.author           = { "Arthur Grishin" => "arthur.grishin@me.com" }
  s.source           = { :git => "https://github.com/arthurgrishin/CRIBs.git", :tag => s.version }
  s.social_media_url = 'https://twitter.com/arthurgrishin'

  s.platform     = :ios, '13.0'
  s.requires_arc = true

  s.source_files = 'CRIBs/*.swift', 'CRIBs/**/*.swift'

  s.frameworks = 'Combine'
  s.module_name = 'CRIBs'
end
