module MysqlInspector
  module TablePart

    attr_accessor :table

    def <=>(other)
      name <=> other.name
    end

  protected

    def quote(word)
      "`#{word}`"
    end

    def paren(words)
      "(#{words * ","})"
    end

  end
end
