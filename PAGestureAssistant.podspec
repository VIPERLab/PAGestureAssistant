#
# Be sure to run `pod lib lint PAGestureAssistant.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "PAGestureAssistant"
  s.version          = "0.2.6"
  s.summary          = "PAGestureAssistant is a drop-in UIViewController category for showing interaction tips and tutorials to users."

  s.description      = <<-DESC
                       PAGestureAssistant is a drop-in UIViewController category for showing interaction tips and tutorials to users that has predefined gestures for convenience and also the ability to define your own.
                       DESC

  s.homepage         = "https://github.com/ipedro/PAGestureAssistant"
  s.screenshots      = "http://i.imgur.com/DVnwy8S.gif"
  s.license          = 'MIT'
  s.author           = { "Pedro Almeida" => "ip4dro@gmail.com" }
  s.source           = { :git => "https://github.com/ipedro/PAGestureAssistant.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/ipedro'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  # s.resource_bundles = {
  #   'PAGestureAssistant' => ['Pod/Assets/*.png']
  # }

  s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit', 'Foundation', 'QuartzCore'
  s.dependency 'FrameAccessor', '~> 2.0'
end
