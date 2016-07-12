require 'faraday'
require 'faraday_middleware'

(dir, repo) = ARGV

class RepositoryClient
  def initialize(url)
    @conn = Faraday.new(url) do |f|
      f.request(:url_encoded)
      f.request(:json)
      f.response(:json, :content_type => /\bjson$/)
      f.adapter(Faraday.default_adapter)        
    end
  end

  def upload_table(name, ns, src)
    o = {
      name: name,
      namespace_name: ns,
      src: src,
      rule_type: 'table',
    }
    post_event(:events_rule_add, o) do |event_url|
      resp = @conn.get(event_url)
      resp = @conn.get(resp.body['url']) if resp.success?
      yield(resp.body) if resp.success?
    end
  end
  
  def upload_rule(name, ns, src)
    o = {
      name: name,
      namespace_name: ns,
      src: src,
      rule_type: 'xalgo',
    }
    post_event(:events_rule_add, o) do |event_url|
      resp = @conn.get(event_url)
      resp = @conn.get(resp.body['url']) if resp.success?
      yield(resp.body) if resp.success?
    end
  end

  private
  
  def post_event(name, o)
#    puts ">>> POST > /api/v1/events"
    resp = @conn.post('/api/v1/events', { name => o })
#    puts ">>> POST < #{resp.status}"
    yield(resp.body['url']) if resp.success?
  end
end

cl = RepositoryClient.new(repo)

def enumerate_dir(dir, glob)
  Dir.glob("#{dir}/#{glob}").each do |fn|
    pn = Pathname.new(fn).relative_path_from(Pathname.new(dir))
    (ns, bn) = pn.split
    yield(fn, ns, bn.to_s.split(/\./))
  end
end

versions = {}

puts "> uploading tables from #{dir} to #{repo}"
enumerate_dir(dir, '**/table.*.json') do |fn, ns, parts|
  puts ">> #{fn} / #{ns} / #{parts[1]}"
  cl.upload_table(parts[1], ns, IO.read(fn)) do |rule|
    versions[parts[1]] = rule['versions'].last
    puts ">>> Uploaded #{rule['namespace']['name']}:#{rule['name']}:#{rule['versions'].last}"
  end
end

puts "> uploading rules from #{dir}"
enumerate_dir(dir, '**/*.xalgo') do |fn, ns, parts|
  puts ">> #{fn} / #{ns} / #{parts[0]}"

  puts ">>> replacing variables"
  lns = []
  IO.read(fn).each_line do |ln|
    m = /\{((?:\w+))_version\}/.match(ln)
    if m
      lns << ln.gsub("{#{m[1]}_version}", versions[m[1]].to_s).strip
    else
      lns << ln.strip
    end
  end

  cl.upload_rule(parts[0], ns, lns.join("\r\n")) do |rule|
    puts ">>> Uploaded #{rule['namespace']['name']}:#{rule['name']}:#{rule['versions'].last}"
  end
end
