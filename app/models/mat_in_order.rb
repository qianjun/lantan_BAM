#encoding: utf-8
class MatInOrder < ActiveRecord::Base
  belongs_to :material
  belongs_to :material_order
  belongs_to :staff

  def self.in_list store_id,first_time,last_time,types=nil,name=nil,code=nil,ids=nil
    sql = ["select materials.*,o.material_num,s.name staff_name,o.price out_price,o.created_at out_time,mo.code order_code,
     c.name cname,o.id o_id,o.remark o_remark from mat_in_orders o inner join materials on materials.id=o.material_id inner join categories c
     on materials.category_id=c.id
      inner join staffs s on s.id=o.staff_id left join material_orders mo on mo.id=o.material_order_id where c.types=? and c.store_id=?
      and materials.status=? and date_format(o.created_at,'%Y-%m-%d') between '#{first_time}' and '#{last_time}'", Category::TYPES[:material], store_id,
      Material::STATUS[:NORMAL]]
    unless types.nil? || types==0 || types==-1
      sql[0] += " and c.id=?"
      sql << types
    end
    unless name.nil? || name.strip.empty?
      sql[0] += " and materials.name like ?"
      sql << "%#{name.strip.gsub(/[%_]/){|x| '\\' + x}}%"
    end
    unless code.nil? || code.strip.empty?
      sql[0] += " and materials.code=?"
      sql << code
    end
    unless ids.nil? || ids.strip.empty?
      sql[0] += ' and o.id in (?)'
      sql << ids.split(",").compact.uniq
    end
    sql[0] += " order by o.created_at desc"
    records = Material.find_by_sql(sql)
    arr = []
    arr << records
    t_money = 0
    records.each do |r|
      t_money += r.out_price.to_f * r.material_num.to_i
    end
    arr << records.length
    arr << t_money
    return arr
  end
end
