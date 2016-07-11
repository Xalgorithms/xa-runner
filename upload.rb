(dir, repo) = ARGV

def enumerate_dir(dir, glob)
  Dir.glob("#{dir}/#{glob}").each do |fn|
    pn = Pathname.new(fn).relative_path_from(Pathname.new(dir))
    (ns, bn) = pn.split
    yield(fn, ns, bn.to_s.split(/\./)[0])
  end
end

puts "> uploading tables from #{dir} to #{repo}"
enumerate_dir(dir, '**/table.*.json') do |fn, ns, name|
  puts ">> #{fn} / #{ns} / #{name}"
end

puts "> uploading rules from #{dir}"
enumerate_dir(dir, '**/*.xalgo') do |fn, ns, name|
  puts ">> #{fn} / #{ns} / #{name}"
end
