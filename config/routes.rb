LantanBAM::Application.routes.draw do

  resources :syncs do
    get "upload_file"
    collection do
      post "upload_image"
    end
  end

  resources :stations do
    collection do
      post "handle_order"
    end
  end
  resources :work_records do
    collection do
      post "adjust_types"
    end
  end
  resources :messages do
    collection do
      get "wechat_msg"
    end
  end
  resources :package_cards do
    collection do
      post "on_weixin"
    end
  end

  # The priority is based upon order of creation:
  # first created -> highest priority.
  root :to => 'logins#index'
  resources :logins do
    collection do
      get "logout", "send_validate_code","phone_login","manage_content"
      post "forgot_password","login_phone"
    end
  end
  match "logout" => "logins#logout"
  match "phone_login" => "logins#phone_login"
  match "manage_content" => "logins#manage_content"
  resources :stores do

    resources :micro_stores do
      collection do
        get :upload_content
        post :create_know
      end
      member do
        post :edit_know
      end
    end

    resources :check_materials do
      collection do
        get :check_record,:submit_check,:file_list
        post :batch_check,:submit_check,:submit_xls
      end
    end
    resources :adverts do
    end
    resources :finance_reports do
      collection do
        get "fee_manage","revenue_report","fee_report","pay_account","payable_account","manage_account"
        post "fee_manage","show_fee","fee_report","load_account","pay_account","manage_account"
        post "payable_account","revenue_report","cost_price","analysis_price","create_assets","manage_assets","show_asset"
        post "update_asset","other_fee","load_prod","return_order"
        get "cost_price","analysis_price","manage_assets","other_fee","complete_account","return_order","print_report"
        delete "destroy"
      end
    end
    resources :data_manages do
      collection do
        post "ajax_prod_serv"
      end
    end
    #resources :depots
    resources :market_manages do
      collection do
        get "makets_totals","makets_list","makets_reports","makets_views","makets_goal",
          "sale_orders","sale_order_list","stored_card_record","daily_consumption_receipt",
          "stored_card_bill", "daily_consumption_receipt_blank", "stored_card_bill_blank","gross_profit"
        post "search_month","search_report","search_sale_order","search_gross_profit"
        get "load_service","load_product","load_pcard","load_goal","load_over"
      end
    end
    resources :complaints do
      collection do
        post "consumer_search"
        get "consumer_list", "con_list", "meta_analysis","cost_price","satisfy_degree"
      end
      member do
        get "complaint_detail"
      end
    end
    resources :stations do
      collection do
        get "show_detail","show_video","see_video","search_video", "simple_station","set_tech"
        post "search","collect_info"
      end
    end
    resources :sales do
      collection do
        post "load_types",:delete_sale,:public_sale
      end
      member do
        post "update_sale"
      end
    end
    resources :package_cards do
      collection do
        post "pcard_types","add_pcard","search","delete_pcard"
        get "sale_records","search_list"
      end
      member do
        post "edit_pcard","update_pcard","request_material"
      end
    end
    resources :products do
      collection do
        post "edit_prod","add_prod","add_serv","serv_create","load_material","update_status","add_package","pack_create","destroy_prod"
        get "prod_services","package_service"
      end
      member do
        post "edit_prod","update_prod","serv_update","edit_serv","show_prod","show_serv","serve_delete","prod_delete","commonly_used",
          "edit_pack","pack_update"
      end
    end
    resources :materials do
      collection do
        get "out","search","order","page_materials","search_head_orders","search_supplier_orders","alipay",
          "print","cuihuo","cancel_order","page_outs","page_ins","page_back_records","page_head_orders","page_supplier_orders",
          "search_supplier_orders","pay_order","update_notices","material_order_pay","set_ignore","print_out",
          "cancel_ignore","search_materials","page_materials_losses","set_material_low_count_commit","print_code",
          "mat_loss_delete","mat_loss","back_good","back_good_search","back_good_commit", "reflesh_low_materials","print_mat"
        post "out_order","material_order","add","alipay_complete","mat_in","batch_check","set_material_low_commit","output_barcode",
          "mat_loss_add","modify_code","check_nums"
      end
      member do
        get "mat_order_detail","get_remark" ,"receive_order","tuihuo","set_material_low_count"
        post "remark"
      end
    end

    resources :staffs do
      collection do
        post "search"
      end
      member do
        post "load_work"
      end
    end
    resources :work_records
    resources :violation_rewards do
      collection do
        post "operate_voilate"
      end
    end
    resources :trains
    resources :month_scores do
      collection do
        get "update_sys_score"
      end
    end
    resources :salaries
    resources :current_month_salaries
    resources :material_order_manages do
      collection do
        get "flow_analysis", "storage_analysis"
      end
    end
    resources :staff_manages do
      collection do
        get "get_year_staff_hart"
        get "average_score_hart"
        get "average_cost_detail_summary"
      end
    end

    resources :suppliers do
      member do
        post "change"
      end
      collection do
        get "page_suppliers"
        post "check"
      end
    end
    resources :welcomes do
      collection do
        post "edit_store_name", "update_staff_password"
        post "info_detail"
      end
    end
    resources :customers do
      collection do
        post  "customer_mark", "single_send_message", "add_car"
        get "search", "add_car_get_datas","select_order"
      end
      member do
        get "order_prods", "revisits", "complaints", "sav_card_records", "pc_card_records"
      end
    end
    resources :revisits do
      collection do
        post "search", "process_complaint","send_mess"
        get "search_list"
      end
    end
    resources :messages do
      collection do
        post "search","set_message","alipay_compete"
        get "search_list","send_list","send_detailed","send_alipay","alipay_charge"
      end
      member do
        get "load_message"
      end
    end

    resources :roles do
      collection do
        get "staff"
        post "set_role","reset_role"
      end
    end

    resources :set_functions do
      collection do
        get "market_new", "market_new_commit", "market_edit", "market_edit_commit", "storage_new", "storage_new_commit",
          "storage_edit", "storage_edit_commit", "depart_new", "depart_new_commit", "sibling_depart_new",
          "sibling_depart_new_commit","depart_edit", "depart_edit_commit", "depart_del", "position_new",
          "position_new_commit", "position_edit_commit", "position_del_commit"
      end
    end

    resources :set_stores do
      collection do
        get "select_cities","cash_register","complete_pay","print_paper","single_print","plus_items","three_line_print"
        post "load_order","pay_order","edit_svcard","search_item","search_info","submit_item","edit_deduct"
        post "post_deduct","search_num"
      end
    end
    resources :station_datas do
      collection do
        post "create"
      end
    end
    resources :discount_cards do
      collection do
        get  "add_products_search", "edit", "edit_dcard_add_products", "edit_add_products_search"
        post "del_all_dcards"
      end
    end
    resources :save_cards do
      collection do
        post "del_all_scards"
      end
    end
    resources :materials_in_outs

    resources :work_orders do
      collection do
        get "work_orders_status"
      end
    end
  end

  match 'stores/:store_id/manage_content' => 'logins#manage_content'
  match 'stores/:store_id/materials_in' => 'materials_in_outs#materials_in'
  match 'stores/:store_id/materials_out' => 'materials_in_outs#materials_out'
  match 'get_material' => 'materials_in_outs#get_material'
  match 'stores/:store_id/create_materials_in' => 'materials_in_outs#create_materials_in'
  match 'create_materials_out' => 'materials_in_outs#create_materials_out'
  match 'save_cookies' => 'materials_in_outs#save_cookies'
  match 'stores/:store_id/materials/:mo_id/get_mo_remark' => 'materials#get_mo_remark'
  match 'stores/:store_id/materials/:mo_id/order_remark' => 'materials#order_remark'
  match 'stores/:store_id/uniq_mat_code' => 'materials#uniq_mat_code'
  match '/upload_code_matin' => 'materials_in_outs#upload_code_matin'
  match '/upload_code_matout' => 'materials_in_outs#upload_code_matout'
  match '/upload_checknum' => 'materials#upload_checknum'
  match 'stores/:store_id/materials_losses/add' => 'materials_losses#add'
  match 'stores/:store_id/materials_losses/delete' => 'materials_losses#delete'
  match 'stores/:store_id/materials_losses/view' => 'materials_losses#view'
  match 'materials/search_by_code' => 'materials#search_by_code'

  #match 'stores/:store_id/depots' => 'depots#index'
  #match 'stores/:store_id/depots/create' => 'depots#create'
  match 'stores/:store_id/depots' => 'depots#index'
  match 'stores/:store_id/check_mat_num' => 'materials#check_mat_num'
  resources :customers do
    collection do
      post "get_car_brands", "get_car_models", "check_car_num", "check_e_car_num","return_order","operate_order"
      get "show_revisit_detail","print_orders"
    end
    member do
      post "edit_car_num"
      get "delete_car_num"
      
    end
  end

  resources :orders do
    member do
      get "order_info", "order_staff"
    end
  end

  resources :materials do
    member do
      get "check"
    end
    collection do
      get "get_act_count", "out"
    end
  end
  
  resources :work_orders do
    collection do
      post "login"
    end
  end

  namespace :api do
    resources :orders do
      collection do
        post "login","add","pay","complaint","search_car","send_code","index_list","brands_products","finish",
          "confirm_reservation","refresh","pay_order","checkin", "show_car", "sync_orders_and_customer","get_user_svcard",
          "use_svcard","work_order_finished","login_and_return_construction_order","check_num","out_materials",
          "get_construction_order","search_by_car_num2","materials_verification","get_lastest_materails","stop_construction",
          "search_material"
      end
    end
    resources :syncs_datas do
      collection do
        post :syncs_db_to_all, :syncs_pics
      end
      member do
        get :return_sync_all_to_db
      end
    end
    resources :logins do
      collection do
        post :check_staff,:staff_login,:staff_checkin,:upload_img,:recgnite_pic
        get :download_staff_infos
      end
    end
    resources :licenses_plates do
      collection do
        post :upload_file
        get :send_file
      end
    end

    #新的app
    resources :new_app_orders do
      collection do
        post :customer_pcards, :package_make_order, :pcard_make_order_commit, :pcard_order_info
        post :make_order2, :complaint, :quickly_make_order, :pay_order_no_auth
        post :update_customer,:make_order,:update_tech
        post :search, :sync_orders_and_customer,:get_customer_info
        post :new_index_list, :order_infom,:work_order_finished,:order_info, :pay_order, :cancel_order
      end
    end

    resources :change do
      collection do
        get :sv_records
        post :update_customer,:change_pwd,:send_code,:use_svcard,:change_to_order,:cancel_reserv,:get_quickly_service
        post :load_reserv,:change_status, :change_station
      end
    end
  end
  resources :return_backs do
    collection do
      get :return_info, :return_msg, :generate_b_code
    end
  end



end
