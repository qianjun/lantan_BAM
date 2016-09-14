var reg1 =  /^\d+$/;
$(document).ready(function(){
    $("#mat_code").focus();
    $("#mat_code").live('keyup', function(event){
        var codeVal = $(this).val();
        var action_name = $(this).attr("data_action");
        var e = event ? event : window.event
        if(e.keyCode==13){
            $.ajax({
                url:"/get_material",
                dataType:"text",
                type: "get",
                data:{
                    code: codeVal,
                    action_name: action_name
                },
                success:function(data) {
                    if(data=="fail"){
                        $(".search_alert").show();
                        $("#mat_code").val('');
                        $("#mat_code").focus();
                    }
                    else{
                        $(".search_alert").hide();
                        $(".mat-out-list").find(".newTr_red").removeClass("newTr_red");
                        $(".mat_code").each(function(){
                            if($(this).text()==codeVal){
                                $(this).parent('tr').addClass("newTr_red");
                                var ori_num = parseInt($(this).siblings(".mat_item_num").text());
                                $(this).siblings(".mat_item_num").text(ori_num+1);
                                $(this).siblings(".num_box").find('input').val(ori_num+1);
                                return false;
                            }
                        });
                        if($(".mat-out-list").find(".newTr_red").length==0){
                            $(".mat-out-list").append(data);
                        }
                        $("#mat_code").val('');
                        $("#mat_code").focus();
                    }
                }
            });
        }
    });
});

function chooseCookie(obj){
    var staff_id = $(obj).val();
    $.get("/save_cookies", {
        staff_id: staff_id
    })
    .done(function(data) {})
}

function changeNum(obj){
    var ori_num = $(obj).parent("td").siblings(".mat_item_num").text();
    $(obj).parent("td").siblings(".mat_item_num").hide();
    $(obj).parent("td").prev(".num_box").find("input").val(ori_num).end().show();
}

function hideInput(obj){
    var ori_num = $(obj).val();
    $(obj).parent("td").hide();
    $(obj).parent("td").siblings(".mat_item_num").text(ori_num).show();
}

function removeRow(obj, print_flag){
    if(print_flag=="1"){
        var id = $(obj).attr('class');
        $("#print_code_tab #search_result").find("#" + id).attr("checked", false);
    }
    if(print_flag=="2"){
        var id = $(obj).attr('class');
        $("#MaterialsLoss #mat_loss_search_result").find("#" + id).attr("checked", false);
    }
    $(obj).parents("tr").remove();
}

function checkNums(store_id){
    var form_action_url = "/stores/"+ store_id +"/create_materials_in"
    var mat_mos = {};
    var material_order_id = "";
    var mat_in_length = $(".mat-out-list").find("tr").length - 1;
    if(mat_in_length==-1){
        tishi_alert('请选择物料！');
        return false;
    }
    var f = true;
    $(".mat-out-list").find("tr").each(function(index){
        material_order_id = this.id;
        var mat_code = $(this).find(".mat_code").text();
        var num = $.trim($(this).find(".mat_item_num").val());
        if (mat_mos[material_order_id] == null){
            mat_mos[material_order_id] = {}
        }
        mat_mos[material_order_id][mat_code]=num;
        if(num.match(reg1)==null){
            tishi_alert("请输入正确的数字！")
            f = false;
        }
    });
    if(f){
        $.ajax({
            url:"/stores/" + store_id + "/materials/check_nums",
            dataType:"json",
            type:"post",
            data:{
                mat_mos: mat_mos
            },
            success:function(data){
                if(data.notice){
                    $.ajax({
                        url: form_action_url,
                        dataType:"json",
                        type:"POST",
                        data:{
                            mat_in_items: data.mat_info,
                            material_order_id : data.material_order_id
                        },
                        success:function(data2){
                            if(data2['status']=="1")
                            {
                                tishi_alert("入库成功！");
                                window.location.href = "/stores/" + store_id + "/materials";
                            }else{
                                tishi_alert("入库失败！");
                            }
                        }
                    });
                }else{
                    tishi_alert(data.msg,5);
                }
                  
            }
        });
    }

}


function checkMatOutNum(obj){
    var f = true;
    $(".mat-out-list").find("tr").each(function(index){
        var out_num = parseInt($(this).find(".mat_item_num").text());
        var mat_storage = parseInt($(this).find(".material_storage").text());
        var mat_name = $(this).find(".mat_name").text();
        if(out_num > mat_storage){
            tishi_alert("【" + mat_name + "】出库量(" + out_num +")大于库存量("+ mat_storage+")");
            $(this).remove();
        }
    })
    if($("#mat_out_types").val()==""){
        tishi_alert("请选择出库类型")
        f = false;
    }
    if(f && $(".mat-out-list").find("tr").length > 0){
        $(obj).parents("form").submit();
    }
}

function disbaleSib(obj, flag){
    if(flag=="next"){
        $(obj).parents(".search").siblings(".scan-upload").find("input[type='submit']").attr("disabled", "disabled");
        $(obj).parent().next().attr("disabled", false);
    }else{
        $(obj).parents(".scan-upload").siblings(".search").find("input[type='text']").attr("disabled", "disabled");
        $('.search_alert').hide();
        $(obj).parent().next().find("input[type='submit']").attr("disabled", false);
    }
}