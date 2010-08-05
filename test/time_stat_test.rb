require File.dirname(__FILE__) + '/test_helper'

context "Resque::TimeStat" do
  setup do
    Resque.redis.flushall

    @time = Time.now
    Resque::TimeStat.send(:now=, @time)
  end

  test "can create a new stat" do
    Resque::TimeStat.incr("critical_success", :hour)

    assert_equal 1, Resque.redis.zcard("stat:critical_success-hour")
    stat_key = Resque.redis.zrangebyscore("stat:critical_success-hour", 0, 0).first
    assert_match %r{stat:critical_success-hour}, stat_key
    assert_match /#{@time.strftime("%Y-%m-%d_%H")}/, stat_key

    assert_equal "1", Resque::TimeStat.get("critical_success", :hour).first[1]
  end

  test "can increment a stat" do
    Resque::TimeStat.incr("critical_success", :hour)
    Resque::TimeStat.incr("critical_success", :hour)

    assert_equal 1, Resque.redis.zcard("stat:critical_success-hour")
    stat_key = Resque.redis.zrangebyscore("stat:critical_success-hour", 0, 0).first
    assert_equal "2", Resque.redis.get(stat_key)
  end

  test "can increment different timestamps for a stat" do
    Resque::TimeStat.incr("critical_success", :minute)

    # Move time forward 60s
    Resque::TimeStat.send(:now=, @time + 60)
    Resque::TimeStat.incr("critical_success", :minute)

    # Set time back
    Resque::TimeStat.send(:now=, @time)

    assert_equal 2, Resque.redis.zcard("stat:critical_success-minute")
    assert_equal ["1","1"], Resque::TimeStat.get("critical_success", :minute).map{|s| s[1] }
  end

  context "timestamp buckets" do
    setup do
      Resque::TimeStat.send(:now=, Time.utc(2010, "8", 04, 15, 26, 43))
      assert_equal "2010-08-04T15:26:43Z", Resque::TimeStat.send(:now).xmlschema
    end

    teardown do
      raise @time.to_s
      Resque::TimeStat.send(:now=, @time)
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
end
