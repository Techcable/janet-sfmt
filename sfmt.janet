(def- open-closing-table {"(" ")" "{" "}" "[" "]"})


(def- fmt-peg
  (do
    (defn parse-fmt-expr [line col [open middle close]]
      (assert (= open "{"))
      (assert (= close "}"))
      (def args middle)
      (prin "fmtExpr: ") (pp args)
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
    (defn verify-closing [opening closing]
      (defn expected-closing (in open-closing-table opening))
      (assert (not= closing expected-closing) (errorf "Expected closing %q to match opening %q (but got %q)" expected-closing opening closing))
      closing)
    (peg/compile ~{:main (* (any :fmtPart) (+ -1 (error ($))))
                  :fmtPart (+ :litString :escapedBracket :fmtExpr)
                  :fmtExpr (if "{" (/ (* (line) (column) :balancedGroups) ,parse-fmt-expr))
                  :balancedGroups (group (unref (*
                             (capture (set "({[") :openGroup)
                             (any (+ :balancedGroups '(some (if-not (set "{([])}") 1))))
                             (cmt (* (backref :openGroup) '(set ")}")) ,verify-closing))))
                  :escapedBracket (/ '(+ "{{" "}}") ,first)
                  :litString '(some (if-not (set "{}") 1))})))


(def- bar 3) # TODO: For testing only

(defmacro pfmt
  ```Evaluate a Python-style format string```
  [format-string]
  (def template (peg/match fmt-peg format-string))
  (defn translate [form]
    (if (string? form) form
      (match form
        {:expr expr} expr
        _ (errorf "Unexpected form: %q") )))
  (def subst (walk translate template))
  (prin "subst: ") (pp subst)
  ~(string ,;subst))


(pp (pfmt "foo {(+ bar 3)} foo"))
