# Uncomment the next line to define a global platform for your project
platform :ios, '11.0'

abstract_target 'Shared' do
    target 'ExampleNativeDApp'
    # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
    use_frameworks!

    pod 'Bitski', :git => 'https://github.com/BitskiCo/BitskiSDK.git', :branch => 'integration/web3-0.3.0'
    pod 'Web3', :git => 'https://github.com/BitskiCo/Web3.swift.git', :branch => 'feature/contracts'
    pod 'Web3/PromiseKit', :git => 'https://github.com/BitskiCo/Web3.swift.git', :branch => 'feature/contracts'
    pod 'Sentry'
    pod 'PromiseKit'
end
