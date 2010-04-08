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
      @benchmarks.each do |name, block|
        @results[name] = run_in_thread("#{name}#{' ' * (longest - name.length)}", @times, block)
      end

      data = []
      @benchmarks.each do |name, block|
        value = @results[name]
        total = value.inject(0) {|sum,item| sum + item}
        data << { :average => format("%.5f", (total / value.length)), :tach => name, :total => format("%.5f", total) }
      end

      Formatador.display_table(data, [:tach, :average, :total])
      Formatador.display_line
    end

    def tach(name, &block)
      @benchmarks << [name, block]
    end

    private

    def run_in_thread(name, count, benchmark)
      thread = Thread.new {
        thread_start = Time.now
        Formatador.redisplay_progressbar(0, count, :label => name, :started_at => thread_start)
        count.times do |index|
          tach_start = Time.now
          instance_eval(&benchmark)
          tach_elapsed = Time.now.to_f - tach_start.to_f
          Thread.current[:results] ||= []
          Thread.current[:results] << tach_elapsed
          Formatador.redisplay_progressbar(index + 1, count, :label => name, :started_at => thread_start)
        end
        Formatador.display_line
      }
      thread.join
      thread[:results]
    end

  end

end
