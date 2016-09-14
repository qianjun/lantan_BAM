#encoding: utf-8
class ReturnBacksController < ApplicationController
  layout nil

  def return_info
    render :text=>WorkOrder.update_work_order(request.parameters)
  end

  def return_msg
    message = ""
    begin
      #msg = TotalMsg.find params[:id]
      #message = msg.attributes.select { |key,value| key =~ /msg[0-9]{1,}/ && !value.nil? && value != "" }.values.join("?") if msg
      store = Store.find_by_code(params[:code])
      current_date = Time.now.to_s
      now_date = (current_date.slice(0,4) + current_date.slice(5,2) + current_date.slice(8,2)).to_i
      if store
        #查询所有未删除的工位信息
        stations = Station.find_by_sql(["select s.id, s.status, s.name
          from stations s where s.status != ?
          and s.store_id = ? order by cast(s.code as signed) asc", Station::STAT[:DELETED], store.id])
        #查询工单
        if stations.any?
          work_orders = Station.find_by_sql("select s.id as station_id, TIMESTAMPDIFF(SECOND, now(), w.ended_at)
            as time_left, c.num as car_num, o.id order_id
            from stations s inner join
            work_orders w on s.id =  w.station_id inner join orders o on w.order_id = o.id inner join
            car_nums c on o.car_num_id = c.id where s.store_id = #{store.id} and w.current_day = #{now_date} and
            o.status != #{Order::STATUS[:DELETED]} and w.status = #{ WorkOrder::STAT[:SERVICING]}")
          s_w_os = {}
          work_orders.each { |wo| s_w_os[wo.station_id] = wo }
          #获取工单中的服务项目
          order_ids = work_orders.map{|w| w.order_id }
          order_products = Product.find_by_sql(["select p.name, opr.order_id from products p
          inner join order_prod_relations opr
          on opr.product_id = p.id where  opr.order_id in (?) order by p.id ",
              order_ids]).group_by {|item| item.order_id }
          msg_arr = []
          stations.each do |s|
            msg = ""
            num = 0
            if s_w_os[s.id] and order_products[s_w_os[s.id].order_id].any?
              if order_products[s_w_os[s.id].order_id].length > 1
                if s_w_os[s.id].time_left > 0
                  num = s_w_os[s.id].time_left/5%(order_products[s_w_os[s.id].order_id].length)
                end
              end
              if order_products[s_w_os[s.id].order_id][num]
                pro = order_products[s_w_os[s.id].order_id][num]
                msg = " "*4 + s_w_os[s.id].car_num + " "*4 + "\n"
                name_length = 0
                n = 0
                pro.name.unpack("U*").each { |ca|
                  if name_length <=14
                    name_length += ca<127 ? 1 : 2
                    n += 1
                  end
                }
                space_length = (16 - name_length)/2
                msg += " " * space_length + pro.name[0..n] + " " * (16 - name_length - space_length) + "\n"
                min = ((s_w_os[s.id].time_left.to_i/60).to_i >= 10) ? (s_w_os[s.id].time_left.to_i/60).to_i.to_s : "0#{(s_w_os[s.id].time_left.to_i/60).to_i.to_s}"
                sec = ((s_w_os[s.id].time_left.to_i%60).to_i >= 10) ? (s_w_os[s.id].time_left.to_i%60).to_i.to_s : "0#{(s_w_os[s.id].time_left.to_i%60).to_i.to_s}"
                time_left = s_w_os[s.id].time_left<0 ? "00:00" : "#{min}:#{sec}"
                msg +=  " " * 5 + time_left + " "*(16 - 5 - time_left.to_s.length)
              end
            end
            msg = "\n    欢迎光临    \n\n" if msg == ""
            msg_arr << msg
          end
        end
        message = msg_arr.join("?")
      end
    rescue
    end
    render :text => message
  end

  #此方法无其他用途，仅为更新萧山库存的code
  def generate_b_code
    materials = Material.find_all_by_store_id(100014)
    materials.each do |m|
      code = Time.now.strftime("%Y%m%d%H%M%L")[1..-1]
      sleep 5
      code[0] = ''
      code[0] = ''
      m.code = code
      m.generate_barcode_img
    end if materials.any?
    render :text => "success"
  end




end