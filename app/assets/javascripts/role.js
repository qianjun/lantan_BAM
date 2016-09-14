/**
 * Created with JetBrains RubyMine.
 * User: alec
 * Date: 13-2-27
 * Time: 下午1:16
 * To change this template use File | Settings | File Templates.
 */
var reg1 =  /^\d+$/;
function add_role(store_id){
    popup("#add_role");
    $("#role_input").attr("value","");

}

function new_role(store_id){
    if($.trim($("#role_input").val()).length==0){
        tishi_alert("请输入角色名称");
    }else if($.trim($("#role_input").val()).length > 8){
        tishi_alert("角色名称不能超过8个汉字");
    }else{
        $.ajax({
            url:"/stores/"+store_id+"/roles/",
            type:"POST",
            dataType:"json",
            data:"name="+ $.trim($("#role_input").val())+"&store_id=" + store_id,
            success:function(data,status){
                if(data["status"]==0){
                    $("#add_role").hide();
                    tishi_alert("角色添加成功");
                    window.location.reload();
                }else if(data["status"]==1){
                    tishi_alert("你输入的角色已经存在");
                }
            },
            error:function(data){
                tishi_alert("添加失败");
            }
        });
    }
}

function edit_role(role_id){
    $("#a_role_"+role_id).hide();
    $("#input_role_"+role_id).show().focus();

}

function blur_role(obj,store_id){
    var role_id = $(obj).attr("id").split("_")[2];
    if($.trim($(obj).val()).length==0){
        tishi_alert("请输入角色名称");
    }else if($.trim($(obj).val()).length > 8){
        tishi_alert("角色名称不能超过8个汉字");
    }else if($.trim($(obj).val())==$("#a_role_"+role_id).text()){
        $("#a_role_"+role_id).show();
        $(obj).hide();
    }else{
        $.ajax({
            url:"/stores/"+store_id+"/roles/"+role_id,
            type:"PUT",
            dataType:"json",
            data:"name="+ $.trim($(obj).val())+"&store_id=" + store_id,
            success:function(data,status){
                if(data['status']=="0")
                {
                    tishi_alert("角色编辑成功")
                    $("#a_role_"+role_id).html($.trim($(obj).val()));
                }
                else{
                    tishi_alert("当前角色不存在")
                }
            },
            error:function(data){
                tishi_alert(data);
            }
        });
        $("#a_role_"+role_id).show();
        $(obj).hide();
    }
}

function set_role(obj,role_id,store_id){
    $(".people_group li").css({
        backgroundColor:"#ffffff"
    });
    $(obj).parent().parent().css({
        backgroundColor:"#ebebeb"
    });
    $.ajax({
        url:this.href,
        dataType:"script",
        type:"GET",
        data:"role_id="+role_id+"&store_id="+store_id,
        success:function(){
            $("#model_div").show();
            $("#role_id").attr("value",role_id);
        }
    });
}

function set_staff_role(staff_id,r_ids){
    popup("#set_role");
    $(".groupFunc_b input[type='checkbox']").each(function(idx,item){
        if($(item).attr("checked")=="checked"){
            $(item).attr("checked", false)
        }
    });
    if(r_ids.length>0){
        for(var i=0;i<r_ids.split(",").length;i++){
            $("#check_role_"+r_ids.split(",")[i]).attr("checked",'checked');
        }
    }
    $("#staff_id_h").attr("value",staff_id);
}

function search_staff(store_id){
    var url = "/stores/"+store_id+"/roles/staff";
    var data = {
        name : $.trim($("#name").val())
    }
    request_ajax(url,data)
}

function del_role(role_id,store_id){
    if(confirm("确定要删除该角色吗")){
        $.ajax({
            url:"/stores/"+store_id+"/roles/"+role_id,
            dataType:"json",
            type:"delete",
            success:function(){
                tishi_alert("角色删除成功")
                window.location.reload();
            }
        });
    }
}

function reset_role(store_id){
    var len = $(".groupFunc_b input:checked").length;
    if(len==0){
        tishi_alert("请选择角色");
    }else{
        var roles = "";
        $(".groupFunc_b input:checked").each(function(idx,item){
            roles += $(item).val()+",";
        });
        $.ajax({
            url:"/stores/"+store_id+"/roles/reset_role",
            dataType:"json",
            type:"POST",
            data:"staff_id="+$("#staff_id_h").val()+"&roles="+roles,
            success:function(){
                tishi_alert("设定成功")
                window.location.replace(window.location.href)
                
            },
            error:function(){

            }
        });
    }
}

function cancel_role_panel(){
    $('#model_div').hide();
    $(".people_group li").css({
        backgroundColor:"#ffffff"
    });
}

function selectAll(obj){
    if($(obj).attr("checked")=="checked"){
        $(obj).parent().next().find("input[type='checkbox']").attr("checked", "checked")
    }else{
        $(obj).parent().next().find("input[type='checkbox']").attr("checked", false)
    }
}



function check_advert(){
    var content = $.trim($("#content").val());
    var last_time = $("#last_time").val();
    if (content == "" || content.length == 0){
        tishi_alert("请输入广告内容！")
    }else{
        if (parseInt(last_time)==0){
            tishi_alert("广告显示时间不能等于0");
        }else{
            $("#advert_form").submit(); 
        }
    }
}


function pay_fee(store_id){
    var pay_fee = $("#pay_fee").val();
    if (parseFloat(pay_fee) >= 10){
        $("#alipay_tab .close").trigger("click");
        show_center("#confirm_tab");
        window.open("/stores/"+store_id+"/messages/alipay_charge?pay_fee="+pay_fee,"_target");

    }else{
        tishi_alert("充值金额有误，最低金额为10元！");
    }
   
}