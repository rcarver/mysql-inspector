require 'optparse'
require 'stringio'

module MysqlInspector
  class CLI

    NAME = "mysql-inspector"

    CURRENT = "current"
    TARGET  = "target"

    def initialize(config, stdout=nil, stderr=nil)
      @config = config
      @stdout = stdout || StringIO.new
      @stderr = stderr || StringIO.new
      @status = 0
    end

    attr_reader :stdout
    attr_reader :stderr
    attr_reader :status

    def exit(msg)
      @stdout.puts msg
      @status = 0
      throw :quit
    end

    def abort(msg)
      @stderr.puts msg
      @status = 1
      throw :quit
    end

    def puts(*args)
      @stdout.puts(*args)
    end

    def usage(msg)
      abort "Usage: #{NAME} #{msg}"
    end

    def option_parser
      @option_parser ||= OptionParser.new do |opts|
        opts.banner = "Usage: #{NAME} [options] command [command args]"

        opts.separator ""
        opts.separator "Options"
        opts.separator ""

        opts.on("--out DIR", "Where to store schemas. Defaults to '.'") do |dir|
          @config.dir = dir
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

    def run(argv)
      option_parser.parse!(argv)

      command = argv.shift

      if respond_to?("run_#{command}")
        send("run_#{command}", argv)
      else
        abort option_parser.to_s
      end
    end

    def run_write(argv)
      database = argv.shift or usage "write DATABASE [VERSION]"
      version  = argv.shift || CURRENT

      begin
        @config.write_dump(version, database)
      rescue MysqlInspector::Access::Error => e
        abort e.message
      end
    end

    def run_load(argv)
      database = argv.shift or usage "load DATABASE [VERSION]"
      version  = argv.shift || CURRENT

      get_dump(version) # ensure it exists

      begin
        @config.load_dump(version, database)
      rescue MysqlInspector::Access::Error => e
        abort e.message
      end
    end

    def run_grep(argv)
      dump = get_dump(CURRENT)

      matchers = *argv.map { |a| Regexp.new(a) }
      grep = Grep.new(dump, matchers)
      grep.execute

      puts "#{dump.db_name}@#{CURRENT}"
      puts
      puts "grep #{matchers.map { |m| m.inspect } * " AND "}"

      puts if grep.any_matches?

      grep.each_table { |table, subset|
        puts table.table_name
        format_items("COL", subset.columns)
        format_items("IDX", subset.indices)
        format_items("CST", subset.constraints)
        puts
      }
    end

    def run_diff(argv)
      dump1 = get_dump(CURRENT)
      dump2 = get_dump(TARGET)

      diff = Diff.new(dump1, dump2)
      diff.execute

      puts "diff #{dump1.db_name}@#{CURRENT} #{dump2.db_name}@#{TARGET}"

      tables = diff.added_tables + diff.missing_tables + diff.different_tables

      if tables.any?
        puts
        tables.sort.each do |t|
          prefix = diff_prefix_for_table(t, diff)
          puts "#{prefix} #{t.table_name}"
          if t.is_a?(Diff::TableDiff)
            diff_format_items("  COL", t.added_columns, t.missing_columns)
            diff_format_items("  IDX", t.added_indices, t.missing_indices)
            diff_format_items("  CST", t.added_constraints, t.missing_constraints)
          end
        end
        puts
      end
    end

  protected

    def get_dump(version)
      dump = @config.create_dump(version)
      dump.exists? or abort "Dump #{version.inspect} does not exist"
      dump
    end

    # Print table details
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

    def diff_prefix_for_table(table, diff)
      case
      when diff.added_tables.include?(table) then "+"
      when diff.missing_tables.include?(table) then "-"
      else "="
      end
    end

    def diff_prefix_for_item(item, added, removed)
      added.include?(item) ? "+" : "-"
    end

    def diff_format_items(label, added, removed)
      format_items(label, (added + removed).sort) { |item|
        prefix = diff_prefix_for_item(item, added, removed)
        "#{prefix} #{item.to_sql}"
      }
    end

  end
end
