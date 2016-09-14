#encoding: utf-8
class Log < ActiveRecord::Base
  STATUS = {:NOMARL =>1,:UNAUTHOR =>0} #0未审核 1 正常
  ROLL = {:YES =>1,:NO =>0} #1 播报 0 不播报
  SHOW_INDEX = {:YES =>1,:NO =>0} #0 显示在更新 1 不显示在更新
end
