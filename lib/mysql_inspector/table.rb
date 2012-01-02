module MysqlInspector
  class Table

    def initialize(db_name, table_name, schema)
      @db_name
      @table_name
      @schema = schema
      @lines = schema.split("\n")
      @lines.map! { |line| line.rstrip[/(.*?),?$/, 1] }
      @lines.delete_if { |line| line =~ /(\/\*|--|CREATE TABLE)/ or line == ");" or line.strip.empty? }
      @lines.sort!
    end

    attr_reader :db_name
    attr_reader :table_name
    attr_reader :schema

    def grep(matchers)
      matches = lines.select do |line|
        matchers.all? do |matcher|
          col, *items = matcher.split(/\s+/)
          col = "`#{col}`"
          [col, items].flatten.all? { |item| line.downcase =~ /#{Regexp.escape item.downcase}/ }
        end
      end
    end 

  end
end
