#encoding: utf-8
namespace :customer_types do
  desc "auto generate customer types"
  task(:auto_generate_customer_types => :environment) do
    Customer.auto_generate_customer_type
  end

end