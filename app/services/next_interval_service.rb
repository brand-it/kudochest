# frozen_string_literal: true
class NextIntervalService < Base::Service
  option :team
  option :attribute
  option :start_at, default: proc {}

  def call
    @start_at ||= Time.current
    send("next_#{frequency}")
  end

  private

  def next_never
    now.advance(years: 1_000)
  end

  def next_hourly
    now.advance(hours: 1)
  end

  def next_daily
    time = start_daily
    time = time.advance(days: 1) until Date::DAYNAMES[time.wday].downcase.in?(team.work_days)
    time.change(hour: hour)
  end

  def start_daily
    now.hour >= hour ? now.advance(days: 1) : now
  end

  def next_weekly
    days_till_next_week_start = week_start_wday - now.wday
    days_till_next_week_start += 7 unless days_till_next_week_start.positive?
    now.change(hour: hour).advance(days: days_till_next_week_start)
  end

  def next_monthly
    now.change(day: 1, hour: hour).advance(months: 1)
  end

  def next_quarterly
    quarter_start_month = ((now.month / 3.0).ceil * 3) - 2
    now.change(month: quarter_start_month, day: 1, hour: hour).advance(months: 3)
  end

  def next_yearly
    now.change(month: 1, day: 1, hour: hour).advance(years: 1)
  end

  def now
    @now ||= start_at.beginning_of_hour
  end

  def frequency
    @frequency ||= team.send(attribute)
  end

  def week_start_wday
    @week_start_wday ||= Date::DAYNAMES.index(team.week_start_day.titleize)
  end

  def hour
    @hour ||= team.token_hour
  end
end
