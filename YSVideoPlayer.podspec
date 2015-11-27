Pod::Spec.new do |s|
  s.name = 'YSVideoPlayer'
  s.version = '0.0.3'
  s.summary = 'YSVideoPlayer'
  s.homepage = 'https://github.com/yusuga/YSMoviePlayer'
  s.license = 'MIT'
  s.author = 'Yu Sugawara'
  s.source = { :git => 'https://github.com/yusuga/YSVideoPlayer.git', :tag => s.version.to_s }
  s.platform = :ios, '7.0'
  s.ios.deployment_target = '7.0'
  s.source_files = 'Classes/YSVideoPlayer/**/*.{h,m}'
  s.resources    = 'Classes/YSVideoPlayer/**/*.{storyboard,lproj}'
  s.requires_arc = true
  s.compiler_flags = '-fmodules'  
  
  s.dependency 'RMUniversalAlert'
  s.dependency 'KVOController'
end