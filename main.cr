require "./utility.cr"
require "./lexer.cr"

# parsing

class CST
  def initialize(@subnodes : Array(CST))
  end
end

def purdypront (x : CST)
  case x
  when Unop
    print "UnaryExp ("
  when Binop
    print "BinaryExp ( " + x.@op + ", "
  when Num
    print "Num (" + x.@value.to_s
  when Identifier
    print "Identifier (" + x.@value
  when TopLevelDefList
    print "TopLevelDefs ("
  end

  x.@subnodes.each do |i|
    purdypront i
    print ", "
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

class TopLevelDefList < CST
  def initialize(@subnodes : Array(CST))
  end
end

def parse_atom (source : Array(Token)) : CST
  if source[0].@type == TokenType::NUMBER
    a = source.shift
    return Num.new(a.@val.to_i)
  end

  if source[0].@type == TokenType::IDENTIFIER
    a = source.shift
    return Identifier.new(a.@val)
  end

  if source[0].@val == "("
    source.shift
    a = parse_expr(source)
    if source[0].@val != ")"
      puts "put closing paren"
      exit 1
    end
    source.shift
    return a
  end

  print "Error when parsing: expected expression, found "
  purdypront source[0]
  exit 1
end

def parse_binary_p1 (source : Array(Token)) : CST
  lhs = parse_atom(source)
  while source.size > 0 && (source[0].@val == "*" || source[0].@val == "/")
    typ = source.shift.@val
    rhs = parse_atom(source)
    lhs = Binop.new(lhs, rhs, typ)
  end
  return lhs
end

def parse_binary_p2 (source : Array(Token)) : CST
  lhs = parse_binary_p1(source)
  while source.size > 0 && (source[0].@val == "+" || source[0].@val == "-")
    typ = source.shift.@val
    rhs = parse_binary_p1(source)
    lhs = Binop.new(lhs, rhs, typ)
  end
  return lhs
end

def parse_expr (source : Array(Token)) : CST
  return parse_binary_p2(source)
end

def parse_def(source : Array(Token)) : CST
  return TopLevelDefList.new([] of CST) # todo
end

def parse () : CST
  defs = [] of CST
  while Lexer.source.size > 0
    defn = parse_def ([] of Token) #todo
    defs.push defn
  end
  return TopLevelDefList.new(defs)
end

cst = parse
purdypront cst
puts ""