#encoding: utf-8
#require 'barby'
#require 'barby/barcode/ean_13'
#require 'barby/outputter/custom_rmagick_outputter'
#require 'barby/outputter/rmagick_outputter'
class Material < ActiveRecord::Base
  has_many :prod_mat_relations
  has_many :material_losses
  has_many :mat_order_items
  has_many :back_good_records
  has_many :material_orders, :through => :mat_order_items do  
    def not_all_in
      where("m_status not in (?) and status != ?",[3,4], MaterialOrder::STATUS[:cancel])
    end
  end
  has_many :mat_out_orders
  has_many  :mat_in_orders
  has_many :prod_mat_relations
  has_many :mat_depot_relations
  has_many :pcard_material_relations
  has_many :depots, :through => :mat_depot_relations
  belongs_to :category
  attr_accessor :ifuse_code, :code_value

  before_create :generate_barcode
  after_create :generate_barcode_img
  STATUS = {:NORMAL => 0, :DELETE => 1}  #物料状态 0为正常 1 为删除 #是否上架  0 为没上架 1 为上架
  TYPES_NAMES = {0 => "清洁用品", 1 => "美容用品", 2 => "装饰产品", 3 => "配件产品", 4 => "电子产品",
    5 =>"其他产品",6 => "辅助工具", 7 => "劳动保护"}
  TYPES = { :CLEAN_PROD =>0, :BEAUTY_PROD =>1,:DECORATE_PROD =>2, :ACCESSORY_PROD =>3, :ELEC_PROD =>4,
    :OTHER_PROD => 5, :ASSISTANT_TOOL => 6, :LABOR_PROTECT => 7}
  PRODUCT_TYPE = [TYPES[:CLEAN_PROD], TYPES[:BEAUTY_PROD], TYPES[:DECORATE_PROD],
    TYPES[:ACCESSORY_PROD], TYPES[:ELEC_PROD], TYPES[:OTHER_PROD]]
  MAT_IN_PATH = "#{File.expand_path(Rails.root)}/public/uploads/mat_in/%s"
  MAT_OUT_PATH = "#{File.expand_path(Rails.root)}/public/uploads/mat_out/%s"
  MAT_CHECKNUM_PATH = "#{File.expand_path(Rails.root)}/public/uploads/mat_check/%s"
  IS_IGNORE = {:YES => 1, :NO => 0} #是否忽略库存预警， 1是 0否
  DEFAULT_MATERIAL_LOW = 0    #默认库存预警为0
  scope :normal, where(:status => STATUS[:NORMAL])
  CHECK_STATUS = {0=>"未盘点",1=>"已盘点"}
  CHECK_NAME = {:UNCOMPLETE =>0,:OVER =>1}
  MAT_RECORD = {0=>"少于库存数",1=>"多于库存数",2=>"相同"}
  RECORD_NAME = {:LESS =>0,:MORE =>1,:EQUAL =>2}


  def self.materials_list store_id,types=nil,name=nil,code=nil
    sql = ["select m.*, c.name  cname,ifnull(storage*sale_price,0) total_price from materials m inner join categories c on m.category_id=c.id
      where c.types=? and c.store_id=? and m.status=?", Category::TYPES[:material], store_id, Material::STATUS[:NORMAL]]
    unless types.nil? || types==0 || types==-1
      sql[0] += " and c.id=?"
      sql << types
    end
    unless name.nil? || name.strip.empty?
      sql[0] += " and m.name like ? or m.remark like ?"
      sql << "%#{name.strip.gsub(/[%_]/){|x| '\\' + x}}%"
      sql << "%#{name.strip.gsub(/[%_]/){|x| '\\' + x}}%"
    end
    unless code.nil? || code.strip.empty?
      sql[0] += " and m.code=?"
      sql << code.strip
    end
    records = Material.find_by_sql(sql)
    return records
  end

  def self.unsalable_list store_id,sql=[nil,nil,nil,nil]
    start_date = sql[0]
    sql[0] = sql[0].blank? ? "'1 = 1'" : "created_at >='#{sql[0]} 00:00:00'"
    sql[1] = sql[1].blank? ? "'1 = 1'" : "created_at <='#{sql[1]} 23:59:59'"
    sql[2] = sql[2].blank? ? nil : "having count(material_id) >= #{sql[2]}"
    sql[3] = sql[3].blank? ? "'1 = 1'" : "m.types = #{sql[3].to_i}"
    Material.find_by_sql("select * from materials m where m.id not in(select material_id as id from mat_out_orders where
    #{sql[0]} and #{sql[1]} and types = 3 and store_id = #{store_id} group by material_id  #{sql[2]}) and m.status !=#{Material::STATUS[:DELETE]} and m.store_id = #{store_id} and #{sql[3]} and created_at < '#{start_date} 00:00:00';")
  end

  private
  
  def generate_barcode
    if self.ifuse_code=="0"
      code = Time.now.strftime("%Y%m%d%H%M%L")[1..-1]
      code[0] = ''
      code[0] = ''
      self.code = code
    end
    if self.code_value
      self.code = self.code_value.strip[0..-2]
    end
  end

  def generate_barcode_img
    begin
      barcode = Barby::EAN13.new(self.code)
      if !FileTest.directory?("#{File.expand_path(Rails.root)}/public/barcode/#{Time.now.strftime("%Y%m")}")
        FileUtils.mkdir_p "#{File.expand_path(Rails.root)}/public/barcode/#{Time.now.strftime("%Y%m")}"
      end
      barcode.to_image_with_data(:height => 210, :margin => 60, :xdim => 5).write(Rails.root.join('public', "barcode", "#{Time.now.strftime("%Y%m")}", "#{self.id}.png"))
      self.update_attributes(:code => self.code+barcode.checksum.to_s, :code_img => "/barcode/#{Time.now.strftime("%Y%m")}/#{self.id}.png")
    rescue
      self.errors[:barby] << "条形码图片生成失败！"
    end
  end

  #更新库存并生成出库记录
  def self.update_storage(material_id,result_storage,staff,remark,types,order=nil)
    Material.transaction do
      material = Material.find_by_id(material_id)
      used_stoage = material.storage-result_storage
      material.update_attribute("storage",result_storage)
      if used_stoage > 0
        MatOutOrder.create(:material => material, :material_num => used_stoage,
          :staff_id => staff, :price => material.price, :types => types.nil? ? MatOutOrder::TYPES_VALUE[:sale] : types,
          :store_id => material.store_id,:remark=>remark,:detailed_list=>material.detailed_list,:order_id=>order.nil? ? nil : order.id)
      elsif used_stoage < 0
        MatInOrder.create({:material => material, :material_order_id => nil,
            :material_num =>-used_stoage , :price => material.import_price, :staff_id =>staff,:remark=>remark })
      end
    end
  end

end
