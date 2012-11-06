require 'optparse'

module MysqlInspector
  class CLI

    NAME = "mysql-inspector"

    CURRENT = "current"
    TARGET  = "target"

    module Helper

      def exit(msg)
        @stdout.puts msg
        throw :quit, 0
      end

      def abort(msg)
        @stderr.puts msg
        throw :quit, 1
      end

      def usage(msg)
        abort "Usage: #{NAME} #{msg}"
      end

      def puts(*args)
        @stdout.puts(*args)
      end
    end

    module Formatting
      # Print table item details.
      #
      # Examples
      #
      #     LABEL    item1
      #              item2
      #
      def format_items(label, items, &formatter)
        pad = " " * 4
        formatter ||= proc { |item | item.to_sql }
        items.each.with_index { |item, i|
          if i == 0
            puts [label, pad, formatter.call(item)] * ""
          else
            puts [" " * label.size, pad, formatter.call(item)] * ""
          end
        }
      end
    end

    include Helper

    def initialize(config, stdout, stderr)
      @config = config
      @stdout = stdout
      @stderr = stderr
      @status = 0
    end

    attr_reader :stdout
    attr_reader :stderr
    attr_reader :status

    def option_parser
      @option_parser ||= OptionParser.new do |opts|
        opts.banner = "Usage: #{NAME} [options] command [command args]"

        opts.separator ""
        opts.separator "Options"
        opts.separator ""

        opts.on("--out DIR", "Where to store schemas. Defaults to '.'") do |dir|
          @config.dir = dir
        end

        opts.on("--rails", "Configure for a Rails project") do
          @config.rails!
        end

        opts.on("-h", "--help", "What you're looking at") do
          exit opts.to_s
        end

        opts.on("-v", "--version", "Show the version of mysql-inspector") do
          exit MysqlInspector::VERSION
        end

        opts.separator ""
        opts.separator "Commands"
        opts.separator ""

        opts.separator "  write DATABASE [VERSION]"
        opts.separator "  load DATABASE [VERSION]"
        opts.separator "  diff"
        opts.separator "  diff TO"
        opts.separator "  diff FROM TO"
        opts.separator "  grep PATTERN [PATTERN]"
        opts.separator ""
      end
    end

    def get_command(argv)
      option_parser.parse!(argv)

      command_name = argv.shift or abort option_parser.to_s
      command_class = command_name.capitalize + "Command"

      begin
        klass = self.class.const_get(command_class)
        command = klass.new(@config, @stdout, @stderr)
        command.parse!(argv)
        command
      rescue NameError
        abort "Unknown command #{command_name.inspect}"
      end
    end

    def run!(argv)
      @status = catch(:quit) {
        command = get_command(argv)
        command.run!
      }
    end

    class Command
      include Helper

      def initialize(config, stdout, stderr)
        @config = config
        @stdout = stdout
        @stderr = stderr
        @status = nil
      end

      attr_reader :config
      attr_reader :stdout
      attr_reader :stderr
      attr_reader :status

      def ivar(name)
        instance_variable_get("@#{name}")
      end

      def get_dump(version)
        dump = @config.create_dump(version)
        dump.exists? or abort "Dump #{version.inspect} does not exist"
        dump
      end

      def parse!(argv)
        @status = catch(:quit) {
          parse(argv)
        }
      end

      def run!
        @status = catch(:quit) {
          begin
            run
            throw :quit, 0
          rescue MysqlInspector::Access::Error => e
            abort e.message
          end
        }
      end
    end

    class WriteCommand < Command

      def parse(argv)
        @database = argv.shift or usage "write DATABASE [VERSION]"
        @version = argv.shift || CURRENT
      end

      def run
        config.database_name = @database
        config.write_dump(@version)
      end
    end

    class LoadCommand < Command

      def parse(argv)
        @database = argv.shift or usage "load DATABASE [VERSION]"
        @version  = argv.shift || CURRENT
      end

      def run
        get_dump(@version) # ensure it exists
        config.database_name = @database
        config.load_dump(@version)
      end
    end

    class GrepCommand < Command
      include Formatting

      def parse(argv)
        @version = CURRENT
        @matchers = argv.map { |a| Regexp.new(a) }
      end

      def run
        dump = get_dump(@version)

        grep = Grep.new(dump, @matchers)
        grep.execute

        puts "grep #{@matchers.map { |m| m.inspect } * " AND "}"

        puts if grep.any_matches?

        grep.each_table { |table, subset|
          puts table.table_name
          format_items("COL", subset.columns)
          format_items("IDX", subset.indices)
          format_items("CST", subset.constraints)
          puts
        }
      end
    end

    class DiffCommand < Command
      include Formatting

      def parse(argv)
        case argv.size
        when 0
          @version1 = CURRENT
          @version2 = TARGET
        when 1
          @version1 = CURRENT
          @version2 = argv.shift
        else
          @version1 = argv.shift
          @version2 = argv.shift
        end
      end

      def run
        dump1 = get_dump(@version1)
        dump2 = get_dump(@version2)

        diff = Diff.new(dump1, dump2)
        diff.execute

        puts "diff #{@version1} #{@version2}"

        tables = diff.added_tables + diff.missing_tables + diff.different_tables

        if tables.any?
          puts
          tables.sort.each do |t|
            prefix = prefix_for_table(t, diff)
            puts "#{prefix} #{t.table_name}"
            if t.is_a?(Diff::TableDiff)
              format_diff_items("  COL", t.added_columns, t.missing_columns)
              format_diff_items("  IDX", t.added_indices, t.missing_indices)
              format_diff_items("  CST", t.added_constraints, t.missing_constraints)
            end
          end
          puts
        end
      end

    protected

      def prefix_for_table(table, diff)
        case
        when diff.added_tables.include?(table) then "+"
        when diff.missing_tables.include?(table) then "-"
        else "="
        end
      end

      def prefix_for_item(item, added, removed)
        added.include?(item) ? "+" : "-"
      end

      def format_diff_items(label, added, removed)
        format_items(label, (added + removed).sort) { |item|
          prefix = prefix_for_item(item, added, removed)
          "#{prefix} #{item.to_sql}"
        }
      end
    end

  end
end
