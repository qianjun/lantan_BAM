#encoding: utf-8
class Fee < ActiveRecord::Base
  FEE_TAB = {0=>"租金",1=>"水电费",2=>"办公费",3=>"差旅费",4=> "招待费",5=>"工资",6=> "税金社保",7=>"待摊费用",8=>"资产折旧",9=>"其他"}

  FEE_CODE = {0=>"ZJ",1=>"SF",2=>"BF",3=>"CF",4=>"ZF",5=>"GF",6=>"JB",7=>"DT",8=>"ZC",9=>"QT"}

  FEE_TYPES = {0=>"基本结算户",1=>"备用金",2=>"银行卡",3=>"私人垫付"}
  STATUS = ApplicationHelper::MODEL_STATUS #0 正常 1 删除 2 作废
  STATUS_NAMES = {0=>"正常",1=>"删除"}
end
