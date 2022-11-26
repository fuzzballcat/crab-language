require "./utility.cr"
require "./error.cr"
require "./lexer.cr"
require "./parser.cr"

cst = parse
purdypront cst
puts ""