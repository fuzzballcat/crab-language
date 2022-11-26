class Lexer
  @@source = File.read "test.src"
  @@lineno = 0
  @@colno  = 0
  @@ignore_newlines = false

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

  def self.ignore_newlines
    return @@ignore_newlines
  end
  def self.ignore_newlines=(@@ignore_newlines)
  end
end

enum TokenType
  ERR_INV
  IGNORE
  EOF

  NEWLINE
  
  KEYWORD
  IDENTIFIER
  PUNC
  OPERATOR
  NUMBER
  STRING
  NONEVAL
end

class Token
  def initialize(@type : TokenType, @val : String, @lineno : Int32, @colno : Int32)
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
    if Lexer.ignore_newlines
      return { i, TokenType::IGNORE }
    end
    return { i, TokenType::NEWLINE }
  end

  if s[0] == '(' && s.get?(1) == ')'
    return { 2, TokenType::NONEVAL }
  end

  if s[0] == '(' || s[0] == ')' || s[0] == ':' || s[0] == '{' || s[0] == '}' || s[0] == ';'
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

def nextok () : Token
  while true
    if Lexer.source.empty?
      return Token.new(TokenType::EOF, " ", Lexer.lineno, Lexer.colno)
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
    token_line = Lexer.lineno
    token_col  = Lexer.colno
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
      return Token.new(accepted[1], token_text, token_line, token_col)
    end
  end
end

def expect (t : TokenType, p : String? = nil, customHint : String? = nil) : Token
  n = nextok
  if n.@type != t
    ExpectError.new(t.to_s, n.@type.to_s, n.@lineno, n.@colno, n.@val.size, p, customHint).throw!
  end
  return n
end

def expect (t : String, p : String? = nil, customHint : String? = nil) : Token
  n = nextok
  if n.@val != t
    ExpectError.new(t, n.@val, n.@lineno, n.@colno, n.@val.size, p, customHint).throw!
  end
  return n
end

# absolute hacky, probably bad on perf
def peek (num : Int32 = 1) : Token
  sr = Lexer.source
  ln = Lexer.lineno
  cn = Lexer.colno

  n = nextok

  # multipeek support
  i = 1
  while i < num
    n = nextok
    i += 1
  end

  Lexer.source = sr
  Lexer.lineno = ln
  Lexer.colno  = cn

  return n
end