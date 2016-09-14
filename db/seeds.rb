#encoding: utf-8
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
City.create(:name => "北京",:order_index =>1 ,:parent_id => 1)
#菜单
num = 0
Menu.create(:id => num+1,:controller => "customers",:name => "客户管理")
Menu.create(:id => num+2,:controller => "materials",:name => "库存管理")
Menu.create(:id => num+3,:controller => "staffs",:name => "员工管理")
Menu.create(:id => num+4,:controller => "datas",:name => "统计管理")
Menu.create(:id => num+5,:controller => "stations",:name => "现场管理")
Menu.create(:id => num+6,:controller => "sales",:name => "营销管理")
Menu.create(:id => num+7,:controller => "base_datas",:name => "基础数据")
Menu.create(:id => num+8,:controller => "pay_cash",:name => "收银")
Menu.create(:id => num+9,:controller => "finances",:name => "财务管理")
#角色
Role.create(:id => num+1,:name => "系统管理员")
Role.create(:id => num+2,:name => "老板")
Role.create(:id => num+3,:name => "店长")
Role.create(:id => num+4,:name => "员工")
#门店
Store.create(:id => num+1,:name => "杭州西湖路门店", :address => "杭州西湖路", :phone => "",
  :contact => "", :email => "", :position => "", :introduction => "", :img_url => "",
  :opened_at => Time.now, :account => 0, :created_at => Time.now, :updated_at => Time.now,
  :city_id => 1, :status => 1)
#系统管理员
staff = Staff.create(:name => "系统管理员", :type_of_w => 0, :position => 0, :sex => 1, :level => 2, :birthday => Time.now,
  :status => Staff::STATUS[:normal], :store_id => Store.first.id, :username => "admin", :password => "123456")
staff.encrypt_password
staff.save
StaffRoleRelation.create(:role_id => num+1, :staff_id => staff.id)

#系统管理员菜单权限
RoleMenuRelation.create(:role_id => num+1, :menu_id => num+1)
RoleMenuRelation.create(:role_id => num+1, :menu_id => num+2)
RoleMenuRelation.create(:role_id => num+1, :menu_id => num+3)
RoleMenuRelation.create(:role_id => num+1, :menu_id => num+4)
RoleMenuRelation.create(:role_id => num+1, :menu_id => num+5)
RoleMenuRelation.create(:role_id => num+1, :menu_id => num+6)
RoleMenuRelation.create(:role_id => num+1, :menu_id => num+7)
RoleMenuRelation.create(:role_id => num+1, :menu_id => num+8)
RoleMenuRelation.create(:role_id => num+1, :menu_id => num+9)

#系统管理员功能权限1048576
RoleModelRelation.create(:role_id => num+1, :model_name => 'customers', :num => 16384)
RoleModelRelation.create(:role_id => num+1, :model_name => 'materials', :num => 4294967296)
RoleModelRelation.create(:role_id => num+1, :model_name => 'staffs', :num => 65536)
RoleModelRelation.create(:role_id => num+1, :model_name => 'datas', :num => 2097152)
RoleModelRelation.create(:role_id => num+1, :model_name => 'stations', :num => 2)
RoleModelRelation.create(:role_id => num+1, :model_name => 'sales', :num => 2097152)
RoleModelRelation.create(:role_id => num+1, :model_name => 'base_datas', :num => 1023)
RoleModelRelation.create(:role_id => num+1, :model_name => 'pay_cash', :num => 1)
RoleModelRelation.create(:role_id => num+1, :model_name => 'finances', :num => 1)

#系统管理员
unless Staff.where(username: 'kbn-admin', type_of_w: '-1').first.present?
  puts 'Starting init an admin user in staffs'
  staff = Staff.create(name: "总部管理员",
    type_of_w: -1, position: 0, sex: 1, level: 2, birthday: Time.now,
    status: Staff::STATUS[:normal], store_id: Store.first.id, phone: '-1',
    username: "bam-admin", password: "bam123456")
  staff.encrypt_password
  staff.save
  p staff.errors

end
