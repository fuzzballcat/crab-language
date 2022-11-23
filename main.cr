enum TokenType
  ERR_INV
  IGNORE
  
  KEYWORD
  IDENTIFIER
  PUNC
  OPERATOR
  NUMBER
end

class Token
  def initialize(@type : TokenType, @val : String)
  end
end

def accept (s : String) : { Int32, TokenType }
  if s[0] == ' ' || s[0] == '\t' 
    return { 1, TokenType::IGNORE }
  end
  
  if s[0] == '(' || s[0] == ')'
    return { 1, TokenType::PUNC }
  end

  if s[0].to_i? != nil
    i = 0
    while i < s.size && s[i].to_i? != nil
      i += 1
    end
    return { i, TokenType::NUMBER }
  end

  if /[A-Za-z]/.match(s[0].to_s) != nil
    i = 0
    while i < s.size && /[A-Za-z]/.match(s[i].to_s) != nil
      i += 1
    end
    return { i, TokenType::IDENTIFIER }
  end

  if s[0] == '+' || s[0] == '-' || s[0] == '*' || s[0] == '/'
    return { 1, TokenType::OPERATOR }
  end

  return { 1, TokenType::ERR_INV }
end

def tokenize (source : String) : Array(Token)
  to_ret = [] of Token
  while !source.empty?
    accepted = accept(source)
    if accepted[1] == TokenType::ERR_INV
      errstr = ""
      while accepted[1] == TokenType::ERR_INV
        errstr += source[0]
        source = source[1..source.size]
        accepted = accept(source)
      end
      print "Invalid token:\n"
      print errstr
      print "\n"
      exit 1
    end

    if accepted[1] != TokenType::IGNORE
      to_ret.push Token.new(accepted[1], source[0..(accepted[0] - 1)])
    end

    source = source[accepted[0]..]
  end

  return to_ret
end

source = File.read "test.src"
toks = tokenize source

puts toks

enum ASTType
  UnaryExp
  BinaryExp
  Num
end

class AST
  def initialize(@type : ASTType, @subnodes : Array(AST))
  end
end

def purdypront (x : AST)
  case x.@type
  when ASTType::UnaryExp
    print "UnaryExp ("
  when ASTType::BinaryExp
    print "BinaryExp ( " + x.as(Binop).@op + ", "
  when ASTType::Num
    print "Num (" + x.as(Num).@value.to_s
  end

  x.@subnodes.each do |i|
    purdypront i
    print ", "
  end

  print ")"
end

class Num < AST
  def initialize(@value : Int32)
    @type = ASTType::Num
    @subnodes = [] of AST
  end
end

class Binop < AST
  def initialize(@lhs : AST, @rhs : AST, @op : String)
    @type = ASTType::BinaryExp
    @subnodes = [@lhs, @rhs]
  end
end 

def parse_atom (source : Array(Token)) : AST
  if source[0].@type == TokenType::NUMBER
    a = source.shift
    return Num.new(a.@val.to_i)
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

  print "ERR_PARSING_ATOM : GOT"
  puts source[0]
  exit 1
end

def parse_binary_p1 (source : Array(Token)) : AST
  lhs = parse_atom(source)
  while source.size > 0 && (source[0].@val == "*" || source[0].@val == "/")
    typ = source.shift.@val
    rhs = parse_atom(source)
    lhs = Binop.new(lhs, rhs, typ)
  end
  return lhs
end

def parse_binary_p2 (source : Array(Token)) : AST
  lhs = parse_binary_p1(source)
  while source.size > 0 && (source[0].@val == "+" || source[0].@val == "-")
    typ = source.shift.@val
    rhs = parse_binary_p1(source)
    lhs = Binop.new(lhs, rhs, typ)
  end
  return lhs
end

def parse_expr (source : Array(Token)) : AST
  return parse_binary_p2(source)
end

def parse (source : Array(Token)) : AST
  return parse_expr(source)
end

ast = parse toks
purdypront ast
puts ""