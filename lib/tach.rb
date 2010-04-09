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
      longest = @benchmarks.map {|benchmark| benchmark[0]}.map {|name| name.length}.max
      for name, block in @benchmarks
        @results[name] = run_in_thread("#{name}#{' ' * (longest - name.length)}", @times, &block)
      end

      data = []
      for name, block in @benchmarks
        value = @results[name]
        total = value.inject(0) {|sum,item| sum + item}
        data << { :average => format("%8.6f", (total / value.length)), :tach => name, :total => format("%8.6f", total) }
      end

      Formatador.display_table(data, [:tach, :average, :total])
      Formatador.display_line
    end

    def tach(name, &block)
      @benchmarks << [name, block]
    end

    private

    def run_in_thread(name, count, &benchmark)
      Formatador.display_line(name)
      thread = Thread.new do
        Thread.current[:results] = []
        tach_start = Time.now
        for index in 1..count
          instance_eval(&benchmark)
        end
        GC::start
        tach_finish = Time.now
        Thread.current[:results] << tach_finish.to_f - tach_start.to_f
      end
      thread.join
      Formatador.display_line
      thread[:results]
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