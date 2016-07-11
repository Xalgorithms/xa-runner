require 'multi_json'

require 'xa/registry/client'
require 'xa/rules/context'
require 'xa/rules/interpret'

def interpret_execute(content, tables)
  include XA::Rules::Interpret

  ctx = XA::Rules::Context.new(tables)
  res = ctx.execute(interpret(content))
  yield(res)
end

(registry, rule_ref, dir) = ARGV

puts "> Loading additional tables from #{dir}"
tables = {}
Dir.glob(File.join(dir, 'table.*.json')).each do |fn|
  puts ">> loading table from #{File.basename(fn)}"
  File.open(fn) do |f|
    tables[File.basename(fn).split('.')[1]] = MultiJson.load(f.read)
  end
end

puts "> Getting remote rule (#{rule_ref}) from #{registry}"
cl = XA::Registry::Client.new(registry)
rule_content = cl.rules(*rule_ref.split(/:/))

if rule_content
  puts "> Executing rule"
  interpret_execute(rule_content, tables) do |res|
  end
else
  puts "! failed to download rule"
end
