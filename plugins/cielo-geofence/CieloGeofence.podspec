Pod::Spec.new do |s|
  s.name = 'CieloGeofence'
  s.version = '1.0.0'
  s.summary = 'Zone Cielo'
  s.license = 'Proprietary'
  s.homepage = 'https://cielomontreal.ca'
  s.author = 'Cielo'
  s.source = { :git => 'https://github.com/adilbaamar/caisse-cielo.git', :tag => s.version.to_s }
  s.source_files = 'ios/Sources/**/*.swift'
  s.ios.deployment_target = '15.0'
  s.dependency 'Capacitor'
  s.swift_version = '5.1'
end
