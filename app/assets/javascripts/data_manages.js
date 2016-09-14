// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

function show_category(store_id,c_id,c_types){
    var is_pcard = arguments[3] ? arguments[3] : 0; //判定是否为套餐卡
    var url = "/stores/"+store_id+"/data_manages/ajax_prod_serv"
    var data = {
        category_id : c_id,
        c_types : c_types,
        first_time:$("#c_first").val(),
        last_time : $("#c_last").val(),
        is_pcard : is_pcard
    }
    request_ajax(url,data,"post")
}


function search_data(store_id){
    var url = "/stores/"+store_id+"/data_manages/";
    var data = {
        first_time:$("#c_first").val(),
        last_time : $("#c_last").val()
    };
    request_ajax(url,data)
}
