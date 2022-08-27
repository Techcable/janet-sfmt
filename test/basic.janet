(import ../sfmt :prefix "")

(def- [bar baz] [3 "two?"]) # TODO: For testing only

(assert (= (sfmt "foo $(+ bar 3) foo $baz") "foo 6 foo two?"))

(assert (= (sfmt "foo $$ $`` `$$$$$` `` bar $(identity baz)") "foo $ $$$$$ bar two?"))
