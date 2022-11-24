# utility
module SafeGet
 def get?(i)
    return self.size <= i ? nil : self[i]
  end
end

class Array 
  include SafeGet
end
class String
  include SafeGet
end

module Colors
  BLACK = "\u001b[30m"
  RED = "\u001b[31m"
  GREEN = "\u001b[32m"
  YELLOW = "\u001b[33m"
  BLUE = "\u001b[34m"
  MAGENTA = "\u001b[35m"
  CYAN = "\u001b[36m"
  WHITE = "\u001b[37m"
  RESET = "\u001b[0m"

  BRIGHTBLACK = "\u001b[30;1m"
  BRIGHTRED = "\u001b[31;1m"
  BRIGHTGREEN = "\u001b[32;1m"
  BRIGHTYELLOW = "\u001b[33;1m"
  BRIGHTBLUE = "\u001b[34;1m"
  BRIGHTMAGENTA = "\u001b[35;1m"
  BRIGHTCYAN = "\u001b[36;1m"
  BRIGHTWHITE = "\u001b[37;1m"

  BOLD = "\u001b[1m"
  UNDERLINE = "\u001b[4m"
  REVERSED = "\u001b[7m"
end

# lexer

class Lexer
  @@source = File.read "test.src"
  @@lineno = 0
  @@colno  = 0

  @@original_source : String = @@source
  def self.original_source
    return @@original_source
  end
  
  # eek
  def self.source
    return @@source
  end
  def self.source=(@@source)
  end

  def self.lineno
    return @@lineno
  end
  def self.lineno=(@@lineno)
  end

  def self.colno
    return @@colno
  end
  def self.colno=(@@colno)
  end
end

class Error
  def initialize(@type : String, @message : String, @line : Int32, @col : Int32, @len : Int32, @truncate : Bool = false)
  end

  def throw!
    print Colors::RED
    print @type
    print Colors::RESET
    print ": "
    puts @message

    print "On line "
    print @line
    print ", col "
    print @col
    print ":\n\n"

    print Colors::BLUE
    print @line
    print " |"
    print Colors::RESET
    
    sourceline = (Lexer.original_source.split "\n")[@line][0..@col+@len-1]
    print sourceline
    if @truncate
      print "..."
    end
    print "\n"
  
    print " " * (@line.to_s.size + 2 + @col)
    print Colors::RED
    print Colors::BOLD
    print "^" * @len
    print Colors::RESET

    print "\n"
    exit 1
  end
end

class LexingError < Error
  def initialize(message : String, line : Int32, col : Int32, len : Int32)
    super("LexingError", message, line, col, len)
  end
end

class UnterminatedStringError < LexingError
  def initialize(line : Int32, col : Int32)
    super("Unterminated string literal", line, col, 5)
    @truncate = true
  end
end

class InvalidTokenError < LexingError
  def initialize(tok : String, @line : Int32, @col : Int32)
    super("Invalid token \"#{tok}\"", line, col, tok.size)
  end
end

enum TokenType
  ERR_INV
  IGNORE

  NEWLINE
  
  KEYWORD
  IDENTIFIER
  PUNC
  OPERATOR
  NUMBER
  STRING
end

class Token
  def initialize(@type : TokenType, @val : String)
  end
end

def purdypront (x : Token)
  print x.@type
  print ": "
  puts x.@val
end

def accept (s : String) : { Int32, TokenType }
  if s[0] == ' ' || s[0] == '\t' 
    return { 1, TokenType::IGNORE }
  end

  if s[0] == '\n'
    i = 0
    while s[i] == '\n'
      i += 1
    end
    return { i, TokenType::NEWLINE }
  end
  
  if s[0] == '(' || s[0] == ')' || s[0] == ':' || s[0] == '{' || s[0] == '}'
    return { 1, TokenType::PUNC }
  end

  if (s[0] == '=' || s[0] == '-') && s.get?(1) == '>'
    return { 2, TokenType::PUNC }
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

  if s[0] == '"'
    i = 1
    while s[i] != '"'
      if s[i] == '\\'
        i += 1
      end

      i += 1
      if i >= s.size
        UnterminatedStringError.new(Lexer.lineno, Lexer.colno).throw!
      end 
    end
    return { i+1, TokenType::STRING }
  end

  if s[0] == '+' || (s[0] == '-' && s.get?(1) != '>') || s[0] == '*' || s[0] == '/'
    return { 1, TokenType::OPERATOR }
  end

  return { 1, TokenType::ERR_INV }
end

def nextok () : Token | Nil
  while true
    if Lexer.source.empty?
      return nil
    end
  
    accepted = accept(Lexer.source)
    if accepted[1] == TokenType::ERR_INV
      errstr = ""
      while accepted[1] == TokenType::ERR_INV
        errstr += Lexer.source[0]
        if Lexer.source.size == 1 
          break 
        end
        Lexer.source = Lexer.source[1..Lexer.source.size]
        accepted = accept(Lexer.source)
      end

      InvalidTokenError.new(errstr, Lexer.lineno, Lexer.colno).throw!
    end

    token_text = Lexer.source[0..(accepted[0] - 1)]
    token_text.each_char do |c|
      if c == '\n'
        Lexer.lineno += 1
        Lexer.colno = 0
      else
        Lexer.colno  += 1
      end
    end
    Lexer.source = Lexer.source[accepted[0]..Lexer.source.size]
  
    if accepted[1] != TokenType::IGNORE
      return Token.new(accepted[1], token_text)
    end
  end
end

def expect (t : TokenType) : Token
  n = nextok
  if !n || n.@type != t
    exit 1 # todo
  end
  return n
end

def expect (t : String) : Token
  n = nextok
  if !n || n.@val != t
    exit 1 # todo
  end
  return n
end

while true
  nextok
end

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