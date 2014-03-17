# CWDepthView

`CWDepthView` serves a singular purpose of easily displaying a modal view on top of the current view alongside an illusion of depth.

![CWDepthView](depthviewdemo.gif)

## Requirements

`CWDepthView` uses ARC and requires iOS 7.0+.

Works for iPhone and iPad.

## Installation

### CocoaPods

*COMING SOON*

### Manual

Copy the folder `CWDepthView` to your project.

## Usage

Firstly, you need to import the library:

```
#import "CWDepthView.h"
```

Now, you need to create the CWDepthView. You should make the object a strong property, otherwise the library might work incorrectly.

For example:

```
@property (strong, nonatomic) CWDepthView *depthView;
```

Now, to initialize the depth view:

```
self.depthView = [CWDepthView new]; // or [[CWDepthView alloc] init] if you're old school
```

To present a `UIView` named `viewToPresent`:

```
[self.depthView presentView:viewToPresent];
```

To dismiss the presented view (note that there is an optional completion block):

```
[self.depthView dismissDepthViewWithCompletion:nil]]
```

## License

    The MIT License (MIT)

    Copyright (c) 2013 Cezary Wojcik <http://www.cezarywojcik.com>

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
