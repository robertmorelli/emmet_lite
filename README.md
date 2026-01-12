# Lexer Generator

This is intended to be an extremely high performance lexer generator. There is some legacy code in here from when the lexer was specific to emmet





# _OLD STUFF. THIS USED TO BE EMMET LITE BUT NO LONGER_
# mini emmet
## Tokens:
- group
  - lparen:`(`
  - rparen:`)`
  - lsquare:`[`
  - rsquare:`]`
- variable
  - string:`"[^"]*"`
  - content:`{[^}]*}`
  - identifier:`[a-Z-_]+`
  - number: `[0-9]+`
- combinator
  - child:`>`
  - sibling:`+`
- prefix
  - id:`#`
  - class:`.`
- misc
  - equals:`=`
  - multiply:`*`
- name
  - div
  - p
  - h1
  - ...
## Grammar
- line
  - collection (combinator line)?
- collection
  - group (multiply number)?
- group
  - lparen line rparen
  - element
- element
  - specifier+ content?
- specifier
  - prefix identifier
  - name
  - lsquare identifier equals string rsquare
