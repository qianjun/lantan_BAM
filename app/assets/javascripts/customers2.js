
function select_property(obj){
    if($(obj).val()==1){
        var len = $("#group_name").parents("div .item").find("font").length;
        if(len<=0){
            $("#group_name").parents("div .item").find("label").prepend("<font class='red'>*</font>");
        }
        $("#group_name").removeAttr("disabled");
    }else{
        $("#group_name").parents("div .item").find("font").remove();
        $("#group_name").attr("disabled", true);
    }
}

function a_debts(obj){
    if($(obj).val()==0){
        $("#debts_money").parents("div .item").find("font").remove();
        $("#debts_money").attr("disabled", true);
        $("#check_time_month").attr("disabled", true);
        $("#check_time_week").attr("disabled", true);
        $("input[name='check_type']").attr("disabled", true);
    }else{
        var len = $("#debts_money").parents("div .item").find("font").length;
        if(len<=0){
            $("#debts_money").parents("div .item").find("label").prepend("<font class='red'>*</font>");
        }
        $("#debts_money").removeAttr("disabled");
        $("input[name='check_type']").removeAttr("disabled");
        if($("input[name='check_type']:checked").val()==0){
            $("#check_time_month").removeAttr("disabled");
        }else{
            $("#check_time_week").removeAttr("disabled");
        }
    }
}

function select_check_type(obj){
    if($(obj).val()==0){
        $("#check_time_month").removeAttr("disabled");
        $("#check_time_week").attr("disabled", true);
    }
    else{
        $("#check_time_week").removeAttr("disabled");
        $("#check_time_month").attr("disabled", true);
    }
}

function add_new_cars(){
    var pattern = new RegExp("[`~@#$^&*()=:;,\\[\\].<>?~！@#￥……&*（）——|{}。，、？-]");
    var buy_year = $("#buy_year").find("option:selected").text();
    var brand = $("#car_brands").find("option:selected").text();
    var model = $("#car_models").find("option:selected").text();
    var model_id = $("#car_models").val();
    var car_num = $.trim($("#new_car_num").val());
    var flag = true;
    if($("#car_brands").val()=="" || $("#car_models").val()==""){
        tishi_alert("请选择品牌或车型!");
        return false;
    }else if(car_num==""){
        tishi_alert("请输入车牌号码!");
        return false;
    }else if(pattern.test(car_num) || car_num.length != 7){
        tishi_alert("车牌号码格式不正确!");
        return false;
    }else{
        $("#selected_cars_div ul").find("span").each(function(){
            if($(this).text()==car_num){
                tishi_alert("已有同名的车牌!");
                flag = false;
                return false;
            }
        })
    }
    if(flag){
        $("#selected_cars_div ul").append("<li>购买年份："+buy_year+"&nbsp;车牌号码：<span>"+car_num+"</span>\n\
             &nbsp;品牌："+brand+"-"+model+"<input type='hidden' value='"+car_num+"-"+model_id+"-"+buy_year+"' name='selected_cars[]'/>\n\
             <a href='javascript:void(0)' class='remove_a' onclick='remove_selected_cars(this)'>删除</a></li>");
    }
}

function remove_selected_cars(obj){
    $(obj).parents("li").remove();
}

function edit_select_property(obj){
    if($(obj).val()==1){
        var len = $("#edit_group_name").parents("div .item").find("font").length;
        if(len<=0){
            $("#edit_group_name").parents("div .item").find("label").prepend("<font class='red'>*</font>");
        }
        $("#edit_group_name").removeAttr("disabled");
    }else{
        $("#edit_group_name").parents("div .item").find("font").remove();
        $("#edit_group_name").attr("disabled", true);
    }
}

function edit_a_debts(obj){
    if($(obj).val()==0){
        $("#edit_debts_money").parents("div .item").find("font").remove();
        $("#edit_debts_money").attr("disabled", true);
        $("#edit_check_time_month").attr("disabled", true);
        $("#edit_check_time_week").attr("disabled", true);
        $("input[name='edit_check_type']").attr("disabled", true);
    }else{
        var len = $("#edit_debts_money").parents("div .item").find("font").length;
        if(len<=0){
            $("#edit_debts_money").parents("div .item").find("label").prepend("<font class='red'>*</font>");
        }
        $("#edit_debts_money").removeAttr("disabled");
        $("input[name='edit_check_type']").removeAttr("disabled");
        if($("input[name='edit_check_type']:checked").val()==0){
            $("#edit_check_time_month").removeAttr("disabled");
        }else{
            $("#edit_check_time_week").removeAttr("disabled");
        }
    }
}

function edit_check_customer() {
    if ($.trim($("#new_name").val()) == "") {
        tishi_alert("请输入客户姓名");
        return false;
    }
    if($("input[name='edit_property']:checked").val()==1 && $.trim($("#edit_group_name").val())==""){
        tishi_alert("请输入单位名称!");
        return false;
    }
    if($("input[name='edit_allowed_debts']:checked").val()==1 && $.trim($("#edit_debts_money").val())==""){
        tishi_alert("请输入挂账额度!");
        return false;
    }
    if($("input[name='edit_allowed_debts']:checked").val()==1 && (isNaN($.trim($("#edit_debts_money").val())) || parseInt($.trim($("#edit_debts_money").val()))<=0)){
        tishi_alert("请输入正确的挂账额度!");
        return false;
    }
    if ($.trim($("#mobilephone").val()) == "" || $.trim($("#mobilephone").val()).length < 6 || $.trim($("#mobilephone").val()).length > 20) {
        tishi_alert("请输入客户手机号码，且号码长度大于6，小于20");
        return false;
    }
    if ($("#new_c_form").length > 0) {
        $("#new_c_form button").attr("disabled", "true");
    }
    return true;
}

function edit_select_check_type(obj){
    if($(obj).val()==0){
        $("#edit_check_time_month").removeAttr("disabled");
        $("#edit_check_time_week").attr("disabled", true);
    }else{
        $("#edit_check_time_week").removeAttr("disabled");
        $("#edit_check_time_month").attr("disabled", true);
    }
}

function add_cars(){
    popup("#add_car_div");
}



function add_car_valid(obj){
    if($.trim($("#add_car_num").val())=="" || $.trim($("#add_car_num").val()).length != 7){
        tishi_alert("请输入车牌号码!");
    }else if($("#add_car_brands").val()=="" || $("#add_car_models").val()==""){
        tishi_alert("请选择车型!");
    }else if($.trim($("#add_car_distance").val())!="" && (isNaN($.trim($("#add_car_distance").val())) || parseInt($.trim($("#add_car_distance").val()))<=0)  ){
        tishi_alert("请输入正确的行驶里程!");
    }else{
        $(obj).parents("form").submit();
        $(obj).attr("disabled", "disabled");
    }
}

function change_pcard_pwd(csrid, p_name){
    popup("#change_pcard_pwd_div");
    $("#change_pcard_pwd_name").text(p_name);
    $("#change_pcard_pwd_name").append("<input type='hidden' name='change_pcard_pwd_cprid' value='"+csrid+"'/>");
}

function change_pcard_pwd_get_valid_code(){
    var csrid = $("input[name='change_pcard_pwd_cprid']").val();
    if ($.trim(csrid)=="" || parseInt(csrid)==0){
        tishi_alert("数据错误!");
    }else{
        $.ajax({
            url: "/api/change/send_code",
            type: "post",
            dataType: "json",
            data: {
                cid : csrid
            },
            success: function(data){
                tishi_alert(data.msg);
            },
            error: function(data){
                tishi_alert("数据错误!");
            }
        })
    }
}

function change_pcard_pwd_commit(){
    var t =/^\+?[0-9][0-9]{5,5}$/
    var csrid = $("input[name='change_pcard_pwd_cprid']").val();
    var vcode = $.trim($("#change_pcard_pwd_valid_code").val());
    var npwd = $.trim($("#change_pcard_pwd_new_pwd").val());
    var rpwd = $.trim($("#change_pcard_pwd_repeat_pwd").val());
    if(csrid=="" || parseInt(csrid)==0){
        tishi_alert("数据错误!");
    }else if(vcode==""){
        tishi_alert("请输入验证码!");
    }else if(npwd==""){
        tishi_alert("请输入新密码!");
    }else if(t.test(npwd)==false){
        tishi_alert("密码长度必须为6位,且必须为0~9的整数!");
    }
    else if(rpwd==""){
        tishi_alert("请输入确认密码!");
    }else if(t.test(rpwd)==false){
        tishi_alert("密码长度必须为6位,且必须为0~9的整数!");
    }else if(npwd != rpwd){
        tishi_alert("两次密码输入不一致!");
    }else{
        $.ajax({
            url: "/api/change/change_pwd",
            type: "post",
            dataType: "json",
            data: {
                cid : csrid,
                verify_code : vcode,
                n_password : npwd
            },
            success: function(data){
                if(data.msg_type==0){
                    tishi_alert(data.msg);
                    $("#change_pcard_pwd_valid_code").val("");
                    $("#change_pcard_pwd_new_pwd").val("");
                    $("#change_pcard_pwd_repeat_pwd").val("");
                    $("#change_pcard_pwd_div").hide();
                    $(".mask").hide();
                }else{
                    tishi_alert(data.msg);
                }
            },
            error : function(data){
                tishi_alert("数据错误!");
            }
        })
    }
}

function change_pcard_pwd_close(){
    $("#change_pcard_pwd_valid_code").val("");
    $("#change_pcard_pwd_new_pwd").val("");
    $("#change_pcard_pwd_repeat_pwd").val("");
}

//function set_repeat_msg(time,t){
//    var time = time;
//    var local_timer=setInterval(function(){
//        if(time > 0){
//            $(t).text("*"+time+"秒后可重新获取验证码!");
//        }else{
//            $(t).text("");
//            window.clearInterval(local_timer);
//        };
//        time -= 1;
//    },1000);
//}