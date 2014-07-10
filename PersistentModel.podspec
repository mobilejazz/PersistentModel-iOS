Pod::Spec.new do |s|

  s.name         = "PersistentModel"
  s.version      = "0.1.0"
  s.summary      = "Easy creation for key-value storage model for iOS and OS X."
  s.description  = "PersistentModel uses the same concept of context and persistent store as CoreData does mixed with a NSCoding protocol to encode and decode model objects.\nWrite down your classes by code and add the coding protocol and you will have a full operational persistent object management. It’s fast, simple, and very useful when there is no need to create complex queries among all set of objects.\nAlso, PersistentModel supports multiple key accessing via KVC, meaning you can define additional keys to access and retrieve your properties. This is very useful to set values from dictionaries whose come from some external server."
  s.homepage     = "https://github.com/mobilejazz/PersistentModel-iOS"
  s.license      = { :type => 'Apache License, Version 2.0', :file => 'LICENSE.txt' }
  s.author             = { "Mobile Jazz" => "info@mobilejazz.cat" }
  s.social_media_url = "http://twitter.com/mobilejazz"
  s.platform     = :ios, '6.0'
  s.source       = { :git => "https://github.com/mobilejazz/PersistentModel-iOS.git", :tag => "0.1.0" }
  s.source_files = 'Source/*.{h,m}'
  s.framework  = 'UIKit'
  s.dependency   'FMDB'
  s.requires_arc = true
  
end
