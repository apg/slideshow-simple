# slideshow/simple

slideshow/simple is new reader to help quickly create slideshows for [Racket's Slideshow](https://docs.racket-lang.org/slideshow/index.html). It was originally inspired by [sent](https://tools.suckless.org/sent), but has expanded in capabilities beyond that of sent.

An example slideshow looks like this.

```
#lang slideshow/simple

slideshow/simple

!image.jpg

# comment line, ignored

Depends on...

- Racket
- Slideshow

slideshow FILENAME
\#lang slideshow/simple

\!IMAGE.png

thanks / questions?
```

It can be run like so:

```bash
$ slideshow filename.rkt
```

To add an image, use `!/path/to/image`, and to add a slide with some
text, just write some stuff followed by a blank line. Multiple lines
of text without blank lines will place all the text on a single slide.

A line that starts with a `#` character is completely ignored. If a
comment line comes immediately after an image, paragraph, quote, or
list the comment counts as a blank line, and a new slide will be
created for the next non blank/non comment line. The comment will 
become speaker notes.

A slide cannot contain both an image and text. Therefore, the
following slideshow is invalid:

```
#lang slideshow/simple

!image.jpg
foo bar baz quux
```

If a slide starts with a `\` the `\` is ignored. This allows escaping
literal `!IMAGE.png`, lines that would otherwise by treated as 
`# comments` comments`, and `\` literal escaped lines.

### Speaker Notes

As mentioned above, speaker notes get added to a slide when comments
are placed *directly* under your slide content:

```
#lang slideshow/simple

This is the slide
# These will show up as speaker notes.
# This will show up on the same slide.

```

### Lists

sent doesn't have lists, but they can be emulated by creating a
multi-line slide with bullets as the first character. In
slideshow/simple we've got bulleted, and numerical lists.

```
#lang slideshow/simple

1. We've
2. Got
3. Them.

- We've
- Got
- Them.
```

Note, though, that lists must be by themselves. There's no title
support, or additional paragraph support. This is considered a bug.

### Text Wrapping to fit.

Long lines will be wrapped to fit, rather than overrun the slide, or
be scaled to super tiny font sizes.

### Quotes

Quotes are popular in slides. slideshow/simple supports them.

```
#lang slideshow/simple

> You miss 100% of the shots you don't take.
> -- Wayne Gretzky
```

### Basic formatting.

There is none. We'll likely add monospace support, cause that'd be nice
for inline code.

## Installation

Run `raco pkg install` in a checkout.

## Contributing and Feedback

I'm sure I can learn a lot from your feedback, ideas and
contributions. Please submit issues before PRs except in trivial
cases.

If you have any other feedback, feel free to email me at the below
address.

## Authors

Andrew Gwozdziewycz web@apgwoz.com

## Copyright

Copyright © 2017, Andrew Gwozdziewycz, web@apgwoz.com

Licensed under the GNU Lesser General Public License
(LGPL). See [LICENSE.txt](./LICENSE.txt) for more information.

Special thanks to the suckless project for their work on sent,
which heavily inspired slideshow/simple.



