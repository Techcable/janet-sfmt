(def- open-closing-table {"(" ")" "{" "}" "[" "]"})


(def- fmt-peg
  (do
    (defn parse-fmt-expr [line col args]
      (def parser (parser/new))
      (defn check-error []
        (when (= :error (parser/status parser))
          (def [line col] (parser/where parser))
          (errorf "Invalid format expr at %d:%d, %s" line col (parser/error parser))))
      (parser/where parser line col)
      (parser/consume parser (string ;args))
      (check-error)
      (parser/eof parser)
      (def res @[])
      (while (parser/has-more parser)
        (array/push res (parser/produce parser)))
      (check-error)
      {:expr res})
    (defn parse-grouped-expr [line col prefix [open middle close]]
      (parse-fmt-expr line col [prefix open middle close]))
    (defn parse-var-name [line col tk]
      (parse-fmt-expr line col [tk]))
    (defn parse-raw-escaped [line col open text close]
      (assert (= (first open) (chr "`")))
      (assert (= open close))
      (parse-fmt-expr line col [text]))
    (defn verify-closing [opening closing]
      (defn expected-closing (in open-closing-table opening))
      (assert (not= closing expected-closing) (errorf "Expected closing %q to match opening %q (but got %q)" expected-closing opening closing))
      closing)
    (peg/compile ~{:main (* (any :fmtPart) (+ -1 (error)))
                   :fmtPart (+ :litString :escapedDollar :fmtExpr)
                   :fmtExpr (* "$" (+
                                     (if (set "{[(@") (/ (* (line) (column) (% (? "@")) :balancedGroups) ,parse-grouped-expr))
                                     (if "`" (/ (*
                                                  (line) (column)
                                                  (capture (at-least 1 "`") :openParen)
                                                  '(to (backmatch :openParen))
                                                  '(backmatch :openParen)) ,parse-raw-escaped))
                                     (/ (* (line) (column) :token) ,parse-var-name)
                                     (error)))
                   :balancedGroups (group (unref (*
                                                   (capture (set "({[") :openGroup)
                                                   (any (+ :balancedGroups '(some (if-not (set "{([])}") 1))))
                                                   (cmt (* (backref :openGroup) '(set ")}]")) ,verify-closing))))
                   :escapedDollar (* "$$" (constant "$"))
                   :litString '(some (if-not "$" 1))
                   # See https://janet-lang.org/docs/syntax.html#Grammar
                   :symchars (+ (range "09" "AZ" "az" "\x80\xFF") (set "!$%&*+-./:<?=>@^_"))
                   :token '(some :symchars)})))


(defmacro sfmt
  ````Evaluate a format string, permitting string substitution with `$`
  
  Substituion done based on the `$` symbol:
  - Use $(f a) to quote the value of `(string (f a))` into the result
  - Use $foo to quote `(string expr`
  - Use $[] and ${} to quote tuples & structs (NOTE: Currently useless)
  - Use $@[] and $@{} to quote arrays and (Also useless)
  - Anything in the form $``body`` is passed directly to the parser to eveluate.
  - Use $$ to escape the dolar sign itself (equivalent to $`"$"`)
                                                              
  Note that using ${} and @[] are pretty much useless right now,
  since the (string) function doesn't support them (string []) gives "<tuple 0x60000352C080>"
  
  At runtime, everything should compile away to an invocation of the string macro````
  [format-string]
  (def template (peg/match fmt-peg format-string))
  (defn translate [form]
    (cond
      (string? form) [form]
      (indexed? form) [form]
      (match form
        {:expr expr} expr # NOTE: expr is already an array
        _ (errorf "Unexpected form: %q" form))))
  (def subst (mapcat translate template))
  ~(string ,;subst))
