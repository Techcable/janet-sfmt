Simple format-strings for Janet
===============================
In the style of python `f"foo {bar}"` or kotlin "foo $bar" (syntatically closer to the latter)

Implemented as a macro.

## Examples
```janet
(defn var "bar")
(print (sfmt "foo $var baz") # Prints "foo bar baz"
(print (sfmt "3 $(2 + 2) 5") # Prints "3 4 5"
```

Unlike [spork/temple] this doees absolutely no HTML escaping at all.

At runtime, everything boils down to an invocation of [`string`](https://janet-lang.org/api/index.html#string) function.

So `(sfmt "foo $var baz")` becomes `(string "foo " var baz)` after macro expansion. 
