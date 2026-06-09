module Ast = {
  type element
  type optionValue

  @get external type_: element => int = "type"
  @get external value: element => string = "value"
  @get external options: element => Dict.t<optionValue> = "options"
  @get external children: element => array<element> = "children"
  @get external optionElements: optionValue => array<element> = "value"
}

@module("@formatjs/icu-messageformat-parser") external parse: string => array<Ast.element> = "parse"
