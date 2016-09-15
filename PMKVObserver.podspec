Pod::Spec.new do |s|
  s.name         = "PMKVObserver"
  s.version      = "2.0.1"
  s.summary      = "Modern thread-safe and type-safe key-value observing for Swift and Objective-C."
  s.description  = <<-DESC
PMKVObserver provides a safe block-based wrapper around Key-Value Observing, with APIs for both Obj-C and Swift. Features include:

* Thread-safety. Observers can be registered on a different thread than KVO notifications are sent on, and can be cancelled on yet another thread. An observer can even be cancelled from two thread simultaneously.
* Automatic unregistering when the observed object deallocates.
* Support for providing an observing object that is given to the block, and automatic unregistering when this observing object deallocates. This lets you call methods on `self` without retaining it or dealing with a weak reference.
* Thread-safety for the automatic deallocation. This protects against receiving messages on another thread while the object is deallocating.
* First-class support for both Obj-C and Swift, including strong typing in the Swift API.
                   DESC
  s.homepage     = "https://github.com/postmates/PMKVObserver"
  s.license      = { :type => "MIT", :file => "LICENSE-MIT" }
  s.author       = { "Kevin Ballard" => "kevin.ballard@postmates.com" }
  s.source       = { :git => "https://github.com/postmates/PMKVObserver.git", :tag => "v#{s.version}" }
  s.requires_arc = true


  s.subspec 'ObjC' do |ss|
      ss.source_files = 'PMKVObserver/**/*.{h,m}'
  end

  s.subspec 'Swift' do |ss|
      ss.source_files = 'PMKVObserver/**/*.{swift}'
      ss.dependency 'PMKVObserver/ObjC'
  end

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.9"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target = "9.0"
end
