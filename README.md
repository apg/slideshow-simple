# slideshow/simple

slideshow/simple is new reader to help quickly create slideshows for [Racket's Slideshow](https://docs.racket-lang.org/slideshow/index.html). It was originally inspired by [sent](https://tools.suckless.org/sent), but has expanded in capabilities beyond that of sent.

An example slideshow looks like this (Note that the this #lang line doesn't quite work this way yet):

```
#lang reader slideshow/simple

slideshow/simple

@image.jpg

# comment line, ignored

depends on
- Racket
- Slideshow

slideshow FILENAME
\#lang reader slideshow/simple

\@IMAGE.png

thanks / questions?
```

And, it can be run like so:

```bash
$ slideshow filename.rkt
```

To add an image, use `@/path/to/image`, and to add a slide with some text, just write some stuff followed by a blank line. Multiple lines of text without blank lines will place all the text on a single slide. 

A line that starts with a `#` character is completely ignored. If a comment line comes immediately after an image or a paragraph, the comment counts as a blank line, and a new slide will be created for the next non blank/non comment line.

A slide cannot contain both an image and text. Therefore, the following slideshow is invalid:

```
#lang reader slideshow/simple

@image.jpg
foo bar baz quux
```

If a slide starts with a `\` the `\` is ignored. This allows escaping literal `@IMAGE.png`, lines that would otherwise by treated as `# comments`, and `\` literal escaped lines.

## Extensions (to be added)

While the `sent` tool provides the very bare minimum, there are a few extensions that this language will support to make giving actual presentations a little bit nicer.

### Speaker Notes

sent doesn't have an answer for speaker notes, but Slideshow does. 

We'll use the following syntax:

```
@image.png
# These are the speaker notes.
# You can have multiple lines of speaker notes, and that's not a big deal.

# This is still a comment, however, because we didn't add a literal blank slide.

\
# Oh, that's a blank slide. Here are it's speaker notes, anyway.
```

### Lists

sent doesn't have lists, but they can be emulated by creating a multi-line slide with bullets as the first character. In slideshow/simple we'll treat align lists on the left, where they belong, instead of being centered.

### Text Wrapping to fit.

Long lines will be wrapped to fit, rather than overrun the slide, or be scaled to super tiny font sizes.

### Quotes

Quotes are popular in slides. We'll support them in a first class manner, with the following syntax:

```
#lang slideshow/simple

> You miss 100% of the shots you don't take.
> - Wayne Gretzky
```

### Basic formatting.

We'll render basic formatting inspired by markdown. 

- **bold**
- _italics_
- ~strike-through~
- `monospace`


## Contributing and Feedback

I'm sure I can learn a lot from your feedback, ideas and contributions. Please submit issues before PRs except in trivial cases.

If you have any other feedback, feel free to email me at the below address.

## Authors

Andrew Gwozdziewycz web@apgwoz.com

## Copyright

Copyright 2017, Andrew Gwozdziewycz, web@apgwoz.com

Licensed under the GNU Lesser General Public License (LGPL). See [LICENSE.txt](./LICENSE.txt) for more information.

Input format, and inspiration thanks to the [suckless](http://suckless.org) project.



