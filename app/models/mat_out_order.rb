#encoding: utf-8
class MatOutOrder < ActiveRecord::Base
  belongs_to :material
  belongs_to :material_order
  belongs_to :order

  TYPES = {0 => "消耗", 1 => "调拨", 2 => "赠送", 3 => "销售",4=>"快速出库",5=>"领用"}
  TYPES_VALUE = {:cost => 0, :transfer => 1, :send => 2, :sale => 3,:quick_out =>4,:deploy=>5}

  def self.out_list store_id,first_time,last_time,types=nil,name=nil,o_types=nil,ids=nil
    sql = ["select materials.*,o.material_num,s.name staff_name,o.price out_price,o.created_at out_time,o.types out_types,
     c.name cname,o.id out_id,o.detailed_list d_list,o.remark o_remark,od.code o_code,od.id o_id from mat_out_orders o inner join
     materials on materials.id=o.material_id inner join categories c on materials.category_id=c.id inner join staffs s on s.id=o.staff_id
    left join orders od on od.id=o.order_id  where c.types=? and c.store_id=? ", Category::TYPES[:material], store_id]
    unless types.nil? || types==0 || types==-1
      sql[0] += " and c.id=?"
      sql << types
    end
    unless name.nil? || name.strip.empty?
      sql[0] += " and materials.name like ?"
      sql << "%#{name.strip.gsub(/[%_]/){|x| '\\' + x}}%"
    end
    unless o_types.nil? || o_types.strip.empty?
      sql[0] += " and o.types=?"
      sql << o_types
    end
    unless ids.nil? || ids.strip.empty?
      sql[0] += ' and o.id in (?)'
      sql << ids.split(",").compact.uniq
    end
    sql[0] += " and date_format(o.created_at,'%Y-%m-%d') between '#{first_time}' and '#{last_time}' order by o.created_at desc"
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

  def self.new_out_order selected_items,store_id,staff,types,remark
    status = 0
    Material.transaction do
      begin
        (selected_items.split(",") || []).each do |item|
          material = Material.find_by_id_and_store_id item.split("_")[0],store_id
          #出库记录 门店出库没有订单id和价格，并修改库存量
          Material.update_storage(item.split("_")[0],material.storage - item.split("_")[1].to_i,staff,remark,types)   if material
        end
      rescue
        status = 1
      end
    end
    status
  end
end
