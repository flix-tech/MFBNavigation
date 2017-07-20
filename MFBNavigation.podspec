Pod::Spec.new do |s|
  s.name         = "MFBNavigation"
  s.version      = "0.9.3"
  s.summary      = "Set of calsses for predictable navigation in iOS apps."
  s.homepage     = "https://github.com/flix-tech/MFBNavigation"

  s.license      = "MIT"
  s.author       = { "Nikolay Kasyanov" => "nikolay.kasyanov@flixbus.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/flix-tech/MFBNavigation.git", :tag => "#{s.version}" }

  s.source_files  = "Classes", "MFBNavigation/**/*.{h,m}"
  s.public_header_files = 'MFBNavigation/**/{MFBAlertNavigation,MFBAlertProxy,MFBModalNavigation,MFBModalNavigator,MFBPushPopNavigation,MFBPushPopNavigator,MFBSuspendibleUIQueue,MFBUnwindToken}.h'

  s.frameworks = "UIKit"

  s.requires_arc = true
end
