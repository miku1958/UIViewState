//
//  ViewController.swift
//  Demo
//
//  Created by 庄黛淳华 on 2021/1/20.
//

import UIKit
import UIViewState

class ViewController: UIViewController, UIViewState {
	@State([.immediately, .ignoreFilter]) var image = UIImage()
	@State var labelTitle: String?
	
	enum Size {
		case mini
		case fullScreen
		mutating func toggle() {
			if self == .mini {
				self = .fullScreen
			} else {
				self = .mini
			}
		}
	}
	@State var size: Size = .mini
	
	let imageview = UIImageView()
	let labelMini = UILabel()
	let labelFullScreen = UILabel()
	override func viewDidLoad() {
		super.viewDidLoad()
		view.addSubview(labelMini)
		view.addSubview(labelFullScreen)
		view.addSubview(imageview)
		
		labelMini.translatesAutoresizingMaskIntoConstraints = false
		labelFullScreen.translatesAutoresizingMaskIntoConstraints = false
		imageview.translatesAutoresizingMaskIntoConstraints = false
		
		let layoutguide = UILayoutGuide()
		view.addLayoutGuide(layoutguide)
		
		NSLayoutConstraint.activate([
			layoutguide.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			layoutguide.centerYAnchor.constraint(equalTo: view.centerYAnchor),
			
			labelMini.topAnchor.constraint(equalTo: layoutguide.topAnchor),
			labelMini.leadingAnchor.constraint(equalTo: layoutguide.leadingAnchor),
			labelMini.trailingAnchor.constraint(equalTo: layoutguide.trailingAnchor),
			
			
			labelFullScreen.topAnchor.constraint(equalTo: labelMini.bottomAnchor),
			labelFullScreen.leadingAnchor.constraint(equalTo: layoutguide.leadingAnchor),
			labelFullScreen.trailingAnchor.constraint(equalTo: layoutguide.trailingAnchor),
			
			
			imageview.topAnchor.constraint(equalTo: labelFullScreen.bottomAnchor),
			imageview.leadingAnchor.constraint(equalTo: layoutguide.leadingAnchor),
			imageview.trailingAnchor.constraint(equalTo: layoutguide.trailingAnchor),
			imageview.bottomAnchor.constraint(equalTo: layoutguide.bottomAnchor),
		])
		
		view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap)))
	
		// If set to intercept, after changing self.image, it will not call self.updateViews.
		_image.setIntercept { (self, image) in
			self.imageview.image = image
		}
	}
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		labelTitle = "by State"
		labelFullScreen.text = labelMini.text // not working
		image = UIImage() // It will not call self.updateViews.
		labelMini.text = "directly"
		
		size = .fullScreen
	}
	@objc func tap() {
		self.size.toggle()
	}
	
	func updateViews() {
		switch size {
		case .mini:
			labelFullScreen.text = "fullSizeDefault"
			labelMini.text = labelTitle
		case .fullScreen:
			labelMini.text = "miniSizeDefault"
			labelFullScreen.text = labelTitle
		}
	}
}
