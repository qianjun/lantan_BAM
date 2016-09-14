// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

function search_finance(e,store_id){
    var p_type = [];
    var p_name = [];
    var parm = {};
    var customer_n =$("#customer_n").val()
    var cate_n = $("#cate_n option:selected").val();
    var pay_type = $("#order_types :checked");
    var prod_name = $("#cate_name").val();
    for(var i=0;i < pay_type.length;i++){
        p_type.push(pay_type[i].value);
    }
    if (p_type.length != 0){
        parm["pay_type"]= p_type.join(",");
    }
    if (prod_name != "" && prod_name.length !=0){
        parm["prod_name"]= prod_name;
    }
    if (cate_n != "" && cate_n.length !=0){
        parm["category_id"] = cate_n;
    }
    if (customer_n != "" && customer_n.length != 0){
        parm["customer_name"] = customer_n;
    }
    set_search(e,store_id,null,parm)
}

function g_code(){
    var types = $("#types option:selected").val();
    $("#code").val(fee_code[""+types]+$("#code_date").val());
}

function check_fee(){
    var name=$("#name").val();
    //    var code = $("#code").val();
    var amount =$("#amount").val();
    var share_month = $("#share_month").val();
    if (name == "" || name.length==0){
        tishi_alert("请输入费用名称");
        return false;
    }
    //    if (code == "" || code.length ==0){
    //        tishi_alert("单据编号不能为空");
    //         return false;
    //    }
    if(amount == "" || amount.length==0 || isNaN(parseFloat(amount)) || parseFloat(amount)<=0){
        tishi_alert("请输入支付金额！");
        return false;
    }
    if(share_month == "" || share_month.length ==0 || isNaN(parseInt(share_month)) || parseInt(share_month)<=0){
        tishi_alert("请输入分摊月份！");
        return false;
    }
    $("#new_fee").submit();
}

function fee_manage(e,store_id){
    var position = $(".tab_before .hover").attr("id");
    var parm = {
        position : position
    };
    set_search(e,store_id,"fee_manage",parm)
}

function change_tab(e,k){
    $(e).parent().find("li").removeClass("hover");
    e.className = "hover";
    $(".nothing,.finnace_title").css("display","none");
    $("#content_"+k+",#finnace_title_"+k).css("display","block")
}

function show_fee(fee_id,store_id){
    var url = "/stores/"+store_id+"/finance_reports/show_fee";
    var position = $(".tab_before .hover").attr("id");
    var data = {
        store_id:store_id,
        fee_id:fee_id,
        position : position
    }
    request_ajax(url,data,"post")
}

function fee_report(e,store_id){
    var parm = {};
    set_search(e,store_id,"fee_report",parm);
}

function load_account(c_id,s_id,rend){
    var url = "/stores/"+s_id+"/finance_reports/load_account";
    var data = {
        customer_id : c_id,
        rend : rend
    };
    request_ajax(url,data,"post")
}

function set_search(e,store_id,action,parm){
    if (action == null){
        action = "search_finance"
    }
    set_time(e,store_id,action)
    send_account(store_id,action,parm);
}



function send_account(store_id,action,parm){
    var first_time = $("#c_first").val();
    var last_time = $("#c_last").val();
    var url = "/stores/"+store_id+"/finance_reports/";
    var type = "get";
    if (action != "search_finance"){
        url += action;
    }
    if (first_time != "" && first_time.length != 0){
        parm["first_time"] = first_time;
    }else{
        parm["first_time"] = 0;
    }
    if (last_time != "" && last_time.length != 0){
        parm["last_time"] = last_time;
    }else{
        parm["last_time"] = 0;
    }
    request_ajax(url,parm,type)
}


function complete_account(store_id,c_id,rend){
    var total_ids = check_account();
    var due_account = $("#due_account").html();
    var left_account = $("#left_account").html();
    var in_account = $("#in_account").val();
    var pay_type = $("#payment_id option:selected").val();
    var staff_id = $("#staff_id option:selected").val();
    var account = 0;
    var parm = {
        p_ids : total_ids,
        customer_id : c_id,
        rend : rend
    };
    var in_a = false;
    if((in_account != "" || in_account.length!=0)){
        if  (isNaN(parseFloat(in_account)) || parseFloat(in_account)<0){
            tishi_alert("充值金额只能是数字！");
            return false;
        }else{
            if(parseFloat(in_account)>0){
                in_a = true;
                account = in_account;
            }
        }
    }
    if (total_ids.length == 0){
        if(confirm("确认只充值"+ in_account+"元，暂不结账吗？")){
            parm["pay_type"] = pay_type;
            parm["staff_id"] = staff_id;
            parm["pay_recieve"] = account;
            parm["trade_amt"] = -1;
            parm["left_account"] = parseFloat(left_account)+parseFloat(in_account);
            send_account(store_id,"complete_account",parm)
        }
    }else{
        if ((parseFloat(left_account)+parseFloat(in_account)) >= parseFloat(due_account)){
            if(confirm('应付金额：'+due_account+"元，余额："+left_account+(in_a ? "元，充值金额："+in_account : "")+"元,确认付款吗？")){
                parm["pay_type"] = pay_type;
                parm["staff_id"] = staff_id;
                parm["pay_recieve"] = account;
                parm["trade_amt"] = due_account;
                parm["left_account"] = parseFloat(left_account)+parseFloat(in_account)- parseFloat(due_account);
                send_account(store_id,"complete_account",parm)
            }
        }else{
            tishi_alert("金额不足！");
        }
    }
}

function check_account(){
    var t_box = $("#t_account :checkbox");
    var sum = 0;
    var total_ids = [];
    for(var i=0;i <t_box.length;i++){
        if (t_box[i].checked){
            sum  += parseFloat($(t_box[i]).parent().parent().find("td").last().find("span").html());
            total_ids.push(t_box[i].value);
        }
    }
    $("#due_account").html(limit_float(sum));
    return total_ids;
}

function limit_float(num){
    var t_num = parseInt(parseFloat(num)*100);
    return  round((t_num%10 == 0 ? t_num : t_num-5)/100.0,2);
}


function t_account(e){
    $("#t_account :checkbox").attr("checked",e.checked);
    var t_box = $("#t_account :checkbox");
    if (e.checked){
        for(var i=0;i <t_box.length;i++){
            var li = $(t_box[i]).parent().parent().find("td");
            var child = " <li id=\"li_"+t_box[i].value+"\">单号："+li.eq(1).html()+" ￥<span style='color:red'>"+li.last().html()+"</span></li>"
            $("#added_accounts").append(child);
        }
    }else{
        for(var k=0;k <t_box.length;k++){
            $("#li_"+t_box[k].value).remove();
        }
    }
    check_account();
}


function box_check(e){
    if (e.checked){
        var li = $(e).parent().parent().find("td");
        var child = " <li id=\"li_"+e.value+"\"> 单号："+li.eq(1).html()+" ￥<span style='color:red'>"+li.last().html()+"</span></li>"
        $("#added_accounts").append(child);
    }else{
        $("#li_"+e.value).remove();
    }
    check_account();
}

function pay_account(e,store_id){
    var parm = {};
    set_search(e,store_id,"pay_account",parm)
}

function payable_account(e,store_id){
    var parm = {};
    set_search(e,store_id,"payable_account",parm)
}

function revenue_report(e,store_id){
    var parm = {};
    set_search(e,store_id,"revenue_report",parm)
}

function manage_tab(e,types){
    $(e).parent().find("li").removeClass("hover");
    e.className = "hover";
    $("#account div[id*='show_']").css('display','none');
    $("#show_"+types).css('display','block');
}

function manage_account(e,store_id){
    var action = "manage_account";
    var url = "/stores/"+store_id+"/finance_reports/"+action;
    var type= "post";
    var account_name = $("#account_name").val();
    var position = $(".tab_before .hover").attr("id");
    var parm = {
        position : position,
        account_name : account_name
    };
    set_time(e,store_id,action)
    request_ajax(url,parm,type)
}


//设置提交按钮的倒计时
function set_time(e,store_id,action){
    $(e).attr("onclick","");
    var time = 3;
    var local_timer=setInterval(function(){
        e.innerHTML="查&nbsp&nbsp询("+time+")";
        if (time <=0){
            $(e).attr("onclick",action+"(this,"+store_id+")");
            window.clearInterval(local_timer);
            e.innerHTML="查&nbsp&nbsp询";
        }
        time -= 1;
    },1000)
}

function cost_price(e,store_id){
    var action = "cost_price";
    var parm = {};
    var cate_n = $("#cate_n option:selected").val();
    if (cate_n != "" && cate_n.length !=0){
        parm["prod_types"] = cate_n;
    }
    set_time(e,store_id,action)
    send_account(store_id,action,parm)
}

function analysis_price(e,store_id){
    var action = "analysis_price";
    var parm = {};
    var cate_n = $("#cate_n option:selected").val();
    if (cate_n != "" && cate_n.length !=0){
        parm["prod_types"] = cate_n;
    }
    set_time(e,store_id,action)
    send_account(store_id,action,parm)
}

function check_assets(){
    var name=$("#name").val();
    var amount =$("#amount").val();
    var share_month = $("#share_month").val();
    if (name == "" || name.length==0){
        tishi_alert("请输入资产名称");
        return false;
    }
    if(amount == "" || amount.length==0 || isNaN(parseFloat(amount)) || parseFloat(amount)<=0){
        tishi_alert("请输入支付金额！");
        return false;
    }
    if(share_month == "" || share_month.length ==0 || isNaN(parseInt(share_month)) || parseInt(share_month)<=0){
        tishi_alert("请输入分摊月份！");
        return false;
    }
    $("#new_assets").submit();
}

function manage_assets(e,store_id){
    var parm = {};
    set_search(e,store_id,"manage_assets",parm);
}

function show_asset(asset_id,store_id){
    var url = "/stores/"+store_id+"/finance_reports/show_asset";
    var parm = {
        store_id:store_id,
        asset_id:asset_id
    }
    request_ajax(url,parm,"post")
}

function set_over(asset_id,store_id){
    var parm = {
        store_id:store_id,
        asset_id:asset_id
    }
    if(confirm("确认要报废该项资产吗？")){
        send_account(store_id,"update_asset",parm);
    }
}

function destroy_fee(action_record,id,store_id,index){
    var record_name = ["费用","资产"];
    var url = "/stores/"+store_id+"/finance_reports/";
    var parm = {
        store_id:store_id,
        id:id,
        action_record : action_record
    }
    if(confirm("确认删除这项"+record_name[index] +"吗？")){
        destroy(url,parm)
    }
}

function destroy(url,parm){
    $.ajax({
        type:"DELETE",
        url: url,
        dataType: "JSON",
        data: parm,
        success : function(data){
            tishi_alert("删除成功！");
            setTimeout(function(){
                window.location.reload();
            },500);
            
        }
    }
    )

}

function other_fee(e,store_id){
    var parm = {};
    var customer_n =$("#customer_n").val()
    var card_type = $("#card_types option:selected").val();
    if (card_type != "" && card_type.length !=0){
        parm["card_type"] = card_type;
    }
    if (customer_n != "" && customer_n.length != 0){
        parm["customer_name"] = customer_n;
    }
    set_search(e,store_id,"other_fee",parm)
}

function load_prod(){
    var category_id = $("#cate_n option:selected").val();
    if (category_id != "" && category_id.length >0){
        $("#cate_name").attr("disabled",false);
    }else{
        $("#cate_name").val("").attr("disabled",true);
    }
}

function return_order(e,store_id){
    var parm = {};
    var prod_name = $("#cate_name").val();
    var customer_n =$("#customer_n").val()
    var cate_n = $("#cate_n option:selected").val();
    if (customer_n != "" && customer_n.length != 0){
        parm["customer_name"] = customer_n;
    }
    if (prod_name != "" && prod_name.length !=0){
        parm["prod_name"]= prod_name;
    }
    if (cate_n != "" && cate_n.length !=0){
        parm["category_id"] = cate_n;
    }
    set_search(e,store_id,"return_order",parm)
}

function print_report(obj,store_id){
    var c_first = $.trim($(obj).parents(".search").find("#c_first").val());
    var c_last = $.trim($(obj).parents(".search").find("#c_last").val());
    window.open("/stores/"+store_id+"/finance_reports/print_report?c_first="+c_first+"&c_last="+c_last);
}