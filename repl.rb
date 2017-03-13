require 'multi_json'
require 'readline'

def load_table(args, env)
  if args.length > 1
    if File.exists?(args[1])
      env[:tables].merge!(args[0] => MultiJson.decode(IO.read(args[1])))
    else
      puts "! no such file: #{args[0]}"
    end
  else
    puts 'use: .table <name> <file>'
  end

  env
end

def list_tables(_, env)
  env[:tables].each do |name, vals|
    puts "#{name}: #{vals.length} rows"
  end
end

def missing(args)
  puts '!unknown'
end

commands = {
  'table'  => method(:load_table),
  'tables' => method(:list_tables),
}

env = {
  tables: {},
}

begin
  while ln = Readline.readline('xa> ', true)
    m = /^\.(.+)/.match(ln)
    if m
      (cmd, *args) = m[1].split(/\s+/)
      env = commands.fetch(cmd, method(:missing)).call(args, env)
    else
      puts 'assume xalgo'
    end
  end
rescue Interrupt => e
  exit
end
