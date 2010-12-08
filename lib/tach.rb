require 'rubygems'
require 'formatador'

module Tach

  STDOUT.sync = true

  unless const_defined?(:VERSION)
    VERSION = '0.0.7'
  end

  def self.meter(times = 1, &block)
    Tach::Meter.new(times, &block)
  end

  def self.tach(name, &block)
    tach_start = Time.now
    instance_eval(&block)
    tach_finish = Time.now
    duration = tach_finish.to_f - tach_start.to_f
    Formatador.display_line
    Formatador.display_line("[bold]#{name}[/] [light_black]#{format("%0.6f", duration)}[/]")
    duration
  end

  class Meter

    def initialize(times = 1, &block)
      @benchmarks = []
      @results = {}
      @times = times

      instance_eval(&block)

      Formatador.display_line
      Formatador.display('[')
      data = []
      for name, block in @benchmarks
        data << { :tach => name, :total => format("%8.6f", run_tach(name, @times, &block)) }
        unless [name, block] == @benchmarks.last
          print(', ')
        end
      end
      print("]\n\n")
      data.sort! {|x,y| x[:total].to_f <=> y[:total].to_f }
      Formatador.display_table(data, [:tach, :total])
      Formatador.display_line
    end

    def tach(name, &block)
      @benchmarks << [name, block]
    end

    private

    def run_tach(name, count, &benchmark)
      GC::start
      print(name)
      tach_start = Time.now

      if benchmark.arity <= 0
        count.times { benchmark.call }
      else
        benchmark.call(count)
      end

      tach_finish = Time.now
      duration = tach_finish.to_f - tach_start.to_f
      duration
    end

  end

end

if __FILE__ == $0

  Tach.tach('sleep') do
    sleep(1)
  end

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

    tach('regex 4') do |n|
      n.times do
        header = data.match(/(.*):\s(.*)/)
        [$1, $2]
      end
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
