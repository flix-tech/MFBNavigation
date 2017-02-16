# MFBNavigation

This library provides wrapper classes to perform modal presentation & navigation transitions in a queued manner.

More details are coming soon.

## Intergration

### CocoaPods

```ruby
pod 'MFBNavigation', :git => 'https://github.com/flix-tech/MFBNavigation.git'
```

### Carthage

```
github "flix-tech/MFBNavigation"
```

## Caveats

### Popovers

iOS popovers can be dismissed by tapping on a background overlay view. By default iOS invokes `-dismissViewControllerAnimated:` directly.
That's not we want since it bypasses the queueing mechanism. We can use popover delegate (`UIPopoverPresentationControllerDelegate` protocol)
to handle this, though:

```objc
- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    // enqueue dismissal
    [modalNavigator dismissModalViewControllerAnimated:YES completion:nil];
    // prevent default system behaviour
    return NO;
}
```

In future, it might worth considering to proxy presentation delegates of any modally presented view controller in order to achieve
such behavior automatically.

### UIActivityViewController

As popovers, presented `UIActivityViewController` instances can be dismissed with background overlay tap.

So far I didn't find any way to prevent this & redirect the dismissal intention to a navigator.

It looks like `UIActivityViewController` uses similar (or even the same) presentation mechanism as popovers do,
though setting presentation controller delegate seems to have no effect.
