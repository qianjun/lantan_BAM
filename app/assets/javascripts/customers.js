function check_customer() {
    if ($.trim($("#new_name").val()) == "") {
        tishi_alert("请输入客户姓名");
        return false;
    }
    if($("input[name='property']:checked").val()==1 && $.trim($("#group_name").val())==""){
        tishi_alert("请输入单位名称!");
        return false;
    }
    if($("input[name='allowed_debts']:checked").val()==1 && $.trim($("#debts_money").val())==""){
        tishi_alert("请输入挂账额度!");
        return false;
    }
    if($("input[name='allowed_debts']:checked").val()==1 && (isNaN($.trim($("#debts_money").val())) || parseInt($.trim($("#debts_money").val()))<=0)){
        tishi_alert("请输入正确的挂账额度!");
        return false;
    }
    if ($.trim($("#mobilephone").val()) == "" || $.trim($("#mobilephone").val()).length < 6 || $.trim($("#mobilephone").val()).length > 20) {
        tishi_alert("请输入客户手机号码，且号码长度大于6，小于20");
        return false;
    }
    var len = $("#selected_cars_div ul").find("li").length;
    if(len<=0){
        var flag = confirm("您没有为该客户关联任何车辆，点击'是'将继续创建");
        if(flag){
            if ($("#new_c_form").length > 0) {
                $("#new_c_form button").attr("disabled", "true");
            }
            return true;
        }else{
            return false;
        }
    }
    else{
        if ($("#new_c_form").length > 0) {
            $("#new_c_form button").attr("disabled", "true");
        }
        return true;
    }
}

function customer_mark(customer_id) {
    popup("#mark_div");
    $("#c_customer_id").val(customer_id);
    $("#mark").val($("#mark_" + customer_id).html());
}

function single_send_message(customer_id) {
    $("#s_s_message_form")[0].reset();
    popup("#message_div");
    $("#m_customer_id").val(customer_id);
}

function check_single_send() {
    if ($.trim($("#content").val()) == "") {
        tishi_alert("请您填写需要发送的内容。");
        return false;
    }
    return true;
}

//弹出层关闭
$(function(){
    $(".message .x").click(function(){
        $(this).parent().hide();
    });
})




function choose_brand(capital_div, car_brands, car_models) {
    if ($.trim($(capital_div).val()) != "") {
        $.ajax({
            async:true,
            dataType:'json',
            data:{
                capital_id : $(capital_div).val()
            },
            url:"/customers/get_car_brands",
            type:'post',
            success : function(data) {
                if (data != null && data != undefined) {
                    $(car_brands +" option").remove();
                    $(car_brands).append("<option value=''>--</option>");
                    $(car_models +" option").remove();
                    $(car_models).append("<option value=''>--</option>");
                    for (var i=0; i<data.length; i++) {
                        $(car_brands).append("<option value='"+ data[i].id + "'>"+ data[i].name + "</option>");
                    }
                }
            }
        })
    }   
}

function choose_model(car_brands, car_models) {
    if ($.trim($(car_brands).val()) != "") {
        $.ajax({
            async:true,
            dataType:'json',
            data:{
                brand_id : $(car_brands).val()
            },
            url:"/customers/get_car_models",
            type:'post',
            success : function(data) {
                if (data != null && data != undefined) {
                    $(car_models + " option").remove();
                    $(car_models).append("<option value=''>--</option>");
                    for (var i=0; i<data.length; i++) {
                        $(car_models).append("<option value='"+ data[i].id + "'>"+ data[i].name + "</option>");
                    }
                }
            }
        })
    }
}

function check_car_num() {
    if ($.trim($("#new_car_num").val()) != "" && $.trim($("#new_car_num").val()).length == 7) {
        $.ajax({
            async:true,
            dataType:'json',
            data:{
                car_num : $("#new_car_num").val()
            },
            url:"/customers/check_car_num",
            type:'post',
            success : function(data) {
                if (data.is_has == false) {
                    tishi_alert("您输入的车牌号码系统中已经存在，点击‘确定’，当前车牌号将修改到当前客户名下。");
                }                
            }
        })
        return false;
    }
}

function check_e_car_num(c_num_id) {
    if ($.trim($("#car_num_" + c_num_id).val()) != "" && $.trim($("#car_num_" + c_num_id).val()).length ==7 ) {
        $.ajax({
            async:true,
            dataType:'json',
            data:{
                car_num : $("#car_num_" + c_num_id).val(),
                car_num_id : c_num_id
            },
            url:"/customers/check_e_car_num",
            type:'post',
            success : function(data) {
                if (data.is_has == false) {
                    tishi_alert("您输入的车牌号码系统中已经存在，点击‘确定’，当前车牌号将修改到当前客户名下。");
                }
            }
        })
        return false;
    }
}

function customer_revisit(order_id, customer_id) {
    $("#r_v_form")[0].reset();
    $("#r_v_form button").removeAttr("disabled");
    popup("#customer_revisit_div");
    $("#rev_order_id").val(order_id);
    $("#rev_customer_id").val(customer_id);
}

function check_revisit() {
    if ($.trim($("#rev_title").val()) == "") {
        tishi_alert("请输入回访的标题");
        return false;
    }
    if ($("#rev_types").val() == "") {
        tishi_alert("请选择回访类型");
        return false;
    }
    if ($.trim($("#rev_content").val()) == "") {
        tishi_alert("请输入回访内容");
        return false;
    }
    if ($.trim($("#rev_answer").val()) == "") {
        tishi_alert("请输入客户留言");
        return false;
    }
    $("#r_v_form button").attr("disabled", "true");
    return true;
}

function check_process() {
    if ($("#prod_type").val() == "") {
        tishi_alert("请选择投诉类型");
        return false;
    }
    if ($.trim($("#pro_remark").val()) == "") {
        tishi_alert("请您填写处理结果");
        return false;
    }
    return true;
}

function edit_car_num(car_num_id) {
    if ($.trim($("#buy_year_" + car_num_id).val()) == "") {
        tishi_alert("请输入汽车购买年份");
        return false;
    }
    if ($.trim($("#car_num_" + car_num_id).val()) == "" || $.trim($("#car_num_" + car_num_id).val()).length != 7) {
        tishi_alert("请输入车牌号码");
        return false;
    }
    if ($("#car_models_" + car_num_id).val() == "") {
        tishi_alert("请选择汽车品牌型号");
        return false;
    }
    if($.trim($("#car_distance_"+car_num_id).val())!="" && (isNaN($.trim($("#car_distance_"+car_num_id).val())) || parseInt($.trim($("#car_distance_"+car_num_id).val()))<0)){
        tishi_alert("请输入正确的行驶里程");
        return false;
    }
    return true;
}


function is_has_trains(complaint_id, obj) {
    $("#is_trains_" + complaint_id).attr("value", "1");
    if (check_process()) {
        obj.submit();
    }    
}

function show_new_customer() {
    $("#new_c_form button").removeAttr("disabled");
    $("#new_c_form")[0].reset();
    popup("#new_cus_div");
}

function edit_customer() {
    $("#edit_c_form")[0].reset();
    popup('#edit_cus_div');
}

function edit_car_num_f(item_id) {
    $("#d_c_n_f_" + item_id)[0].reset();
    popup("#edit_car_num_" + item_id);
}

$(document).ready(function(){
    //处理违规
    $(".process_violation").live("click", function(){
        var store_id = $(this).attr("name");
        var id = $(this).attr("id");

        var url = "/stores/"+ store_id+"/violation_rewards/"+ id +"/edit";
        var data = {
            id : id,
            store_id : store_id
        }
        request_ajax(url,data)
    });
})

function show_revisit_detail(revisit_id,store_id){   //显示投诉详情
    var url = "/customers/show_revisit_detail";
    var data = {
        r_id : revisit_id,
        store_id : store_id
    }
    request_ajax(url,data)
}

function print_orders(store_id){
    var checked_ids = $("input[id^='line']:checked");
    var ids = [];
    for(var i=0; i < checked_ids.length; i++){
        ids.push(checked_ids[i].value)
    }
    if (checked_ids.length == 0){
        tishi_alert("请选择打印数据");
    }else{
        $(":checked").attr("checked",false);
        window.open("/customers/print_orders?ids="+ids.join(","),"_blank")
    }
    
}

function search_customer(store_id){
    var url = "/stores/"+store_id+"/customers/";
    var data = {
        name : $("#name").val(),
        car_num : $("#car_num").val(),
        phone : $("#phone").val(),
        started_at : $("#started_at").val(),
        ended_at : $("#ended_at").val()
    }
    $(".search_btn,#submit_spinner").toggle();
    request_ajax(url,data)
}

function select_order(store_id,car_num_id,customer_id){
    var url = "/stores/"+store_id+"/customers/select_order";
    var data = {
        car_num_id : car_num_id,
        customer_id : customer_id
    }
    request_ajax(url,data)
}
