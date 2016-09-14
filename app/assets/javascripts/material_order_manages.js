// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
function search_mat_in_or_out(store_id,obj) {
    var start_date = $.trim($(obj).parents(".search").find("#start_date").val());
    var end_date = $.trim($(obj).parents(".search").find("#end_date").val());
    var mat_types = $.trim($(obj).parents(".search").find("#mat_types").val());
    var mat_in_or_out = $.trim($(obj).parents(".search").find("#mat_in_or_out").val());

    if(mat_in_or_out=="")
        tishi_alert("请选择入/出库类型!");
    else{
        var url = "/stores/"+store_id+"/material_order_manages/search_mat_in_or_out";
        var data = {
            start_date : start_date,
            end_date : end_date,
            mat_types : mat_types,
            store_id : store_id,
            mat_in_or_out : mat_in_or_out
        }
        request_ajax(url,data)
    }
}

function search_unsalable_materials(store_id,obj) {
    var start_date = $.trim($(obj).parents(".search").find("#start_date").val());
    var end_date = $.trim($(obj).parents(".search").find("#end_date").val());
    var mat_types = $.trim($(obj).parents(".search").find("#mat_types").val());
    var sale_num = $.trim($(obj).parents(".search").find("#sale_num").val());
    var url = "/stores/"+store_id+"/material_order_manages/search_unsalable_materials";
    var data = {
        start_date : start_date,
        end_date : end_date,
        mat_types : mat_types,
        store_id : store_id,
        sale_num : sale_num
    }
    request_ajax(url,data)
}

function t_search(url){
    var types = $('#types option:selected').val();
    var c_time = $('#c_time').val();
    var e_time = $("#e_time").val();
    if (c_time != "" && c_time.length !=0 && e_time != "" && e_time.length !=0){
        if (c_time > e_time){
            tishi_alert("开始日期必须小于结束日期");
            return false;
        }
    }
    window.location.href = url +"?c_time="+c_time+"&e_time="+e_time+"&return_types="+types;
}