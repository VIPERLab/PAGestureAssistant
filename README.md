# PAGestureAssistant

[![Version](https://img.shields.io/cocoapods/v/PAGestureAssistant.svg?style=flat)](http://cocoapods.org/pods/PAGestureAssistant)
[![License](https://img.shields.io/cocoapods/l/PAGestureAssistant.svg?style=flat)](http://cocoapods.org/pods/PAGestureAssistant)
[![Platform](https://img.shields.io/cocoapods/p/PAGestureAssistant.svg?style=flat)](http://cocoapods.org/pods/PAGestureAssistant)

![Screenshot 1](http://i.imgur.com/DVnwy8S.gif)

PAGestureAssistant is a drop-in UIViewController category for showing interaction tips and tutorials to users that has predefined gestures for convenience and also the ability to define your own.

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

Choose from a set of predefined animations from the list below, or define your own custom swipe with a `startPoint` and `endPoint`.
```
// Tap animations
PAGestureAssistantTapSingle
PAGestureAssistantTapLongPress
PAGestureAssistantTapDouble

// Swipe animations
PAGestureAssistantSwipeDirectonUp
PAGestureAssistantSwipeDirectonDown
PAGestureAssistantSwipeDirectonLeft
PAGestureAssistantSwipeDirectonRight

```
Then, in your `viewDidAppear` set your assistant.
```
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    // Shows a tap gesture animation with a label in the view's center after 5 seconds
    [self showGestureAssistantForTap:PAGestureAssistantTapSingle
                                view:self.view
                                text:@"Tap here to begin"
                   afterIdleInterval:5];
}
```
That's it!

## Behaviors

This pod has two distinct behaviors:

#### Assistant Mode
Ideal for non-obvious usage patterns, like swiping down to dismiss a view.

Every time the user idles for longer than the defined interval the animation kicks in, and any user interaction passes through to the views below. To achieve this behavior, simply don't pass a completion block in any of the `showGestureAssistant` methods.

#### Tutorial Mode
Ideal for teaching users intricate flows.

After the defined interval the animation will show only once, and any user interaction will be blocked. To achieve this behavior simply pass a completion block (even one that does nothing) to any of the `showGestureAssistant` methods.

## Appearance
You can customize the following properties, and/or use a `NSAttributedString` to format text as you wish.

```
/* Sets a custom overlay color */
[[PAGestureAssistant appearance] setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.8f]];

/* Sets a custom text color */
[[PAGestureAssistant appearance] setTextColor:[UIColor darkGrayColor]];

/* Sets the gesture view color */
[[PAGestureAssistant appearance] setTapColor:self.view.tintColor];

/* Sets a custom image for the gesture view */
//[[PAGestureAssistant appearance] setTapImage:[UIImage imageNamed:@"image"]];

```

## Examples
Tutorial Example:

```
/* Chain multiple calls to achieve a tutorial effect */

// First show a custom swipe...
[self showGestureAssistantForSwipeWithStartPoint:CGPointMake(60, 60)
                                        endPoint:self.view.center
                                            text:@"You can create custom swipes"
                               afterIdleInterval:0
                                      completion:^(BOOL finished) {

    // ...then a tap on a button...
    [self showGestureAssistantForTap:PAGestureAssistantTapSingle
                                view:self.button
                                text:@"Tap twice"
                   afterIdleInterval:0
                          completion:^(BOOL finished) {

        // ...and a swipe up gesture
        [self showGestureAssistantForSwipeDirection:PAGestureAssistantSwipeDirectonUp
                                               text:@"Swipe up"
                                  afterIdleInterval:0
                                         completion:^(BOOL finished) {

            NSLog(@"Tutorial complete");

        }];
    }];
}];
```


## Requirements

- iOS 8.0+
- If you install it manually, you must also copy  [FrameAccessor](https://github.com/AlexDenisov/FrameAccessor).


## Installation

PAGestureAssistant is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "PAGestureAssistant"
```

## Author

Pedro Almeida, [@ipedro](https://twitter.com/ipedro)

## Credits

Hand icon by [Zach Blevins](https://dribbble.com/shots/1904249-Handy-Gestures).
The category implementation was inspired by Bryce Buchanan's [swizzling method]( https://blog.newrelic.com/2014/04/16/right-way-to-swizzle/).
## License

PAGestureAssistant is available under the MIT license.

Copyright (c) 2016 Pedro Almeida

```
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```
