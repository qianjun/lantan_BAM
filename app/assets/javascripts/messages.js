function select_customers() {
    var checkboxes = $("#search_div input:checked");
    var send_html = "";
    var customer_ids = "";
    if(checkboxes.length==0){
        $(".select_all").attr("checked", false);
    }
    if(checkboxes.length == $("#search_div input").length){
        $(".select_all").attr("checked", "checked");
    }
    for (var i=0; i<checkboxes.length; i++) {
        send_html += "<div id='cus_"+ checkboxes[i].value +"'><em>"+ $("#label_" + checkboxes[i].value).html()
        + "</em><a href='javascript:void(0);' class='remove_a' onclick='delete_cus("+ checkboxes[i].value +")'>删除</a></div>";
        customer_ids == "" ? (customer_ids += checkboxes[i].value) : (customer_ids += "," + checkboxes[i].value);
    }
    $("#customer_ids").val(customer_ids);
    $("#send_div").html(send_html);
}

function delete_cus(customer_id) {
    $("#c_" + customer_id).removeAttr("checked");
    $("#cus_" + customer_id).remove();
    var ids = $("#customer_ids").val();
    if (ids != null && ids != "") {
        var ids_arr = ids.split(",");
        var new_ids = [];
        for (var i=0; i<ids_arr.length; i++) {
            if (ids_arr[i] != ""+customer_id) {
                new_ids.push(ids_arr[i]);
            }
        }
        $("#customer_ids").attr("value", new_ids.join(","));
    }
    if($("#customer_ids").attr("value")==""){
        $(".select_all").attr("checked", false);
    }
}

function check_message() {
    if ($.trim($("#customer_ids").val()) == "") {
        tishi_alert("请选择您要发信息的客户。")
        return false;
    }
    if ($.trim($("#content").val()) == "") {
        tishi_alert("请您填写需要发送的内容。");
        return false;
    }
    $("#send_message").attr("disabled",true);
    return true;
}

function selectAllCustomers(obj){
    if($(obj).attr("checked")=='checked'){
        $(obj).parent().next().find("input[type='checkbox']").attr("checked", "checked");
        select_customers();
    }else{
        $(obj).parent().next().find("input[type='checkbox']").attr("checked", false);
        $("#customer_ids").val("");
        $("#send_div").html("");
    }
}

function send_message(store_id,status){
    var msg = $("#tbody_revist :checkbox");
    var send_ids = [];
    var url = "/stores/"+store_id+"/revisits/send_mess";
    var data = {
        deal_status : status,
        send_ids : send_ids
    }
    for(var i=0;i<msg.length;i++){
        if (msg[i].checked){
            send_ids.push(msg[i].value);
        }
    }
    if (send_ids.length == 0){
        tishi_alert("请选择回访或者提醒信息！");
        return false;
    }else{
        request_ajax(url,data,"post")
    }
    
}