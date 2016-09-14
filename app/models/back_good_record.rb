#encoding: utf-8
class BackGoodRecord < ActiveRecord::Base
  belongs_to :supplier
  belongs_to :material
  def self.back_list store_id,type=nil,name=nil,code=nil,supp=nil
    sql = ["select bgr.*,m.name mname,m.code mcode,c.name cname, s.name sname,bgr.price b_price
            from back_good_records bgr inner join materials m on bgr.material_id = m.id
            inner join categories c on m.category_id=c.id
            inner join suppliers s on bgr.supplier_id=s.id
            where bgr.store_id = ? ", store_id]
    unless type.nil? || type==0 || type==-1
      sql[0] += " and c.id=?"
      sql << type
    end
    unless name.nil? || name.strip.empty?
      sql[0] += " and m.name like ?"
      sql << "%#{name.strip.gsub(/[%_]/){|x| '\\' + x}}%"
    end
    unless code.nil? || code.strip.empty?
      sql[0] += " and m.code = ?"
      sql << code.strip
    end
    unless supp.nil? || supp==0
      sql[0] += " and bgr.supplier_id=?"
      sql << supp
    end
    sql[0] += " order by bgr.created_at desc"
    records = BackGoodRecord.find_by_sql(sql)
    return records
  end
end
