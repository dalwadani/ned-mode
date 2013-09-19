NED Major Mode
========
An Emacs major mode for NED files which are used in [OMNeT++][omnet].
Our aim now is to provide: syntax highlighting, indentation support and a few commands.
Now it has a basic implementation of autocomlation for packages name.

## Indentation


(This section is based on the work done in [coffee-mode][cm])

### TAB Theory

It goes like this: when you press `TAB`, we indent the line unless
doing so would make the current line more than two indentation levels
deepers than the previous line. If that's the case, remove all
indentation.


Consider this code, with point at the position indicated by the
caret:

    line1()
      line2()
      line3()
         ^

Pressing `TAB` will produce the following code:

    line1()
      line2()
        line3()
           ^

Pressing `TAB` again will produce this code:

    line1()
      line2()
    line3()
       ^

And so on. I think this is a pretty good way of getting decent
indentation with a whitespace-sensitive language.

### Newline and Indent

We all love hitting `RET` and having the next line indented
properly. Given this code and cursor position:

    line1()
      line2()
      line3()
            ^

Pressing `RET` would insert a newline and place our cursor at the
following position:

    line1()
      line2()
      line3()

      ^

In other words, the level of indentation is maintained. This
applies to comments as well. Combined with the `TAB` you should be
able to get things where you want them pretty easily.

### Indenters

`class`, `for`, `if`, and possibly other keywords cause the next line
to be indented a level deeper automatically.

For example, given this code and cursor position::

    class Animal
                ^

Pressing enter would produce the following:

    class Animal

      ^

That is, indented a column deeper.

This also applies to lines ending in `->`, `=>`, `{`, `[`, and
possibly more characters.

So this code and cursor position:

    $('#demo').click ->
                       ^

On enter would produce this:

    $('#demo').click ->

      ^

### Multiline comment
If the last line was a comment, the following will probably be too. This makes it easy to write multi-line comments

## Feature
- Highlighting comments
- Highlighting keywords
- Auto indent 

## Bugs
If you have any issues using this mode please use <https://github.com/dalwadani/ned-mode/issues>

[omnet]: http://www.omnetpp.org
[cm]: https://github.com/defunkt/coffee-mode