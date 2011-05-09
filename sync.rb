#!/usr/bin/env ruby
ls=[]
$stdin.each_line do |l|
  if l.strip.empty?
    unless ls.empty?
      sleep 0.1
      puts ls
      ls=[]
    end
  else
    ls << l
  end
end
