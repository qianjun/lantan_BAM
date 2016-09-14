#encoding: utf-8
class PackageCard < ActiveRecord::Base
  has_many :pcard_prod_relations
  #  has_many :products, :through => :pcard_prod_relations
  has_many :pcard_material_relations
  has_many  :c_pcard_relations
  belongs_to :store

  STAT = {:INVALID =>0,:NORMAL =>1}  #0 为失效或删除  1 为正常使用
  TIME_SELCTED = {:PERIOD =>0,:END_TIME =>1} #0 时间段  1  有效时间长度
  scope :on_weixin, lambda{|store_id| where(:store_id => store_id,:on_weixin => true,:status=>STAT[:NORMAL])}
  
  #查询卡信息
  def self.search_pcard(store_id,pcard=nil,car_num=nil,c_name=nil,created_at=nil,ended_at=nil)
    conditions = [""]
    sql="select cp.id,c.name,c.mobilephone,p.name p_name,cp.content,p.price,cp.status,p.id p_id from c_pcard_relations cp inner join customers c on c.id=cp.customer_id
    inner join  package_cards p on p.id=cp.package_card_id "
    unless car_num.nil? || car_num == ""  || car_num.length ==0
      sql += " inner join customer_num_relations  cn on c.id=cn.customer_id inner join car_nums n on n.id=cn.car_num_id"
    end
    sql += " where p.store_id=#{store_id} and p.status=#{PackageCard::STAT[:NORMAL]} and cp.status != #{CPcardRelation::STATUS[:INVALID]}"
    sql += " and p.id=#{pcard}"  unless pcard.nil? || pcard == "" || pcard.length==0
    unless car_num.nil? || car_num == ""  || car_num.length ==0
      sql += " and n.num like ?"
      conditions << "%#{car_num.gsub('%', '\%')}%"
    end
    unless c_name.nil? || c_name == "" || c_name.length == 0
      sql += " and c.name like ?"
      conditions << "%#{c_name.gsub(/[%_]/){|x| '\\' + x}}%"
    end
    sql += " and cp.created_at > '#{created_at}'" unless created_at.nil? || created_at == "" || created_at.length ==0
    sql += " and cp.created_at < '#{ended_at}'" unless ended_at.nil? ||  ended_at == "" || ended_at.length == 0
    conditions[0] = sql
    return CPcardRelation.find_by_sql(conditions)
  end


end
