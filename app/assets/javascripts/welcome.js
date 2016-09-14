function set_store_name(obj){
    var old_name = $(obj).text();
    $(obj).hide();
    $(obj).prev().show();
    $(obj).prev().find("input:first").val(old_name);
    $(obj).prev().find("input:first").focus();
}

function edit_store_name(obj,store_id){
    var new_name = $.trim($(obj).val());
    if(new_name == $(obj).parent().next().text()){
        $(obj).parent().hide();
        $(obj).parent().next().show();
    }else if(new_name==""){
        tishi_alert("编辑失败,门店名不能为空!");
        $(obj).parent().hide();
        $(obj).parent().next().show();
    }else{
        $.ajax({
            async:false,
            url: "welcomes/edit_store_name",
            type: "post",
            dataType: "json",
            data: {
                store_id : store_id,
                name : new_name
            },
            success: function(data){
                if(data.status==0){
                    tishi_alert("编辑失败!");
                    $(obj).parent().hide();
                    $(obj).parent().next().show();
                    var old_name = $(obj).parent().next().text();
                    $(obj).val(old_name);
                };
                if(data.status==2){
                    tishi_alert("编辑失败,已有同名的门店!");
                    $(obj).parent().hide();
                    $(obj).parent().next().show();
                    var old_name = $(obj).parent().next().text();
                    $(obj).val(old_name);
                };
                if(data.status==1){
                    tishi_alert("编辑成功!");
                    $(obj).parent().hide();
                    $(obj).parent().next().text(data.new_name);
                    $(obj).parent().next().show();
                }
            }
        })
    }
}
$(document).ready(function(){
    $("#edit_password").click(function(){
        popup("#edit_password_area");
    });

    $("#edit_password_btn").click(function(){
        var old_password = $(this).parents('form').find("#old_password").val();
        var new_password = $(this).parents('form').find("#new_password").val();
        var confirm_password = $(this).parents('form').find("#confirm_password").val();
        if($.trim(old_password) == ''){
            tishi_alert("旧密码不能为空!");
            return false;
        }
        if($.trim(new_password) == ''){
            tishi_alert("新密码不能为空!");
            return false;
        }
        if($.trim(confirm_password) == ''){
            tishi_alert("确认密码不能为空!");
            return false;
        }
        if($.trim(confirm_password) != $.trim(new_password)){
            tishi_alert("新密码和确认密码不一致!");
            return false;
        }
        if($.trim(old_password) == $.trim(new_password)){
            tishi_alert("新密码和旧密码不能相同!");
            return false;
        }
        return true;
    });

    $(".cancel_btn").click(function(){
        hide_form();
        return false;
    });

    $("#edit_password_area .close").click(function(){
        hide_form();
        return false;
    });

    function hide_form(){
        $("#edit_password_area").hide();
        $(".mask").hide();
        $("#old_password").val('');
        $("#new_password").val('');
        $("#confirm_password").val('');
    }
});

/*在线QQ*/
$(function(){
    $('.online_qq').mouseover(function(){
        $(this).stop().animate( {
            right: '0px'
        } , 500 );
    })
    $('.online_qq').mouseout(function(){
        $(this).stop().animate( {
            right: '-100px'
        } , 500 );
    })
});

function info_detail(log_id,store_id){
    var url = "/stores/"+store_id+"/welcomes/info_detail";
    $.ajax({
        type:"post",
        url: url,
        dataType: "script",
        data: {
            log_id : log_id
        }
    })
}