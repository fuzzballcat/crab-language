require "levenshtein" # string distance

class Error
  def initialize(@type : String, @message : String, @line : Int32, @col : Int32, @len : Int32, @truncate : Bool = false, @hint : String? = nil)
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
    
    sourceline = (Lexer.original_source.split "\n")[@line]
    if @truncate
      sourceline = sourceline[0..@col+@len-1]
    end
    print sourceline
    if @truncate
      print "..."
    end
    print "\n"
  
    print " " * (@line.to_s.size + 2 + @col)
    print Colors::RED
    print Colors::BOLD
    print "^" * @len
    print "\n\n"

    if @hint
      print Colors::YELLOW
      print Colors::BOLD
      print "Hint: "
      puts @hint
    end

    print Colors::RESET
    exit 1
  end
end

##############

class LexingError < Error
  def initialize(message : String, line : Int32, col : Int32, len : Int32)
    super("LexingError", message, line, col, len)
  end
end

class UnterminatedStringError < LexingError
  def initialize(line : Int32, col : Int32)
    super("Unterminated string literal", line, col, 5)
    @truncate = true
    @hint = "You missed a quote somewhere.  Add one to terminate the string."
  end
end

# todo: maintain
LIST_OF_COMMON_SYMBOLS = [
  "==",
  ">=",
  "<=",
  "!=",
  "->",
  "=>",
  "=",
  "+",
  "-",
  "*",
  "/",
  ":",
  "(",
  ")",
  "{",
  "}",
  "&&",
  "||",
  "!",
  "**"
]

class InvalidTokenError < LexingError
  def initialize(tok : String, @line : Int32, @col : Int32)
    super("Invalid token \"#{tok}\"", line, col, tok.size)
    @hint = "This is a typo."

    full_in_spaces = ((Lexer.original_source.split "\n")[@line].split " ").find { |s| s.includes?(tok) }

    if !full_in_spaces # make type system happy
      return
    end

    closest = (LIST_OF_COMMON_SYMBOLS.sort { |x, y| Levenshtein.distance(full_in_spaces, x) <=> Levenshtein.distance(full_in_spaces, y) }) [0]

    if !closest
      return
    end

    @hint = "Did you mean " + Colors::MAGENTA + closest + 
Colors::YELLOW + "?"
  end
end

####

class ParsingError < Error
  def initialize(message : String, line : Int32, col : Int32, len : Int32)
    super("ParsingError", message, line, col, len)
  end
end
