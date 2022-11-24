# SAFEGET

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

# COLOR

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