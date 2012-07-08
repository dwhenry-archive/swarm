10.times do
  a = rand

  b = a < 0.5 ? 'low' : 'high'

  puts b
end

require "coverage.so"
Coverage.start
require "coverage.rb"
p Coverage.result