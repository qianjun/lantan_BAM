#encoding: utf-8
class Knowlege < ActiveRecord::Base

  #宣传推广示例
  SAMPLE = [{:title=>"夏天如何加油才会更省",:img_url=>"/assets/sample.jpg",
      :description=>"最好是按照厂家所规定的标号去使用汽油，正常情况下，最好以使用下限要求的标号油较好。"},{},{}]

  def self.sample
    SAMPLE.inject([]) {|arr,sam|arr << Knowlege.new(sam)}
  end
end
