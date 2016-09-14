#encoding: utf-8
class MaterialLoss < ActiveRecord::Base
  belongs_to :staff
  belongs_to :material
  TYPES = {:LESS =>0,:MORE =>1}
  TYPES_NAME = {0=>"报损",1 => "报溢"}


  #  def self.list page,per_page,store_id,sql=[nil,nil,nil]
  #    sql[0] = sql[0].blank? ? "1 = 1" : ["code = ?",sql[0]]
  #    sql[1] = sql[1].blank? ? "1 = 1" : ["m.name like ?", "%#{sql[1].gsub(/[%_]/){|x| '\\' + x}}%"]
  #    sql[2] = (sql[2].blank? ||  sql[2] == "-1") ? "1 = 1" : ["types = ?", sql[2].to_i]
  #
  #    MaterialLoss.where(sql[0]).where(sql[1]).where(sql[2]).where("m.status = #{Material::STATUS[:NORMAL]} and m.store_id = #{store_id}").paginate(
  #      :select =>"ml.id, ml.loss_num, ml.store_id, m.code, m.name, m.status, m.types, m.unit, m.price, m.sale_price, s.name staff_name",
  #      :from => "material_losses ml",
  #      :joins => "inner join materials m on ml.material_id =  m.id inner join staffs s on ml.staff_id = s.id",
  #      :order => "ml.created_at desc",
  #      :page => page,:per_page => per_page)
  #  end
  def self.loss_list store_id,types=nil,name=nil,code=nil
    sql = ["select ml.id, ml.loss_num,ml.store_id, m.code, m.name, m.status, m.types, m.unit, m.price, m.sale_price,ml.remark,
    s.name staff_name, c.name cname,ml.types m_types from material_losses ml inner join materials m on ml.material_id=m.id inner join categories c
    on m.category_id=c.id inner join staffs s on ml.staff_id=s.id where m.status=? and c.store_id=? and c.types=?",
      Material::STATUS[:NORMAL], store_id, Category::TYPES[:material]]
    unless types.nil? || types==0 || types==-1
      sql[0] += " and c.id=?"
      sql << types
    end
    unless name.nil? || name.strip.empty?
      sql[0] += " and m.name like ?"
      sql << "%#{name.strip.gsub(/[%_]/){|x| '\\' + x}}%"
    end
    unless code.nil? || code.strip.empty?
      sql[0] += " and m.code=?"
      sql << code.strip
    end
    sql[0] += " order by ml.created_at desc"
    records = MaterialLoss.find_by_sql(sql)
    return records
  end
end