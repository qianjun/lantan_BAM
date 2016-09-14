#encoding: utf-8
module MessagesHelper


  def working_orders (store_id)
    orders = Order.working_orders store_id.to_i
    orders = combin_orders(orders)
    orders = new_app_order_by_status(orders)
    orders
  end


end
