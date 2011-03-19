require 'rubygems'
require 'formatador'

module Tach

  STDOUT.sync = true

  unless const_defined?(:VERSION)
    VERSION = '0.0.8'
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
        durations = run_tach(name, @times, &block)
        total = durations.inject(0) {|sum, duration| sum + duration}
        average = total.to_f / @times.to_f

        # calculate standard deviation
        deviation_squares = durations.map do |duration|
          deviation = duration - average
          deviation * deviation
        end
        deviation_squares_average = deviation_squares.inject(0) {|sum, deviation| sum + deviation} / deviation_squares.length.to_f
        standard_deviation = Math.sqrt(deviation_squares_average)

        data << {
          :tach   => name,
          :total  => format("%8.6f", total),
          :min    => format("%8.6f", durations.min),
          :avg    => format("%8.6f", average),
          :max    => format("%8.6f", durations.max),
          :stddev => format("%8.6f", standard_deviation)
        }

        unless [name, block] == @benchmarks.last
          print(', ')
        end
      end
      print("]\n\n")
      data.sort! {|x,y| x[:total].to_f <=> y[:total].to_f }
      Formatador.display_table(data, [:tach, :total, :min, :avg, :max, :stddev])
      Formatador.display_line
    end

    def tach(name, &block)
      @benchmarks << [name, block]
    end

    private

    def run_tach(name, count, &benchmark)
      GC::start
      print(name)
      durations = []

      if benchmark.arity <= 0
        count.times do
          tach_start = Time.now
          benchmark.call
          tach_finish = Time.now
          durations << tach_finish.to_f - tach_start.to_f
        end
      else
        tach_start = Time.now
        benchmark.call(count)
        tach_finish = Time.now
        durations << tach_finish.to_f - tach_start.to_f
      end

      durations
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

end
