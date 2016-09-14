function submit_search_form(store_id,type,obj){
    var form = $(obj).parent().parent().find("#select_types");
    var name = $.trim($(obj).parent().parent().find("#name").val());
    var types = $(form).find("#material_category_id").val();
    if(types==""&&name==""){
        tishi_alert("请选择类型或填写名称！");
    }
    else{
        var data = "name="+name+"&types="+types+"&type="+type;
        if(type==1){
            data += "&from=" + $(".fixed").attr("id");
        }
        $.ajax({
            async:true,
            url:encodeURI("/stores/"+store_id+"/materials/search?"+data),
            dataType:"script",
            type:"GET",
            success:function(){
                $("#search_result").show();
                $("#dinghuo_search_result").show();
                var mat_ids = [];
                if(type==1){
                    $("#dinghuo_selected_materials").find("tr").each(function(){
                        mat_ids.push($(this).attr('id').split('_')[2])
                    })

                    $("#dinghuo_search_material").find('input').each(function(){
                        var mat_id = $(this).attr('id').split('_')[1];

                        if(mat_ids.indexOf(mat_id)>=0){
                            $(this).attr("checked", 'checked');
                        }
                    })
                }else if(type==2){
                    $("#selected_materials").find("tr").each(function(){
                        mat_ids.push($(this).attr('id').split('_')[2])
                    })
                    // alert(mat_ids)
                    $("#search_result").find('input.print_mat').each(function(){
                        var mat_id = $(this).attr('id').split('_')[1];
                        //alert(mat_id)
                        if(mat_ids.indexOf(mat_id)>=0){
                            $(this).attr("checked", 'checked');
                        }
                    })
                }
            },
            error:function(){
                tishi_alert("查询失败！");
            }
        });
    }
}

function select_material(obj,name,type,panel_type){
    var select_str = $("#selected_items").val();
    if($(obj).is(":checked")){
        var tr = "<tr id='li_"+$(obj).attr("id")+"'><td>";
        tr += name + "</td><td>" + type + "</td><td>" + $(obj).val() + "</td><td>" +
        "<input type='text' id='out_num_"+$(obj).attr("id")+"' value='1' onchange=\"set_out_num(this,'"+$(obj).val()+"')\" style='width:50px;'/></td><td><a href='javascript:void(0);' alt='"+$(obj).attr("id")+"' onclick='del_result(this,\"\")'>删除</a></td></tr>";
        $("#selected_materials").append(tr);
        select_str += $(obj).attr("id").split("_")[1] + "_1,";
        $("#selected_items").attr("value",select_str);
    }
    else{
        var selected_str = "";
        $("#selected_items").val("");
        $("#li_"+$(obj).attr("id")).remove();
        $("#selected_materials").find("tr").each(function(){
            selected_str += $(this).attr("id").split("_")[2] + "_1,";
        })
        $("#selected_items").val(selected_str);

    }
}

//库存报损选择
function select_mat_loss_material(obj,name,code,typesname,storage,id){
    var count = 0;
    var m_id = 0;
    $("#MaterialsLoss #selected_materials").find("tr").each(function(){
        m_id = $(this).attr("id").split("_")[2];
        if(id == m_id)
            count++;
    });

    if($(obj).is(":checked")){
        if(count == 0){
            var tr = "<tr id='li_"+$(obj).attr("id")+"'><td>";
            tr += name + "</td><td>"+ typesname + "</td><td>" + code + "</td><td>" + storage +"</td><td>"+ "<input type='text' value='1'  alt="+name+" class='mat_loss_num'  name='mat_losses["+ $(obj).attr('id').split('_')[1] +"][mat_num]' style='width:60px' /><input type='hidden' style='width:10px' value='"+storage +"'/>" + "</td><td>" +
            "<a href='javascript:void(0)' class='"+ $(obj).attr("id") +"' onclick='removeRow(this,2); return false;'>移除</a></td>" +"<input type='hidden' name='mat_losses["+ $(obj).attr('id').split('_')[1] +"][mat_id]' value="+ id + "></tr>";
            $("#MaterialsLoss #selected_materials").append(tr);
        }
        else
        {
            $("#MaterialsLoss #selected_materials").find("tr").each(function(){
                m_id = $(this).attr("id").split("_")[2];
                if(id == m_id)
                    $(this).remove();
            });
            var tr = "<tr id='li_"+$(obj).attr("id")+"'><td>";
            tr += name + "</td><td>"+ typesname + "</td><td>" + code + "</td><td>" + storage +"</td><td>"+ "<input type='text' value='1'  alt="+name+" class='mat_loss_num'  name='mat_losses["+ $(obj).attr('id').split('_')[1] +"][mat_num]' style='width:60px' /><input type='hidden' style='width:10px' value='"+storage +"'/>" + "</td><td>" +
            "<a href='javascript:void(0)' class='"+ $(obj).attr("id") +"' onclick='removeRow(this,2); return false;'>移除</a></td>" +"<input type='hidden' name='mat_losses["+ $(obj).attr('id').split('_')[1] +"][mat_id]' value="+ id + "></tr>";
            $("#MaterialsLoss #selected_materials").append(tr);
        }
    }
    else{
        $("#li_"+$(obj).attr("id")).remove();
    }
}

function select_print_material(obj,name,type){
    if($(obj).is(":checked")){
        var tr = "<tr id='li_"+$(obj).attr("id")+"'><td>";
        tr += $(obj).attr("alt") + "</td><td>" +name + "</td><td>" + type + "</td><td>" + $(obj).attr('data-unit') +"</td><td>"+ "<input type='text' class='print_code' alt="+$(obj).attr("alt")+" name='print["+ $(obj).attr('id').split('_')[1] +"][print_code_num]' style='width:60px' />" + "</td><td>" +
        "<a href='javascript:void(0)' class='"+ $(obj).attr("id") +"' onclick='removeRow(this,1); return false;'>移除</a></td>" +"<input type='hidden' name='print["+ $(obj).attr('id').split('_')[1] +"][print_code]' value="+ $(obj).attr('alt') + "></tr>";
        $("#print_code_tab #selected_materials").append(tr);
    }
    else{
        $("#li_"+$(obj).attr("id")).remove();
    }
}

//select_order_material(this,'水枪',       '辅助工具',1,'234234566','2344.0')
function select_order_material(obj,type,m){
    var old_total = parseFloat($("#total_count").text());
    var  supplier= $(".fixed").attr("id");
    if (supplier != undefined){
        if($(obj).is(":checked")){
            var id = m.id;
            var storage = m.storage == null ? 0 : m.storage;
            var import_price = m.import_price == null ? 0 : m.import_price
            var sale_price = m.sale_price == null　? 0 : m.sale_price
            var li = "<tr id='"+id+"' class='in_mat_selected'><td>";
            li += m.name + "</td><td>" + type + "</td><td><input type='text' onblur=\"cal_fees()\" \n\
            id='import_price_"+id+"' value='" + import_price +"' /></td><td>" + sale_price +"</td><td>\n\
           <input type='text' id='out_num_"+id+"' value='1' onblur=\"cal_fees()\" style='width:50px;'/></td><td>" +
            "<span class='per_total' id='total_"+id+"'>" +  import_price + "</span></td><td id='storage_"+id+"'>" + storage +"</td><td>\n\
          <a href='javascript:void(0);' alt='"+id+"' onclick='del_result(this,\"_dinghuo\")'>删除</a></td></tr>";
            if($("#dinghuo_selected_materials").find("tr.in_mat_selected").length > 0){
                $("#dinghuo_selected_materials").find("tr.in_mat_selected:last").after(li);
                $("#total_count").text((old_total+parseFloat(import_price)).toFixed(2))
            }
            else{
                $("#dinghuo_selected_materials").prepend(li);
                $("#total_count").text(import_price);
            }
        }else{
            $("#dinghuo_selected_materials").find("#li_"+$(obj).attr("id")).remove();
            var select_items = $("#selected_items_dinghuo").val().split(",");
            var del_item =  jQuery.grep(select_items,function(n,i){
                return select_items[i].split("_")[0]==$(obj).attr("id").split("_")[1];
            });
            select_items = jQuery.grep(select_items,function(n,i){
                return select_items[i].split("_")[0]!=$(obj).attr("id").split("_")[1];
            });
            $("#selected_items_dinghuo").attr("value",select_items.join(","));
            var items = del_item[0].split("_");

            $("#total_count").text((old_total - parseFloat(items[2]) * parseInt(items[1])).toFixed(2));
        }
    }

}

function del_result(obj,type){
    //   alert($("#selected_items").val());
    var matId = $(obj).attr('alt');
    var select_items = $("#selected_items"+type).val().split(",");
    var del_item =  jQuery.grep(select_items,function(n,i){
        return select_items[i].split("_")[0]==$(obj).parent().parent().attr("id").split("_")[2];
    });
    select_items = jQuery.grep(select_items,function(n,i){
        return select_items[i].split("_")[0]!=$(obj).parent().parent().attr("id").split("_")[2];
    });
    $("#selected_items"+type).attr("value",select_items.join(","));
    $(obj).parent().parent().remove();

    if(type=="_dinghuo"){
        $("#dinghuo_search_material").find("input").each(function(){
            var mat_id = $(this).attr("id").split("_")[1];
            if(matId == mat_id){
                $(this).attr("checked",false);
            }
        })
        var items = del_item[0].split("_");
        var old_total = parseFloat($("#total_count").text());
        $("#total_count").text((old_total - parseFloat(items[2]) * parseInt(items[1])).toFixed(2));
    }else{
        $("#search_material").find("input").each(function(){
            var mat_id = $(this).attr("id");
            if(matId == mat_id){
                $(this).attr("checked",false);
            }
        })
    }
}

function set_out_num(obj,storage){
    if(parseInt($(obj).val())>parseInt(storage)){
        tishi_alert("请输入小于库存量的值");
    }else if(parseInt($(obj).val())==0){
        tishi_alert("请输入出库量");
    }else{
        var select_itemts = $("#selected_items").val().split(",");
        for(var i=0;i<select_itemts.length;i++){
            if(select_itemts[i].split("_")[0]==$(obj).parent().parent().attr("id").split("_")[2]){
                select_itemts[i] = select_itemts[i].split("_")[0] + "_" + $(obj).val();
            }
        }
        $("#selected_items").attr("value",select_itemts.join(","));
    }
}

function cal_fees(){
    var is_suit = false;
    var total_price = 0;
    var show_tab = [];
    $("#dinghuo_selected_materials tr").each(function(){
        var import_price =  parseFloat($("#import_price_"+this.id).val());
        var out_num =  parseInt($("#out_num_"+this.id).val());
        if(isNaN(import_price) || import_price < 0 || isNaN(out_num) || out_num <=0){
            is_suit =  true
        }else{
            var name = $(this).find("td").eq(0).html();
            var types = $(this).find("td").eq(1).html();
            var t_price = $(this).find("td").eq(5).find("span").html();
            $("#total_"+this.id).text((import_price*out_num).toFixed(2));
            total_price += round(import_price*out_num,2);
            show_tab.push("<tr><td>"+name+"</td><td>"+types+"</td><td>"+import_price+"</td><td>"+out_num+"</td><td>"+t_price+"</td>")
        }
    })
    if (is_suit || $("#dinghuo_selected_materials tr").length <=0){
        tishi_alert("请输入进货价和订货量！");
        return false;
    }
    else{
        $("#total_count").text(total_price.toFixed(2));
        return show_tab;
    }
}

function confirm_pay(){
    var show_tab = cal_fees();
    if(show_tab){
        var supplier = $("#supplier_box .fixed")[0];
        if (parseInt(supplier.id)>0){
            if (confirm("确定从供应商"+supplier.innerHTML+"订货吗？")){
                var total_price = $("#total_count").text();
                $("#dh_price_total").text(total_price);
                $("#supplier_from").html("订货渠道："+supplier.innerHTML);
                $("#dinghuo_tab").hide();
                $("#order_selected_materials").html(show_tab.join())
                popup("#fukuan_tab");
            }
        }else{
            tishi_alert("请选择供应商")
        }
    }else{
        tishi_alert("请选择物料");
    }
}

function submit_material_order(form_id,obj){
    var data = {};
    data["supplier"]=$(".fixed").attr("id");
    data["material_order"]={};
    $("#dinghuo_selected_materials tr").each(function(){
        var import_price =  parseFloat($("#import_price_"+this.id).val());
        var out_num =  parseInt($("#out_num_"+this.id).val());
        data["material_order"][this.id]= [out_num,import_price]
    })
    $("#submit_material,#submit_spinner").toggle();
    $.ajax({
        url:$("#"+form_id).attr("action"),
        dataType:"script",
        data:data,
        type:"POST",
        success:function(data,status){
        },
        error:function(err){
            $("#submit_material,#submit_spinner").toggle();
            tishi_alert("订货中...");
        }
    });

}



function set_order_num(obj,storage,m_id,m_price,m_code,m_type){
    var old_num = parseFloat($("#total_"+m_id).text());
    var new_num = parseFloat($(obj).val()=="" ? 0 : $(obj).val()) * parseFloat(m_price);
    var name = $("#mat_"+m_id).next().text();
    $("#total_"+m_id).text(new_num.toFixed(2));
    if(parseInt($(".fixed").attr("id"))==0 && parseInt($(obj).val())>parseInt(storage)){
        tishi_alert("请输入小于库存量的值");
    }else if(parseInt($(obj).val())==0 || $(obj).val()==""){
        tishi_alert("请输入订货量");
    }else{
        var select_itemts = $("#selected_items_dinghuo").val().split(",");
        for(var i=0;i<select_itemts.length;i++){
            if(select_itemts[i].split("_")[0]==$(obj).parent().parent().attr("id").split("_")[2]){
                select_itemts[i] = select_itemts[i].split("_")[0] + "_" + $(obj).val() + "_" + select_itemts[i].split("_")[2] + "_" + m_code + "_" + name + "_" + m_type;
            }
        }
        $("#selected_items_dinghuo").attr("value",select_itemts.join(","));
    }
    var total_price = 0;
    $("#dinghuo_selected_materials").find(".per_total").each(function(){
        total_price += parseFloat($(this).text());
    })

    $("#total_count").text(total_price.toFixed(2));
}

function submit_out_order(form_id){
    var a = true;
    $("#selected_materials").find("input").each(function(){
        var storage = parseInt($(this).parent().prev().text());
        var name = $(this).parent().parent().find("td:first").text();
        if($(this).val().match(reg1)==null){
            tishi_alert("请输入有效出库量");
            a = false;
        }
        if(parseFloat($(this).val()) > storage){
            tishi_alert("【"+name+"】出库量请输入小于库存量的值");
            a = false;
        }else if(parseFloat($(this).val()) < 0){
            tishi_alert("【"+name+"】出库量请输入大于0的值");
            a = false;
        }
    })
    if($("#mat_out_types").val()==""){
        tishi_alert("请选择出库类型")
        a = false;
    }
    if(a){
        if($("#selected_items").val()!=null && $("#selected_items").val()!=""){
            $("#"+form_id).find("input[class='confirm_btn']").attr("disabled","disabled");
            $.ajax({
                url:$("#"+form_id).attr("action"),
                dataType:"json",
                data:{
                    staff : $("#staff").val(),
                    selected_items : $("#selected_items").val(),
                    types : $("#mat_out_types").val(),
                    remark : $("#chuku_remark").val()
                },
                type:"POST",
                success:function(data,status){
                    if(data["status"]==0){
                        tishi_alert("出库成功");
                        window.location.reload();
                    }
                },
                error:function(err){
                    tishi_alert("正在出库...");
                }
            });
        }else{
            tishi_alert("请选择物料");
        }
    }
}

function add_material(store_id){
    var i = $("#dinghuo_selected_materials").find("tr").size();
    if(i>0){
        i = $("#dinghuo_selected_materials").find("tr").last().attr("id").split("_")[2];
    }
    var li = "<tr id='add_li_"+i+"'><td><input type='text' id='add_name_"+i+"' /></td><td>"+
    $("#select_types").html() +"</td><td><input type='text' id='cost_price_"+i+"'/></td><td><input type='text' id='sale_price_"+i+"'/></td><td><input type='text' id='add_count_"+i+"' /></td><td>--</td><td>--</td><td>"+
    "<button onclick=\"return add_new_material(this,'"+i+"','"+store_id+"')\">确定</button></td></tr>" ;
    //    alert(li);
    $("#dinghuo_selected_materials").append(li);
}

function change_supplier(obj){
    var idx = $(obj).find("option:selected").index();
    $("#dinghuo_search_material").html("");
    $("#selected_items_dinghuo").attr("value","");
    $("#total_count").text(0.0);
    if(idx == 0){
        $("#dinghuo_selected_materials").html("");
        $("#activity_code").show();
        $("#add_material").hide();
        $("#add_new_materials").html("");
    }else{
        $("#dinghuo_selected_materials").html("");
        $("#activity_code").hide();
        $("#add_material").show();
    }
}

function back_good_validate(store_id){      //退货确定按钮验证
    var data = new Array();
    var flag = true;
    $("input[name='back_good_count']").each(function(){
        if ((new RegExp(/^\d+$/)).test($.trim($(this).val()))==false || parseInt($.trim($(this).val()))<=0){
            tishi_alert("请输入正确的退货数量，数量必须为大于零的整数!");
            flag = false;
            return false;
        }
    });
    $("input[name='back_good_price']").each(function(){
        var price = $.trim($(this).val())
        if (price == "" || price.length==0 || isNaN(parseFloat(price)) || parseFloat(price) < 0){
            tishi_alert("请输入正确的退货价格，价格必须为大于零！");
            flag = false;
            return false;
        }
    });
    var total_price = 0;
    var supplier_id = $("#back_good_supplier option:selected").val();
    $("#back_good_tbody tr").each(function(){
        var storage = parseInt($(this).find("td:nth-child(4)").text());
        var num = parseInt($(this).find("td:nth-child(5)").text());
        var back_num = parseInt($(this).find("td:nth-child(6) input").val());
        var back_price = parseFloat($(this).find("td:nth-child(7) input").val());
        if(back_num > num || back_num > storage){
            tishi_alert("退货量不能大于库存量或者订货量!");
            flag = false;
            return false;
        }else{
            var id = $(this).find("input[name='good_id']")[0].value;
            total_price += (back_num*back_price)
            data.push(id+"-"+back_num+"-"+back_price);
        }
    })
    if(flag && confirm("您本次的退款总额是"+total_price+"，确认退货吗？")){
        $("#submit_back,#submit_spinner").toggle();
        $.ajax({
            url: "/stores/"+store_id+"/materials/back_good_commit",
            dataType : "json",
            type : "get",
            data : {
                data : data,
                supplier : supplier_id
            },
            success:function(data){
                if(data==1){
                    tishi_alert("退货成功!")
                    window.location.reload();
                }else{
                    $("#submit_back,#submit_spinner").toggle();
                    tishi_alert("无数据!");
                }
            },
            error:function(data){
                $("#submit_back,#submit_spinner").toggle();
                tishi_alert("退货失败!");
            }
        })
    }

}