require 'rubygems'
require 'annals'
require 'formatador'

module Tach

  def self.meter(times = 1, &block)
    Tach::Meter.new(times, &block)
  end

  class Meter

    def initialize(times = 1, &block)
      @benchmarks = []
      @results = {}
      @times = times

      instance_eval(&block)

      Formatador.display_line
      data = []
      for name, block in @benchmarks
        data << { :tach => name, :total => format("%8.6f", run_tach(name, @times, &block)) }
      end
      Formatador.display_table(data, [:tach, :total])
      Formatador.display_line
    end

    def tach(name, &block)
      @benchmarks << [name, block]
    end

    private

    def run_tach(name, count, &benchmark)
      GC::start
      Formatador.display_line(name)
      tach_start = Time.now
      for index in 1..count
        instance_eval(&benchmark)
      end
      tach_finish = Time.now
      Formatador.display_line
      tach_finish - tach_start
    end

  end

end

if __FILE__ == $0

  data = 'Content-Length: 100'
  Tach.meter(100_000) do

    tach('regex 1') do
      header = data.match(/(.*):\s(.*)/)
      [$1, $2]
    end

    tach('regex 2') do
      header = data.match(/(.*):\s(.*)/)
      [$1, $2]
    end

    tach('regex 3') do
      header = data.match(/(.*):\s(.*)/)
      [$1, $2]
    end

  end

require 'benchmark'
Benchmark.bm do |bench|
  bench.report('regex 1') do
    100_000.times do
      header = data.match(/(.*):\s(.*)/)
      [$1, $2]
    end
  end
  bench.report('regex 2') do
    100_000.times do
      header = data.match(/(.*):\s(.*)/)
      [$1, $2]
    end
  end
  bench.report('regex 3') do
    100_000.times do
      header = data.match(/(.*):\s(.*)/)
      [$1, $2]
    end
  end
end

end