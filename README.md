# UIViewState

目前为止这个库仍然只是玩具

So far this library is still just a toy

让 UIKit 的数据流更像 SwiftUI

灵感来自: 

https://www.swiftbysundell.com/articles/accessing-a-swift-property-wrappers-enclosing-instance/

https://forums.swift.org/t/property-wrappers-access-to-both-enclosing-self-and-wrapper-instance/32526/2

https://github.com/ReSwift/ReSwift

感谢

## 简单用法:

```
class ViewController: UIViewController, UIViewState {
  @State var labelTitle: String?
  ...
  
  func updateViews() { // UIViewState 协议需要实现的方法
    label.text = labelTitle
  }
}

let ctr = ViewController()
ctr.labelTitle = "new" // 自动调用 updateViews()
```

无需什么额外的设置, 用法跟 SwiftUI 几乎一模一样(除了回调)

## 其他用法
```
@State([.immediately, .ignoreFilter]) var image = UIImage()
```
immediately 代表会在设置后立刻回调 updateViews, 如果没有设置则代表会在当前 runloop 触发 CATransaction 刷新前统一调用 updateViews 避免多个成员变化触发多次 updateViews 方法

ignoreFilter 代表禁用过滤, 默认如果右值为 Equtable 的时候会判断值是否有变化, 有变化才会触发刷新, 等价于:
```
var image = UIImage() {
  didSet {
    if image != oldValue {
      updateViews()
    }
  }
}
```

```
_image.setIntercept { (self, image) in
  self.imageview.image = image
}
```
如果使用了 setIntercept, 那么当 image 发生变化时就不会调用 updateViews 而是会通过这个闭包进行更新

## TODO
实现类似于label.setText($text)的效果
