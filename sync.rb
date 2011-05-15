#!/usr/bin/env ruby

s = (ARGV[0] || 0.1).to_f

ls=[]
$stdin.each_line do |l|
  if l.strip.empty?
    unless ls.empty?
      sleep s
      puts ls
      ls=[]
    end
  else
    ls << l
  end
end
