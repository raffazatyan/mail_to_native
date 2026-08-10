#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint mail_to_native.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'mail_to_native'
  s.version          = '0.0.1'
  s.summary          = 'Pick an installed mail app and open its compose screen with subject and body prefilled.'
  s.description      = <<-DESC
Pick an installed mail app and open its compose screen with subject and body prefilled.
                       DESC
  s.homepage         = 'https://github.com/raffazatyan/mail_to_native'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Rafael Azatyan' => 'rafael.azatyan@moneteam.com' }
  s.source           = { :path => '.' }
  s.source_files = 'mail_to_native/Sources/mail_to_native/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'mail_to_native_privacy' => ['mail_to_native/Sources/mail_to_native/PrivacyInfo.xcprivacy']}
end
