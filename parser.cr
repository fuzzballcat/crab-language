class CST
  def initialize(@subnodes : Array(CST))
  end
end

def purdypront (x : CST)
  expand_out = false
  
  case x
  when Unop
    print "UnaryExp ("
  when Binop
    print "BinaryExp ( " + x.@op + ", "
  when Num
    print "Num (" + x.@value.to_s
  when NoneVal
    print "NoneVal("
  when StringExpr
    print "String (#{x.@value})"
  when Identifier
    print "Identifier (" + x.@value
  when Funcall
    print "Funcall ["
    purdypront x.@name
    print "]("
  when BracketBlock
    print "ExprList ("
  when TypeConstructor
    print "TypeConstructor[#{x.@name}] ("
  when FunctionType
    print "FunctionType ("
    x.@foralls.each do |i|
      purdypront i
      print ", "
    end
    print "=> "
    x.@arguments.each do |i|
      purdypront i
      print ", "
    end
    print "-> "
    purdypront x.@returnType
  when ValuePlusType
    print "ValuePlusType ("
  when TopLevelDefList
    print "TopLevelDefs ("
    expand_out = true
  when Def
    print "Def [#{x.@name}] ("
  end

  x.@subnodes.each do |i|
    if expand_out
      print "\n\n\t"
    end
    purdypront i
    print ", "
  end

  if expand_out
    print "\n\n"
  end
  print ")"
end

class Num < CST
  def initialize(@value : Int32)
    @subnodes = [] of CST
  end
end

class Identifier < CST
  def initialize(@value : String)
    @subnodes = [] of CST
  end
end

class StringExpr < CST
  def initialize(@value : String)
    @subnodes = [] of CST
  end
end

class NoneVal < CST
  def initialize()
    @subnodes = [] of CST
  end
end

class Unop < CST
  def initialize(@rhs : CST, @op : String)
    @subnodes = [@rhs]
  end
end

class Binop < CST
  def initialize(@lhs : CST, @rhs : CST, @op : String)
    @subnodes = [@lhs, @rhs]
  end
end

class Funcall < CST
  def initialize(@name : CST, @args : Array(CST))
    @subnodes = @args
  end
end

class BracketBlock < CST
  def initialize(@exprs : Array(CST))
    @subnodes = @exprs
  end
end

class TypeConstructor < CST
  def initialize(@name : String, @arguments : Array(CST))
    @subnodes = @arguments
  end
end

class ValuePlusType < CST
  def initialize(@expression : CST, @type : CST)
    @subnodes = [@expression, @type]
  end
end

class FunctionType < CST
  def initialize(@foralls : Array(CST), @arguments : Array(CST), @returnType : CST)
    @subnodes = [] of CST
  end
end

class Def < CST
  def initialize(@name : String, @typeExpression : CST)
    @subnodes = [@typeExpression]
  end
end

class TopLevelDefList < CST
  def initialize(@subnodes : Array(CST))
  end
end

def parse_atom () : CST
  if peek.@type == TokenType::NUMBER
    a = nextok
    return Num.new(a.@val.to_i)
  end

  if peek.@type == TokenType::IDENTIFIER
    a = nextok
    return Identifier.new(a.@val)
  end

  if peek.@type == TokenType::STRING
    a = nextok
    return StringExpr.new(a.@val)
  end

  if peek.@type == TokenType::NONEVAL
    a = nextok
    return NoneVal.new()
  end

  if peek.@val == "("
    nextok
    a = parse_expression
    expect(")", "an expression")
    return a
  end

  if peek.@val == "{"
    nextok
    Lexer.ignore_newlines = true
    a = [parse_expression]
    while peek.@val == ";"
      nextok
      a.push parse_expression
    end
    expect("}", "a bracketed block")
    Lexer.ignore_newlines = false
    return BracketBlock.new(a)
  end

  n = nextok
  ExpectError.new("an expression", n.@val, n.@lineno, n.@colno, n.@val.size, "an expression").throw!
end

def parse_binary_p1 () : CST
  lhs = parse_atom
  while peek.@val == "*" || peek.@val == "/"
    typ = nextok.@val
    rhs = parse_atom
    lhs = Binop.new(lhs, rhs, typ)
  end
  return lhs
end

def parse_binary_p2 () : CST
  lhs = parse_binary_p1
  while peek.@val == "+" || peek.@val == "-"
    typ = nextok.@val
    rhs = parse_binary_p1
    lhs = Binop.new(lhs, rhs, typ)
  end
  return lhs
end

def parse_funcall_expr () : CST
  ex = parse_binary_p2

  args = [] of CST
  while peek.@val == "(" || peek.@type == TokenType::IDENTIFIER || peek.@type == TokenType::NUMBER || peek.@type == TokenType::STRING || peek.@type == TokenType::NONEVAL
    nextex = parse_binary_p2
    args.push nextex
  end

  if args.size != 0
    return Funcall.new(ex, args)
  else
    return ex
  end
end

def parse_expression () : CST
  return parse_funcall_expr
end

def parse_type_atom : CST
  if peek.@val == "("
    nextok
    typ = parse_type
    expect(")", "a type declaration")
    return typ
  end

  id = expect(TokenType::IDENTIFIER, "a type declaration")

  args = [] of CST
  while peek.@type == TokenType::IDENTIFIER || peek.@val == "(" || peek.@type == TokenType::NONEVAL
    if peek.@val == "("
      args.push parse_type_atom
    elsif peek.@type == TokenType::NONEVAL
      nextok
      args.push NoneVal.new()
    else
      args.push Identifier.new(nextok.@val)
    end
  end

  if args.size != 0
    return TypeConstructor.new(id.@val, args)
  else
    return Identifier.new(id.@val)
  end
end

def parse_type : CST
  atom = parse_type_atom

  if peek.@val == "->"
    nextok
    returntyp = parse_type_atom
    # todo: RankNTypes

    # atom has absorbed all fn args, extract them
    args = [atom]
    if atom.is_a?(TypeConstructor)
      args = [Identifier.new(atom.@name)] + atom.@arguments
    end
    return FunctionType.new([] of CST, args, returntyp)
  else
    return atom
  end
end

def parse_argument_expression() : CST
  if peek.@val == "("
    nextok
    xpr = parse_argument_expression()
    expect(")", "an argument name or pattern match expression")
    return xpr
  end
  
  id = expect(TokenType::IDENTIFIER, "an argument name or pattern match expression")
  args = [] of CST
  while peek.@type == TokenType::IDENTIFIER || peek.@val == "("
    if peek.@val == "("
      args.push parse_argument_expression
    else
      args.push Identifier.new(nextok.@val)
    end
  end

  if args.size != 0
    return TypeConstructor.new(id.@val, args)
  else
    return Identifier.new(id.@val)
  end
end

def parse_argument() : CST
  expr = parse_argument_expression

  expect(":", "an argument's type declaration")

  typ = parse_type_atom

  return ValuePlusType.new(expr, typ)
end

def parse_return() : CST
  expr = parse_expression

  expect(":", "the return type declaration")

  typ = parse_type_atom

  return ValuePlusType.new(expr, typ)
end

def parse_def_fn_type() : CST
  idx = 1
  pought = peek(idx) # "peeked" doesn't sound right
  while "=>" != pought.@val != ":"
    if pought.@type == TokenType::EOF
      expect("=> or ->", "a function declaration")
    end
    idx += 1
    pought = peek(idx)
  end

  poly_ids = [] of CST

  if peek(idx).@val == "=>"
    while peek.@val != "=>"
      poly_ids.push Identifier.new(expect(TokenType::IDENTIFIER, "a polymorphic type variable declaration").@val)
    end
    nextok
  end

  args = [] of CST
  while peek.@val != "->"
    args.push parse_argument
  end

  nextok

  ret = parse_return

  return FunctionType.new(poly_ids, args, ret)
end

def parse_def() : CST
  id = expect(TokenType::IDENTIFIER, "a function definition")
  ftyp = parse_def_fn_type

  return Def.new(id.@val, ftyp)
end

def parse () : CST
  defs = [] of CST
  while peek.@type != TokenType::EOF
    defn = parse_def
    defs.push defn

    if peek.@type != TokenType::EOF
      expect(TokenType::NEWLINE, customHint: "Function definitions must each be placed on a new line.")
    end
  end
  return TopLevelDefList.new(defs)
end