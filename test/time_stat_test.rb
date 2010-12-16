require File.dirname(__FILE__) + '/test_helper'

context "Resque::TimeStat" do
  setup do
    Resque.redis.flushall

    @time = Time.now
    Resque::TimeStat.send(:now=, @time)
  end

  test "can create a new stat" do
    stat_key = Resque::TimeStat.incr("critical_success", :hour)

    assert_match %r{stat:critical_success-hour}, stat_key
    assert_equal 1, Resque.redis.get(stat_key).to_i
  end

  test "can increment a stat" do
    Resque::TimeStat.incr("critical_success", :hour)
    stat_key = Resque::TimeStat.incr("critical_success", :hour)

    assert_equal "2", Resque.redis.get(stat_key)
  end

  test "can increment different timestamps for a stat" do
    Resque::TimeStat.incr("critical_success", :minute)

    # Move time forward 60s
    Resque::TimeStat.send(:now=, @time + 60)

    Resque::TimeStat.incr("critical_success", :minute)

    assert_equal [1, 1], Resque::TimeStat.get("critical_success", :minute).map{|s| s[1] }.select{|k,v| k > 0}

    # Set time back
    Resque::TimeStat.send(:now=, @time)
  end

  test "can increment all time_units at once" do
    Resque::TimeStat.incr_all("critical_success")

    ['day', 'hour', 'minute'].each do |time_unit|
      assert_equal 1, Resque::TimeStat.get("critical_success", time_unit.to_sym).select{|k,v| v > 0 }.size
    end
  end

  context "timestamp buckets" do
    setup do
      Resque::TimeStat.send(:now=, Time.utc(2010, "8", 04, 15, 26, 43))
      assert_equal "2010-08-04T15:26:43Z", Resque::TimeStat.send(:now).xmlschema
    end

    test "second" do
      assert_equal "2010-08-04T15:26:43Z", Resque::TimeStat.send(:timestamp, :second).xmlschema
    end

    test "beginning of minute" do
      assert_equal "2010-08-04T15:26:00Z", Resque::TimeStat.send(:timestamp, :minute).xmlschema
    end

    test "beginning of hour" do
      assert_equal "2010-08-04T15:00:00Z", Resque::TimeStat.send(:timestamp, :hour).xmlschema
    end

    test "beginning of day" do
      assert_equal "2010-08-04T00:00:00Z", Resque::TimeStat.send(:timestamp, :day).xmlschema
    end
  end

  context "timestamp ranges" do
    setup do
      Resque::TimeStat.send(:now=, Time.utc(2010, "8", 04, 15, 26, 43))
      assert_equal "2010-08-04T15:26:43Z", Resque::TimeStat.send(:now).xmlschema
    end

    test "day" do
      timestamps = Resque::TimeStat.send(:timestamp_range, :day)

      assert_equal 30, timestamps.size
      assert_equal "2010-08-04T00:00:00Z", timestamps.first.xmlschema # beginning of day
      assert_equal "2010-07-06T00:00:00Z", timestamps.last.xmlschema # 29 days before
    end

    test "hour" do
      timestamps = Resque::TimeStat.send(:timestamp_range, :hour)

      assert_equal 24, timestamps.size
      assert_equal "2010-08-04T15:00:00Z", timestamps.first.xmlschema # beginning of hour
      assert_equal "2010-08-03T16:00:00Z", timestamps.last.xmlschema # 23 hours before
    end

    test "minute" do
      timestamps = Resque::TimeStat.send(:timestamp_range, :minute)

      assert_equal 60, timestamps.size
      assert_equal "2010-08-04T15:26:00Z", timestamps.first.xmlschema # beginning of minute
      assert_equal "2010-08-04T14:27:00Z", timestamps.last.xmlschema # 59 minutes before
    end
  end
end

