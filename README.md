# PAGestureAssistant

[![Version](https://img.shields.io/cocoapods/v/PAGestureAssistant.svg?style=flat)](http://cocoapods.org/pods/PAGestureAssistant)
[![License](https://img.shields.io/cocoapods/l/PAGestureAssistant.svg?style=flat)](http://cocoapods.org/pods/PAGestureAssistant)
[![Platform](https://img.shields.io/cocoapods/p/PAGestureAssistant.svg?style=flat)](http://cocoapods.org/pods/PAGestureAssistant)

![Screenshot 1](https://raw.githubusercontent.com/ipedro/PAGestureAssistant/master/screenshot1.gif)
![Screenshot 2](https://raw.githubusercontent.com/ipedro/PAGestureAssistant/master/screenshot2.gif)

PAGestureAssistant is a drop-in UIViewController category for showing interaction tips and tutorials to users that has predefined gestures for convenience and also the ability to define your own.

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

Then, in your `viewDidAppear` set your assistant, for example:
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

You can set your custom swipe defining a `startPoint` and `endPoint`, or choose from a set of predefined animations:
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

Tutorial Example:

```
/* Chain multiple calls to achieve a tutorial effect */

// First show a custom swipe...
[self showGestureAssistantForSwipeWithStartPoint:CGPointMake(60, 60)
                                        endPoint:self.view.center
                                            text:@"You can create custom swipes"
                              afterIdleInterval:0 completion:^(BOOL finished) {

    // ...then a tap on a button...
    [self showGestureAssistantForTap:PAGestureAssistantTapSingle
                                view:self.button
                                text:@"Tap twice"
                   afterIdleInterval:0 completion:^(BOOL finished) {

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

You can also customize the appearance:

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

Note: If you don't define a completion block any user interaction will pass through to the views below, but if you define a completion block that will not happen. I recommend checking out the demo project to check this behavior.

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

The category implementation was inspired by the very good [DZNEmptyDataSet](https://github.com/dzenbot/DZNEmptyDataSet), check it out.
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
