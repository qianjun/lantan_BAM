//登录默认值
function focusBlur(e){
    $(e).focus(function(){
        var thisVal = $(this).val();
        if(thisVal == this.defaultValue){
            $(this).val('');
        }
    })
    $(e).blur(function(){
        var thisVal = $(this).val();
        if(thisVal == ''){
            $(this).val(this.defaultValue);
        }
    })
}

$(function(){
    focusBlur('.login_box input');//用户信息input默认值
// focusBlur('.item input');//用户信息input默认值
})

//切换
$(function() {
    change_tab_li();
})

function change_tab_li(){
    $('div.tab_head li').bind('click',function(){
        $(this).addClass('hover').siblings().removeClass('hover');
        var index = $('div.tab_head li').index(this);
        $('div.data_body > div').eq(index).show().siblings().hide();
    });
}

//偶数行变色
$(function(){
    odd_even();
});

function odd_even(){
    $(".data_table > tbody > tr:odd").addClass("tbg");
    $(".data_tab_table > tbody > tr:odd").addClass("tbg");
}

//弹出层
function popup(t){
    var scolltop = document.body.scrollTop|document.documentElement.scrollTop; //滚动条高度
    var doc_height = $(document).height(); //页面高度
    var doc_width = $(document).width(); //页面宽度
    //var win_height = document.documentElement.clientHeight;//jQuery(document).height();
    var win_height = window.height; //窗口高度
    var layer_height = $(t).height(); //弹出层高度
    var layer_width = $(t).width(); //弹出层宽度
    $(".mask").css({
        display:'block',
        height: (layer_height+scolltop+100)<doc_height ? doc_height+100 : layer_height+scolltop+100+50
    })
    $(t).css('top',scolltop+100);
    $(t).css('left',(doc_width-layer_width)/2);
    $(t).css('display','block');
  
    $(t+" a.close").live("click",function(){
        $(t).css('display','none');
        $(".mask").css('display','none');
    })
    $(".cancel_btn").live("click",function(){
        $(t).css('display','none');
        $(".mask").css('display','none');
    })
}

//现场施工
$(function(){
    var sitePayHeight = $(".site_pay").height();
    $(".site_pay > h1").css("height",sitePayHeight);

    var siteWorkHeight = $(".site_work").height();
    $(".site_work > h1").css("height",siteWorkHeight);

    var siteInfoHeight = $(".site_info").height();
    $(".site_info > h1").css("height",siteInfoHeight);
});

//向选择框添加产品服务
function add_this(e,name){
    var child="<div id='"+e.value+"'><em>"+name +"</em><input id='prod_price' value='"+ e.id+"' type='hidden' />\n\
   <a href='javascript:void(0)' class='addre_a' onclick=\"add_one(\'"+e.value +"\')\" id='add_one"+e.value +"'>+</a>\n\
   <span><input name='sale_prod["+e.value +"]' \n\
    type='text' class='addre_input' value='1' id='add_p"+e.value +"' /></span><a href='javascript:void(0)' class='addre_a' \n\
    id='delete_one"+e.value+"'>-</a><a href='javascript:void(0)' class='remove_a' \n\
    onclick='$(this).parent().remove();if($(\"#prod_"+ e.value+"\").length!=0){$(\"#prod_"+ e.value+"\")[0].checked=false;}'>删除</a></div>";
    if ($(e)[0].checked){
        if ($("#add_products #"+e.value).length==0){
            $(".popup_body_fieldset #add_products").append(child);
        }else{
            var num=parseInt($("#add_products #add_p"+e.value).val())+1;
            $("#add_products #add_p"+e.value).val(num);
            $("#add_products #delete_one"+e.value).attr("onclick","delete_one('"+ e.value+"')");
        }
    }else{
        $("#add_products #"+e.value).remove();
    }
}


function add_one(id,type){
    var num =0;
    type = arguments[1] ? arguments[1] : 0
    if(type==0){
        num=parseInt($("#add_products #add_p"+id).val())+1;
    }
    if(type == 1){
        num = parseFloat($("#add_products #add_p"+id).val())+1;
    }
    $("#add_products #add_p"+id).val(num);
    if (num>=2)
        $("#add_products #delete_one"+id).attr("onclick","delete_one('"+ id+"',1)");
}

function delete_one(id,type){
    var num =0;
    type = arguments[1] ? arguments[1] : 0
    if(type==0){
        num=parseInt($("#add_products #add_p"+id).val())-1;
    }
    if(type == 1){
        num = parseFloat($("#add_products #add_p"+id).val())-1;
    }
    if (num<=1){
        $("#add_products #delete_one"+id).attr("onclick","");
    }
    $("#add_products #add_p"+id).val(num);
}

function show_center(t){
    var mouse_position = document.body.scrollTop+document.documentElement.scrollTop;
    var doc_height = $(document).height();
    var doc_width = $(document).width();
    var layer_height = $(t).height();
    var layer_width = $(t).width();
    var win_height =  $(window).height();
    $(".mask").css({
        display:'block',
        height:　(layer_height+mouse_position+100)<doc_height ? doc_height+100 : layer_height+mouse_position+100+50
    });
    $(t).css('top',mouse_position+100+"px" );
    $(t).css('left',(doc_width-layer_width)/2);
    $(t).css('display','block');
    $(t + " .close").click(function(){
        $(t).css('display','none');
        $(".mask").css('display','none');
    });
}
//用于在弹出层上面的弹出 层级会比show_center的高
function before_center(t){
    var mouse_position = document.body.scrollTop+document.documentElement.scrollTop;
    var win_height =  $(window).height();
    var doc_height = $(document).height();
    var doc_width = $(document).width();
    var layer_height = $(t).height();
    var layer_width = $(t).width();
    $(t).css('z-index',120);
    $(t).css('top',mouse_position/2+100+"px");
    $(t).css('left',(doc_width-layer_width)/2);
    $(t).css('display','block');
    $(".maskOne").css({
        display:'block',
        height:(layer_height+mouse_position+100)<doc_height ? doc_height+100 : layer_height+mouse_position+100+50
    });
    $(t + " .close").click(function(){
        $(t).css('display','none');
        $(".maskOne").css('display','none');
    });
}


//基础数据权限配置 切换
$(function() {
    $('.groupFunc_h li').bind('click',function(){
        $(this).addClass('hover').siblings().removeClass('hover');
        var index = $('.groupFunc_h li').index(this);
        $('.groupFunc_b > div').eq(index).show().siblings().hide();
    });
});

//排序切换箭头
function sort_change(obj){
    if($(obj).attr("class") == "sort_u"){
        $(obj).attr("class", "sort_d");
    }else if($(obj).attr("class") == "sort_d"){
        $(obj).attr("class", "sort_u");
    }else if($(obj).attr("class") == "sort_u_s"){
        $(obj).attr("class", "sort_d_s");
    }else{
        $(obj).attr("class", "sort_u_s");
    }
}


//提示错误信息
function tishi_alert(message){
    var time = arguments[1] ?  arguments[1] : 3;
    $(".alert_h").html(message+"&nbsp&nbsp&nbsp<span id=time>"+time+"</span>");
    var scolltop = document.body.scrollTop|document.documentElement.scrollTop;
    var win_height = document.documentElement.clientHeight;//jQuery(document).height();
    var z_layer_height = $(".tab_alert").height();
    $(".tab_alert").css('top',(win_height-z_layer_height)/2 + scolltop);
    var doc_width = $(document).width();
    var layer_width = $(".tab_alert").width();
    $(".tab_alert").css('left',(doc_width-layer_width)/2);
    $(".tab_alert").css('display','block');
    jQuery('.tab_alert').fadeTo("slow",1);
    $(".tab_alert .close").click(function(){
        $(".tab_alert").css('display','none');
    })
    setTimeout(function(){
        jQuery('.tab_alert').fadeTo("slow",0);
    }, time*1000);
    setTimeout(function(){
        jQuery(".tab_alert").css('display','none');
    }, time*1000);
    var local_timer=setInterval(function(){
        time -= 1;
        jQuery("#time").html(time);
        if (time <=0){
            jQuery("#time").html("");
            window.clearInterval(local_timer);
        }
    },1000)
}

//center popup div
function center_popup_div(ele){
    var scolltop = document.body.scrollTop|document.documentElement.scrollTop;
    var win_height = document.documentElement.clientHeight;
    var z_layer_height = $(ele).height();
    $(ele).css('top',(win_height-z_layer_height)/2 + scolltop);
}

// 点击取消按钮隐藏层
function hide_mask(t){
    $(t).css('display','none');
    $(".mask").css('display','none');
}

///*获取data_table的宽度*/
//$(function(){
//	var div_w=$(".table_box").width();
//	var table_w =$(".table_box > .data_table").width();
//	$(".table_box_h").css("paddingRight",div_w-table_w)
//})



function round(v,e){
    var t=1;
    for(;e>0;t*=10,e--);
    for(;e<0;t/=10,e++);
    return  Math.round(v*t)/t;
}

function change_dot(x,e)
{
    var f_x = parseFloat(x);
    if (isNaN(f_x))
    {
        alert('function:changeTwoDecimal->parameter error');
        return false;
    }
    var t=1;
    for(;e>0;t*=10,e--);
    for(;e<0;t/=10,e++);
    f_x = Math.round(x*t)/t;
    var s_x = f_x.toString();
    var pos_decimal = s_x.indexOf('.');
    if (pos_decimal < 0)
    {
        pos_decimal = s_x.length;
        s_x += '.';
    }
    while (s_x.length <= pos_decimal + 2)
    {
        s_x += '0';
    }
    return s_x;
}

function set_default_value(e,get_value){
    $(get_value).val(e.value);
}

function set_default_to_pic(e){
    return (e.files[0].size/1024).toFixed(0) > 200;
}

//点击 显示和隐藏提示框
function show_complaint(t) {
    $("#"+t+"_s").show();
    $("#"+t+"_h").hide();
}

function hide_complaint(t) {
    $("#"+t+"_s").hide();
    $("#"+t+"_h").show();
}

//type为1的时候可以输入小数
function add_m(e,type,max_num){
    type = arguments[1] ? arguments[1] : 0;
    max_num = arguments[2] ? arguments[2] : 10000000;
    var num = $.trim($(e).parent().find(":text").val());
    if (type == 0){
        if (isNaN(parseInt(num))){
            num = 0;
        }else{
            num = parseInt(num)
        }
    }
    if(type == 1){
        if (isNaN(parseFloat(num))){
            num = 0;
        }else{
            num = round(parseFloat(num),1);
        }
    }
    if(num <max_num ){
        $(e).parent().find(":text").val(num+1);
    }
    
}

function del_m(e,type,min_num){
    type = arguments[1] ? arguments[1] : 0
    min_num = arguments[2] ? arguments[2] : 0;
    var num = $.trim($(e).parent().find(":text").val());
    if (type == 0){
        if (isNaN(parseInt(num))){
            num = 0;
        }else{
            num = parseInt(num)
        }
    }
    if(type==1){
        if (isNaN(parseFloat(num))){
            num = 0;
        }else{
            num = round(parseFloat(num),1)
        }
    }
    if (num > min_num ){
        if(num >=1){
            $(e).parent().find(":text").val(num-1);
        }else{
            $(e).parent().find(":text").val(num);
        }
    }
}

//根据按钮状态 使输入框是否可用
function toggle_abled(e,symbol){
    $(symbol).attr("disabled",!e.checked).val("");
}

//退单操作
function operate_order(order_id,e){
    var fact_type = $("#fact_type").val();
    var return_fee = $("#return_fee").val();
    var return_num = $("#return_num").val();
    var product_id = $("#product_id").val();
    var max_num = $("#max_num").val();
    var data = {
        fact_type : fact_type,
        return_fee : return_fee,
        return_num : return_num,
        product_id : product_id,
        max_num : max_num
    }
    if (parseInt(fact_type)==2){
        var cash_fee = parseFloat($.trim($("#cash_fee").val()));
        if (isNaN(cash_fee) || round(cash_fee,2) <0 || round(cash_fee,2) > round(return_fee,2) ){
            tishi_alert("退款金额有误！");
            return false;
        }
        data["cash_fee"] = cash_fee;
    }
    if (parseInt(fact_type)==1){
        var cash = parseFloat($.trim($("#cash_fee").val()));
        var sv_fee = parseFloat($.trim($("#sv_fee").val()));
        var return_type1 = $("#return_type1")[0].checked;
        var return_type2 = $("#return_type2")[0].checked;
        if(return_type1){
            if (isNaN(sv_fee) || round(sv_fee,2) <0){
                tishi_alert("退款金额有误！");
                return false;
            }
            data["sv_fee"] = sv_fee;
        }
        if(return_type2){
            if (isNaN(cash) || round(cash,2) <0){
                tishi_alert("退款金额有误！");
                return false;
            }
            data["cash_fee"] = cash;
        }
        if(return_type1 && return_type2 && round(cash+sv_fee,2) > round(return_fee,2) ){
            tishi_alert("退单金额超出！");
            return false;
        }
    }
    if (confirm("确定要退单吗？")){
        var reason = $("#return_reason option:selected").val();
        var direct = $("input[name='direct']:checked").val();
        var item_types = $("#item_types").val();
        data["order_id"] = order_id;
        data["reason"] = reason;
        data["direct"] = direct;
        data["item_types"] = item_types;
        e.disabled = true
        $.ajax({
            async:true,
            dataType: "json",
            type: "post",
            url: "/customers/operate_order",
            data: data,
            success :function(data){
                $("#return_order .close").trigger("click");
                tishi_alert(data.msg);
                setTimeout(function(){
                    window.location.reload();
                },300)
            }
        })
    }
}


//退单功能
function return_order(o_id,c_id){
    var url = "/customers/return_order";
    var data = {
        o_id : o_id,
        c_id : c_id
    }
    request_ajax(url,data,"post")
}

//开启关闭短信功能
function set_message(m_index,m_status,e,store_id){
    var m_fun = $(e).parent().parent().find("#a_role").html();
    var action_name = "开启";
    if (m_status == 0){
        $(e).parent().parent()[0].className = "red_li";
        action_name = "关闭";
    }else{
        $(e).parent().parent()[0].className = "green_li";
    }
    $.ajax({
        async:true,
        dataType: "json",
        type: "post",
        url: "/stores/"+store_id+"/messages/set_message",
        data: {
            m_index : m_index,
            m_fun : action_name+m_fun,
            m_status : m_status
        },
        success:function(data){
            tishi_alert(data.message+"成功！");
            setTimeout(function(){
                window.location.reload();
            },1000)
        }
    })
}