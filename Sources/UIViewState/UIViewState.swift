//
//  UIViewState.swift
//  Demo
//
//  Created by 庄黛淳华 on 2021/1/20.
//

import UIKit

func inMain(_ action: @escaping () -> Void) {
	if Thread.isMainThread {
		action()
	} else {
		DispatchQueue.main.async(execute: action)
	}
}
public protocol UIViewState: UIResponder {
	func updateViews()
	typealias State<T> = _UIViewStateAnyState<Self, T>
}
private class UIViewStateProxy {
	private init () { }
	static let shared = UIViewStateProxy()
	var updates = Set<AnyHashable>()
	
	private var didRegistered = false
	func registerInRunloopIfNeed() {
		if didRegistered { return }
		
		// call at the end of the runloop before CATransaction begins updating
		
		/*
		160 / 1999000 / _beforeCACommitHandler
		160 / 2000000 / _ZN2CA11Transaction17observer_callbackEP19__CFRunLoopObservermPv
		160 / 2001000 / _afterCACommitHandler
		*/
		
		let obs = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, CFRunLoopActivity.beforeWaiting.rawValue, true, 1999000-1) { (obs, activity) in
			
			for view in self.updates.compactMap({
				$0.base as? UIViewState
			}){
				view.updateViews()
			}
			self.updates.removeAll()
			CFRunLoopRemoveObserver(CFRunLoopGetMain(), obs, .commonModes)
			self.didRegistered = false
		}
		CFRunLoopAddObserver(CFRunLoopGetMain(), obs, .commonModes)
	}
}
@propertyWrapper
public struct _UIViewStateAnyState<UIViewStateType: UIViewState, Value> {
	public typealias ValueKeyPath = ReferenceWritableKeyPath<UIViewStateType, Value>
	public typealias SelfKeyPath = ReferenceWritableKeyPath<UIViewStateType, Self>
	
	public static subscript(
		_enclosingInstance instance: UIViewStateType,
		wrapped wrappedKeyPath: ValueKeyPath,
		storage storageKeyPath: SelfKeyPath
	) -> Value {
		get {
			return instance[keyPath: storageKeyPath].wrappedValue
		}
		set {
			let wrapper = instance[keyPath: storageKeyPath]
			if let filter = wrapper.filter, filter(wrapper.wrappedValue, newValue) {
				return
			}
			let options = wrapper.updateOptions
			instance[keyPath: storageKeyPath].wrappedValue = newValue
			inMain {
				if !options.contains(.ignoreFilter), let intercept = wrapper.intercept {
					intercept(instance, newValue)
				} else if options.contains(.immediately) {
					instance.updateViews()
				} else {
					_ = UIViewStateProxy.shared.updates.insert(instance)
					UIViewStateProxy.shared.registerInRunloopIfNeed()
				}
			}
		}
	}
	
	public var wrappedValue: Value
	
	private var intercept: ((UIViewStateType, Value) -> Void)?
	public mutating func setIntercept(_ action: @escaping (UIViewStateType, Value) -> Void) {
		intercept = action
	}
	public var filter: ((Value, Value) -> Bool)?
	
	public struct UpdateOption: OptionSet {
		public let rawValue: UInt
		public init(rawValue: UInt) {
			self.rawValue = rawValue
		}
		
		/// otherwise will update before Runloop waiting
		public static var immediately: UpdateOption { UpdateOption(rawValue: 1<<0) }
		
		/// ignore filter (eg: Equtable)
		public static var ignoreFilter: UpdateOption { UpdateOption(rawValue: 1<<1) }
	}
	@usableFromInline
	var updateOptions: UpdateOption
	
	@inlinable
	@inline(__always)
	public init(defaultInit: Void, wrappedValue: Value, updateOption: UpdateOption) {
		self.wrappedValue = wrappedValue
		self.updateOptions = updateOption
	}
	
	@inlinable
	@inline(__always)
	@_disfavoredOverload
	public init(wrappedValue: Value, _ updateOption: UpdateOption = []) {
		self.init(defaultInit: (), wrappedValue: wrappedValue, updateOption: updateOption)
	}
	
	@inlinable
	@inline(__always)
	@_disfavoredOverload
	public init<Wraped>(_ updateOption: UpdateOption = []) where Value == Wraped? {
		self.init(defaultInit: (), wrappedValue: nil, updateOption: updateOption)
	}
}
extension _UIViewStateAnyState where Value: Equatable {
	@inlinable
	@inline(__always)
	public init(wrappedValue: Value, _ updateOption: UpdateOption = []) {
		self.init(defaultInit: (), wrappedValue: wrappedValue, updateOption: updateOption)
		self.filter = (==)
	}
	
	@inlinable
	@inline(__always)
	public init<Wraped>(_ updateOption: UpdateOption = []) where Value == Wraped? {
		self.init(defaultInit: (), wrappedValue: nil, updateOption: updateOption)
		self.filter = (==)
	}
}
