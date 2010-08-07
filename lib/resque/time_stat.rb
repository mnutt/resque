module Resque
  # The time stat subsystem.  Tracks stats based on day, hour, minute, or second
  module TimeStat
    extend self
    extend Helpers

    # Get all of the dates for a stat
    def get(stat, time_unit)
      keys = redis.zrangebyscore("stat:#{stat}-#{time_unit}", 0, 0)
      values = Array(redis.mget(*keys))

      results = {}
      Array(keys).each_with_index do |key, i|
        results[key.sub(/^stat:#{stat}-#{time_unit}-/, '')] = values[i].to_i
      end

      results
    end

    # Alias of 'get'
    def [](stat)
      get(stat)
    end

    # Increments the stat, bucketing based on the timestamp.
    #
    # Valid time_unit values are :day, :hour, :minute, and :second. Can
    # optionally accept a third int parameter.  The stat is then incremented
    # by that much
    def incr(stat, time_unit, by = 1)
      timestamped_key = timestamped_stat(stat, time_unit)
      redis.incrby("stat:#{timestamped_key}", by)
      redis.zadd("stat:#{stat}-#{time_unit}", 0, "stat:#{timestamped_key}")
    end

    # Increments the stat, bucketing based on day, hour, and minute
    def incr_all(stat, by = 1)
      [:day, :hour, :minute].each do |time_unit|
        incr(stat, time_unit, by)
      end
    end

    # Increments stat by one, bucketing based on the timestamp.
    def <<(stat, time_unit)
      incr stat, time_unit
    end

    # For a string stat name, decrements the stat by one, bucketing based on the timestamp.
    #
    # Valid time_unit values are :day, :hour, :minute, and :second. Can
    # optionally accept a third int parameter.  The stat is then decremented
    # by that much
    def decr(stat, time_unit, by = 1)
      timestamped_key = timestamped_stat(stat, time_unit)
      redis.decrby("stat:#{timestamped_key}", by)
    end

    # Decrements stat by one, bucketing based on the timestamp.
    def >>(stat, time_unit)
      decr stat, time_unit
    end

    # Clears all timestamps for the stat.
    def clear(stat)
      %w(day hour minute second).each do |time_unit|
        stat_list = redis.get("stat:#{stat}-#{time_unit}")
        if stat_list
          redis.mdel(stat_list)
          redis.del("stat:#{stat}-#{time_unit}")
        end
      end
    end

    protected

    def now
      @now || Time.now
    end

    def now=(time)
      @now = time
    end

    def timestamp(time_unit)
      timestamp = now.utc
      case time_unit.to_s
        when 'day' then timestamp - (timestamp.hour * 60 * 60) - (timestamp.min * 60) - timestamp.sec
        when 'hour' then timestamp - (timestamp.min * 60) - timestamp.sec
        when 'minute' then timestamp - timestamp.sec
        else timestamp
      end
    end

    def timestamped_stat(stat, time_unit)
      "#{stat}-#{time_unit}-#{timestamp(time_unit).strftime('%Y-%m-%d_%H:%M:%S')}"
    end

  end
end
