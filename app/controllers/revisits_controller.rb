#encoding: utf-8
class RevisitsController < ApplicationController
  before_filter :sign?
  layout "customer"
  def index
    session[:started_at] = nil
    session[:ended_at] = nil
    session[:is_vip] = nil
    session[:is_visited] = nil
    session[:is_time] = "1"
    session[:time] = nil
    session[:is_price] = "1"
    session[:price] = nil
    @store = Store.find(params[:store_id].to_i)
    @send_msg = SendMessage.joins(:customer).select("send_messages.*,name").where(:store_id=>params[:store_id],:status=>[SendMessage::STATUS[:WAITING],SendMessage::STATUS[:FAIL]]).
      order('types,car_num_id,customer_id')
    @car_nums = CarNum.where(:id=>@send_msg.map(&:car_num_id)).inject({}){|h,c|h[c.id]=c.num;h}
    @customers = Order.get_order_customers(@store.id, (Time.now - 15.days).to_date.to_s, Time.now.to_date.to_s, nil, "1",
      "3", "1", "500", nil, nil, params[:page])
  end

  def search
    session[:started_at] = params[:started_at]
    session[:ended_at] = params[:ended_at]
    session[:is_vip] = params[:is_vip]
    session[:is_visited] = params[:is_visited]
    session[:is_time] = params[:is_time]
    session[:time] = params[:time]
    session[:is_price] = params[:is_price]
    session[:price] = params[:price]
    redirect_to "/stores/#{params[:store_id]}/revisits/search_list"
  end

  def search_list
    @store = Store.find(params[:store_id].to_i)
    @customers = Order.get_order_customers(@store.id, session[:started_at], session[:ended_at], session[:is_visited],
      session[:is_time], session[:time], session[:is_price], session[:price], session[:is_vip], nil, params[:page])
    render "index"
  end

  def create
    flash[:notice] = "创建回访失败，请您重新尝试。"
    if params[:rev_title]
      Revisit.transaction do
        complaint = Complaint.create(:order_id => params[:rev_order_id].to_i, :reason => params[:rev_answer],
          :status => Complaint::STATUS[:UNTREATED], :customer_id => params[:rev_customer_id].to_i,
          :store_id => params[:store_id].to_i) if params[:is_complaint]
        revisit = Revisit.create(:customer_id => params[:rev_customer_id].to_i, :types => params[:rev_types].to_i,
          :title => params[:rev_title], :answer => params[:rev_answer], :content => params[:rev_content],
          :complaint_id => (complaint.nil? ? nil : complaint.id))
        RevisitOrderRelation.create(:order_id => params[:rev_order_id].to_i, :revisit_id => revisit.id)
        order = Order.find(params[:rev_order_id].to_i)
        order.update_attributes(:is_visited => true) unless order.is_visited
      end
      flash[:notice] = "添加回访成功。"
    end
    rev_page = params[:rev_page].empty? ? 1 : params[:rev_page]
    return_url = "/stores/#{params[:store_id]}/customers/#{params[:rev_customer_id].to_i}?rev_page=#{rev_page}"
    redirect_to return_url
  end

  def process_complaint
    flash[:notice] = "处理失败，请您重新尝试。"
    if params[:prod_type] 
      staff_ids = params[:c_staff_id].split(",") unless params[:c_staff_id].nil?
      staff_id_1, staff_id_2 = staff_ids[0], staff_ids[1] if staff_ids
      is_violation = params[:prod_type].to_i < Complaint::TYPES[:INVALID] ? true : false
      status = params[:cfs].to_i == Complaint::STATUS[:PROCESSED] ? true : false
      complaint = Complaint.find(params[:pro_compl_id].to_i)
      complaint.update_attributes(:types => params[:prod_type].to_i, :remark => params[:pro_remark],
        :status => status, :is_violation => is_violation, :process_at => status ? Time.now : nil,
        :staff_id_1 => staff_id_1, :staff_id_2 => staff_id_2, :c_feedback_suggestion => status)
      if is_violation
        vr1 = ViolationReward.find_by_target_id_and_staff_id(complaint.id, staff_id_1)
        vr2 = ViolationReward.find_by_target_id_and_staff_id(complaint.id, staff_id_2)
        w_records = WorkRecord.where(:staff_id=>([staff_id_1]|[staff_id_2]).compact,:current_day=>Time.now.strftime("%Y-%m-%d"))
        w_records.each {|w_record|
          c_num = w_record.complaint_num.nil? ? 0 : w_record.complaint_num
          w_record.update_attributes(:complaint_num=>c_num+1)} unless w_records.blank?
        violation_hash = {:status => ViolationReward::STATUS[:NOMAL],
          :situation => "订单#{params[:pc_code]}产生投诉，#{Complaint::TYPES_NAMES[params[:prod_type].to_i]}",
          :types => ViolationReward::TYPES[:VIOLATION], :target_id => complaint.id}
        ViolationReward.create(violation_hash.merge({:staff_id => staff_id_1})) if staff_id_1 and !vr1
        ViolationReward.create(violation_hash.merge({:staff_id => staff_id_2})) if staff_id_2 and !vr2
      end
      flash[:notice] = "处理投诉成功。"
    end
    if params["is_trains_#{params[:pro_compl_id]}"] == "0"
      return_url = "/stores/#{params[:pc_store_id]}/customers/#{params[:pc_cust_id]}?comp_page=#{params[:comp_page]}"
      redirect_to return_url
    else
      redirect_to "/stores/#{params[:pc_store_id]}/staffs"
    end
  end


  def send_mess
    if params[:deal_status].to_i == SendMessage::STATUS[:FINISHED]
      message_arr,store = [],Store.find(params[:store_id])
      send_messages = SendMessage.where(:id=>params[:send_ids]).group_by{|i| {:c_id=>i.customer_id,:m_id=>i.message_record_id}}
      customers = Customer.find(send_messages.keys.inject([]){|arr,h|arr << h[:c_id]}.compact.uniq).inject({}){|h,c|h[c.id]=c;h}
      m_records,s_messages,this_price,records = {},{},0,[]
      begin
        Order.transaction do  #通过transaction控制发送失败时的状态
          send_messages.each { |k,v|
            strs,customer = [],customers[k[:c_id]]
            if customer
              if k[:m_id].nil?
                v.each_with_index {|str,index|strs << "#{index+1}.#{str.content}" }
                content ="#{customer.name}\t女士/男士,您好,#{store.name}的美容小贴士提醒您:\n" + strs.join("\r\n")
                piece = content.length%70==0 ? content.length/70 : content.length/70+1
                message_record = MessageRecord.create({:store_id =>customer.store_id, :content =>content,:send_at => Time.now,
                    :types=>MessageRecord::M_TYPES[:AUTO_REVIST],:total_num=>piece,:total_fee=>piece*Constant::MSG_PRICE,:status=>SendMessage::STATUS[:FINISHED]})
                this_price += piece*Constant::MSG_PRICE
                records << message_record.id
                v.each {|message|s_messages[message.id]={:message_record_id=>message_record.id,:status=>params[:deal_status]}}
                message_arr << {:content => content.gsub(/([   ])/,"\t"), :msid => "#{customer.id}", :mobile =>customer.mobilephone}
              else
                piece = 0
                v.each do |record|
                  s_messages[record.id]={:status=>params[:deal_status]}
                  content = record.content
                  piece += content.length%70==0 ? content.length/70 : content.length/70+1
                  this_price += piece*Constant::MSG_PRICE
                  message_arr << {:content => content.gsub(/([   ])/,"\t"), :msid => "#{customer.id}", :mobile =>customer.mobilephone}
                end
                m_records[k[:m_id]]={:total_num=>piece,:total_fee=>piece*Constant::MSG_PRICE,:status=>SendMessage::STATUS[:FINISHED]}
              end
            end
          }
          if  (store.message_fee-this_price) > Constant::OWE_PRICE
            send_message_request(message_arr,20)
            SendMessage.update(s_messages.keys,s_messages.values)
            MessageRecord.update(m_records.keys,m_records.values)
            store.warn_store(this_price) #提示门店费用信息
            @msg = "发送成功！"
          else
            MessageRecord.delete_all(:id=>records)
            @msg = "余额不足！"
          end
        end
      rescue
        SendMessage.where(:id=>params[:send_ids]).update_all(:status=>SendMessage::STATUS[:FAIL])
        @msg = "发送失败！"
      end
    else
      SendMessage.where(:id=>params[:send_ids]).update_all(:status=>params[:deal_status])
    end
    @send_msg = SendMessage.where(:store_id=>params[:store_id],:status=>[SendMessage::STATUS[:WAITING],SendMessage::STATUS[:FAIL]]).order('types,car_num_id,customer_id')
    @car_nums = CarNum.find(@send_msg.map(&:car_num_id)).inject({}){|h,c|h[c.id]=c.num;h}
    @s_custs = Customer.find(@send_msg.map(&:customer_id)).inject({}){|h,c|h[c.id]=c.name;h}
  end

  
end
