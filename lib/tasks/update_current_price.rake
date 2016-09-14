#encoding: utf-8
desc "update all the current_price for sale_goal_type"
namespace :daily do
  task(:update_current_price => :environment) do
    Store.all.each {|store|
      prices = GoalSale.update_curr_price(store.id)
      GoalSale.where("store_id=#{store.id} and date_format(ended_at,'%Y-%m-%d') >= date_format(now(),'%Y-%m-%d') and
      date_format(started_at,'%Y-%m-%d') <= date_format(now(),'%Y-%m-%d')" ).each do |sale|
        sale.goal_sale_types.each{|type|type.update_attributes(
            :current_price=>type.current_price+(prices[type.types].nil? ? 0 : prices[type.types])
          )}
      end
    }
  end
end