module Codestart
  module StringColor
    def shell_green
      "\e[1;32;40m#{self}\e[0m"
    end

    def shell_red
      "\e[1;31;40m#{self}\e[0m"
    end

    def shell_yellow
      "\e[1;33;40m#{self}\e[0m"
    end
  end
end

class String
  include Codestart::StringColor
end