#
# Be sure to run `pod lib lint Magics.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Magics'
  s.version          = '2.2.1'
  s.summary          = 'Magic server communications'

  s.description      = <<-DESC
Magics is a library that makes client-server communication looks like a magic. It takes on iself as much as possible, at the same time providing flexibilty.
                       DESC

  s.homepage         = 'https://github.com/Anvics/Magics.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Nikita Arkhipov' => 'nikitarkhipov@gmail.com' }
  s.source           = { :git => 'https://github.com/Anvics/Magics.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'
  s.osx.deployment_target = '10.12'

  s.source_files = 'Magics/Classes/**/*'
  
  s.frameworks = 'Foundation'
end
