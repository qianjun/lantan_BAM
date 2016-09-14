/**
 * Created with JetBrains RubyMine.
 * User: alec
 * Date: 13-1-28
 * Time: 下午4:44
 * To change this template use File | Settings | File Templates.
 */
//保存material remark
//= require kucun2

function s_supplier(){
    var suppliers = $("#supplier_box ul li");
    suppliers.css("display","none");
    var input_s = $("#supplier_n").val();
    if(input_s != "" && input_s.length !=0){
        var re = new RegExp(input_s+"+","i");
        var is_test = true;
        for(var i=0;i< suppliers.length;i++){
            if (re.test(suppliers[i].dir) || re.test(suppliers[i].innerHTML)){
                is_test = false;
                $(suppliers[i]).css("display","block")
            }
        }
        if (is_test){
            $(suppliers[suppliers.length-1]).css("display","block")
        }
    }

}

function control_deduct(e){
    var display = e.checked ? "" : "none";
    $("#techin_p,#techin_t,#techin_lable").css("display",display);
    $("#is_added").val(e.checked+0);
}

function check_revist(e){
    $("#con_"+e.alt+",#time_"+e.alt).attr("disabled",!e.checked);
    e.value = e.checked+0;
    if (!e.checked){
        $("#con_"+e.alt+",#time_"+e.alt).val("");
    }
}

function change_input(front,back){
    $(front).attr('disabled',true).val('');
    $(back).attr('disabled',false).val('0.0');
}

function set_cap(){
    var s_name = $.trim(("#still_name").val());
    var c_name = $.trim(("#cap_name").val());
    if (s_name != c_name){
        $('#refuse').val(0);
    }
}

function get_cap_code(e,store_id){
    if($.trim(e.value) == "" || $.trim(e.value).length == 0){
        $("#cap_name").val("");
    }else{
        $('refuse').val(0);
        $.ajax({
            url:"/stores/"+ store_id+"/suppliers/check",
            dataType:"json",
            type: "post",
            data:{
                name : $.trim(e.value)
            },
            success:function(data){
                $("#cap_name,#still_name").val(data.cap_name);
                if (parseInt(data.msg_type) == 1){
                    $('#refuse').val(1);
                }else{
                    $('#refuse').val(0);
                }
            }
        });
    }
}


var reg1 =  /^\d+$/;
var reg2 = /^\d+\.{0,1}\d*$/;
function save_material_remark(mat_id,store_id,obj){
    var content = $("#remark").val();
    if(mat_id!=null && content.length>0){
        $(obj).attr("disabled", "disabled");
        $.ajax({
            url:"/stores/"+store_id+"/materials/"+mat_id + "/remark",
            dataType:"text",
            type:"POST",
            data:"remark="+content,
            success: function(data){
                if(data == "1"){
                    tishi_alert("操作成功！");
                    hide_mask("#remark_div");
                //window.location.reload();
                }
            },
            error:function(err){
                tishi_alert("出错了");
            }
        });
    } else{
        tishi_alert("请输入备注内容");
    }
}

function check_material_num(m_id, store_id, obj, pandian_flag){                       //核实库存
    var check_num;
    if(pandian_flag=="")
    {
        check_num = $("#materials_tab_table #check_num_"+m_id).last().val();
    }
    else{
        check_num = $("#print_sort_table #check_num_"+m_id).val();
    }
    if(check_num.match(reg1)==null){
        tishi_alert("请输入有效数字");
    }
    else{
        if(confirm("确定核实的入库数量？")){
            $.ajax({
                url:"/materials/"+m_id + "/check",
                dataType:"script",
                data:{
                    num : check_num,
                    store_id : store_id,
                    pandian_flag:pandian_flag
                },
                success:function(data){
                },
                error:function(){
                    tishi_alert("核实失败");
                }
            });
        }
    }
}





function pay_material_order(parent_id, pay_type,store_id, obj){
    var flag = true;
    var mo_id = $("#"+parent_id+" #pay_order_id").val();
    var mo_type = $("#"+parent_id+" #pay_order_type").val();
    var if_refresh = $('#final_fukuan_tab #if_refresh').val();
    var total_price = $("#final_price").text();
    var sav_price = $("#sav_price").val();
    var sale_id = $("#sale_id").val();
    var sale_price = $("#sale_price").text();
    $(obj).attr('disabled', 'disabled');
    if(pay_type==4 && parseFloat($("#rest_count span").text()) <= parseFloat(total_price)){
        tishi_alert("门店余额不足");
        $(obj).attr('disabled', false);
        flag = false;
    }
    if(flag){
        $.ajax({
            url:"/stores/"+store_id + "/materials/pay_order",
            dataType:"json",
            data:"mo_id="+mo_id+"&pay_type="+pay_type+"&total_price="+total_price+"&sav_price="+sav_price+"&sale_id="+sale_id+"&sale_price="+sale_price,
            type:"GET",
            success:function(data,status){
                if(data["status"]==0){
                    tishi_alert("支付成功");
                    if(if_refresh=="0"){
                        if(pay_type!=5)
                        {
                            if(mo_type==1)
                            {
                                $("#merchant_"+ mo_id+" ul").find("li:nth-child(6) span").text("已付款");
                            }else{
                                $("#merchant_"+mo_id+" ul").find("li:nth-child(4) span").text("已付款");
                            }
                        }
                        hide_mask("#" + parent_id);
                    }
                    else{
                        window.location.href = "/stores/"+store_id + "/materials";
                    }
                }else if(data["status"]== -1){
                    hide_mask("#"+parent_id);
                    popup("#alipay_confirm");
                    $("#alipay_confirm #pay_order_id").val(mo_id);
                    window.open(encodeURI(data["pay_req"]),'支付宝','height=768,width=1024,scrollbars=yes,status =yes');
                }else{
                    tishi_alert("出错了，订货失败！")
                }
            },
            error:function(err){
                tishi_alert("支付失败");
            }
        });
    }
}



function get_act_count(obj,mo_id){
    var price_total = parseFloat($("#price_total").text());
    if($(obj).val()!=""){
        $.ajax({
            url:"/materials/get_act_count",
            dataType:"json",
            data:"code="+$(obj).val()+"&mo_id="+mo_id,
            type:"GET",
            success:function(data,status){
                if(data.status==1){
                    $("#use_code_count").text(data.text);
                    $("#sale_id").attr("value",data.sale_id);
                    if(data.text == ""){
                        tishi_alert("当前code不可用")
                    }
                    //$("#sale_price").text(data.text);
                    var save_price = 0.0;
                    var sale_price = 0.0;
                    if($("#use_card").attr('checked')=='checked')
                    {
                        $('#savecard_price').text($("#sav_price").val()).parent().show();
                        save_price = $("#sav_price").val()=="" ? 0.0 : $("#sav_price").val();
                    }
  
                    if($("#use_code").attr('checked')=='checked'){
                        $('#sale_price').text($("#use_code_count").text()).parent().show();
                        sale_price = $("#use_code_count").text()=="" ? 0.0 : $("#use_code_count").text();
                    }
                    var final_price = (price_total - parseFloat(save_price) - parseFloat(sale_price)) > 0 ? (price_total - parseFloat(save_price) - parseFloat(sale_price)) : 0.0
                    $("#final_price").text(parseFloat(final_price).toFixed(2));
                }
            }
        });
    }
    else{
        $("#use_code_count").text("");
        $('#sale_price').text("").parent().hide();
        tishi_alert("请输入活动代码")
        $("#use_code").attr('checked',false);
        var save_price = 0.0;
        var sale_price = 0.0;
        if($("#use_card").attr('checked')=='checked')
        {
            $('#savecard_price').text($("#sav_price").val()).parent().show();
            save_price = $("#sav_price").val()=="" ? 0.0 : $("#sav_price").val();
        }

        if($("#use_code").attr('checked')=='checked'){
            $('#sale_price').text($("#use_code_count").text()).parent().show();
            sale_price = $("#use_code_count").text()=="" ? 0.0 : $("#use_code_count").text();
        }
        var final_price = (price_total - parseFloat(save_price) - parseFloat(sale_price)) > 0 ? (price_total - parseFloat(save_price) - parseFloat(sale_price)) : 0.0
        $("#final_price").text(parseFloat(final_price).toFixed(2));
    }
   
}

function use_sale(obj, flag){
    var total_price = parseFloat($("#price_total").text());
    var sav_price = $("#sav_price").val();
    var sal_price = $("#use_code_count").text();
    if($(obj).attr("checked")=="checked"){
        if(flag=='sav'){
            if(sav_price!="")
            {
                $("#savecard_price").text(sav_price);
                $("#savecard_price").parent().show();
            }
            else{
                tishi_alert("请输入抵用金额");
                $(obj).attr("checked", false);
            }
        //$("#price_total").text((total_price - sav_price) > 0 ? (total_price - sav_price) : 0.0);
        }
        else{
            if($("#act_code").val()!=""){
                if(sal_price!=""){
                    $("#sale_price").text(sal_price);
                    $("#sale_price").parent().show();
                }
            }else{
                tishi_alert("请输入活动代码");
                $(obj).attr("checked", false);
            }
        }
    }
    else{
        if(flag=='sav'){
            $("#savecard_price").text("");
            $("#savecard_price").parent().hide();
        }
        else{
            $("#sale_price").text("");
            $("#sale_price").parent().hide();
           
        }
    }
    if($("#sav_price").val()!="" || sal_price!=""){
        var final_price = parseFloat($("#price_total").text()) - parseFloat($("#sale_price").text()=="" ? 0 : $("#sale_price").text()) - parseFloat($("#savecard_price").text()=="" ? 0 :$("#savecard_price").text())
        $("#final_price").text(final_price < 0 ? "0.0" : parseFloat(final_price).toFixed(2));
    }
}

function add_new_material(obj,idx,store_id){
    if($("#add_name_"+idx).val()==""){
        tishi_alert("请输入名称");
    }else if($("#add_li_"+idx + " #material_types").val()==""){
        tishi_alert("请选择类型");
    }
    else if($.trim($("#cost_price_"+idx).val()).match(reg2)==null){
        tishi_alert("请输入物料成本价");
    }else if($.trim($("#sale_price_"+idx).val()).match(reg2)==null){
        tishi_alert("请输入物料零售价");
    }
    else if($("#add_count_"+idx).val()==""){
        tishi_alert("请输入订货量");
    }else{
        var type = $("#add_li_"+idx + " #material_category_id").val();
        var type_name = $("#add_li_"+idx + " #material_category_id").find("option:selected").text();
        var order_count = $("#add_count_"+idx).val();
        $(obj).attr('disabled','disabled');
        $.ajax({
            url:"/stores/" + store_id + "/materials",
            dataType:"json",
            type:"POST",
            data:"&material[name]="+$("#add_name_"+idx).val()+
            "&material[price]="+$("#cost_price_"+idx).val()+"&material[ifuse_code]=0"
            + "&material[sale_price]=" + $("#sale_price_"+idx).val() + "&material[category_id]="+type,
            success:function(data,status){
                add_material_to_selected(data.material,type_name,order_count);
                $("#add_li_"+idx).remove();
            }
        });
    }
    return false;
}

function add_material_to_selected(obj,type_name,order_count){
    var id = obj.id;
    var each_total_price;
    var toatl_account = 0.0;
    var selectedItems = $("#dinghuo_selected_materials").find('#li_mat_'+id);
    var nonchecked = $("#dinghuo_search_material").find("#mat_"+id);
    if(nonchecked.length>0){
        nonchecked.attr("checked", 'checked');
    }
    if(selectedItems.length==0){
        var li = "<tr id='li_mat_"+id+"' class='in_mat_selected'><td>";
        li += obj.name + "</td><td>" + type_name + "</td><td>" + (obj.import_price== undefined ? 0 : obj.import_price) +
        "</td><td>" + obj.sale_price +"</td><td><input type='text' id='out_num_"+$(obj).attr("id")+"' value='"+ order_count +"' onkeyup=\"set_order_num(this,'"+obj.storage+"','"+id+"','"+(obj.import_price== undefined ? 0 : obj.import_price)+"','"+obj.code+"','"+type_name+"')\" style='width:50px;'/></td><td>" +
        "<span class='per_total' id='total_"+id+"'>" + parseFloat((obj.import_price== undefined ? 0 : obj.import_price) * parseInt(order_count)) + "</span></td><td>--</td><td><a href='javascript:void(0);' alt='"+id+"' onclick='del_result(this,\"_dinghuo\")'>删除</a></td></tr>";

        $("#dinghuo_selected_materials").append(li);
    }else{
        var ori_num = selectedItems.find('#out_num_mat_'+id);
        var ori_price = selectedItems.find('#total_'+id);
        ori_num.val(parseInt(ori_num.val())+parseInt(order_count));
        ori_price.text(parseInt(ori_num.val())*parseFloat((obj.import_price== undefined ? 0 : obj.import_price)));
    }
    $("#dinghuo_selected_materials").find("tr.in_mat_selected").each(function(){
        each_total_price = parseFloat($(this).find("td span").text());
        toatl_account += each_total_price;
    })
    $("#total_count").text(toatl_account.toFixed(2));
    var select_str = $("#selected_items_dinghuo").val();
    select_str += id + "_"+order_count+"_"+ (obj.import_price== undefined ? 0 : obj.import_price) +",";
    $("#selected_items_dinghuo").attr("value",select_str);
}

function removeChecked(obj){
    if(parseFloat($(obj).val()) < 0 || $(obj).val()==""){
        tishi_alert("请输入有效抵用款");
        $(obj).val("");
        $("#use_card").attr('checked', false);
        $('#savecard_price').text("").parent().hide()
    }
    else if(parseFloat($(obj).val()) > parseFloat($("#use_card").val())){
        tishi_alert("请输入小于可使用抵用款");
        $(obj).val("");
        $("#use_card").attr('checked', false);
        $('#savecard_price').text("").parent().hide()
    }
    //else if(parseFloat($(obj).val()) <= parseFloat($("#use_card").val())){
         
    //  }
    var price_total = parseFloat($("#price_total").text());
    var save_price = 0.0;
    var sale_price = 0.0;
    if($("#use_card").attr('checked')=='checked')
    {
        $('#savecard_price').text($(obj).val()).parent().show();
        save_price = $(obj).val()=="" ? 0.0 : $(obj).val();
    }
    if($("#use_code").attr('checked')=='checked'){
        $('#sale_price').text($("#use_code_count").text()).parent().show();
        sale_price = $("#use_code_count").text()=="" ? 0.0 : $("#use_code_count").text();
    }
    var final_price = (price_total - parseFloat(save_price) - parseFloat(sale_price)) > 0 ? (price_total - parseFloat(save_price) - parseFloat(sale_price)) : "0.0"

    $("#final_price").text(parseFloat(final_price).toFixed(2));
}

//function type_name(type){
//    name = "";
//    if(type==0){
//        name = "清洁用品" ;
//    }else if(type == 1){
//        name = "美容用品";
//    }else if(type==2){
//        name = "装饰产品";
//    }else if(type==3){
//        name = "配件产品";
//    }else if(type==4){
//        name = "电子产品";
//    }else if(type==5){
//        name = "其他产品"
//    }else if(type==6){
//        name = "辅助工具"
//    }else if(type==7){
//        name = "劳动保护"
//    }
//    return name;
//}

function select_check_type(obj){
    var name = $(obj).attr("id");
    var type = $(obj).val();
    if(name=="supplier_check_type"){
        if(type==1){
            $("#supplier_check_time").removeAttr("disabled");
        }
        else{
            $("#supplier_check_time").attr("disabled", true);
        }
    }else{
        if(type==1){
            $("#edit_supplier_check_time").removeAttr("disabled");
        }else{
            $("#edit_supplier_check_time").attr("disabled", true);
        }
    }
}

function edit_commit_supplier_form(obj){
    if($.trim($("#edit_supplier_name").val())==""){
        tishi_alert("请输入名称");
    }
    else if($.trim($("#edit_supplier_contact").val())==""){
        tishi_alert("请输入联系人");
    }else if($.trim($("#edit_supplier_phone").val())==""){
        tishi_alert("请输入联系电话");
    }
    else{
        if (parseInt($("#refuse").val())== 0){
            $(obj).parents("form").submit();
            $(obj).attr('disabled','disabled');
        }else{
            tishi_alert("助记码已存在");
        }
    }
}

function commit_supplier_form(obj){
    if($.trim($("#supplier_name").val())==""){
        tishi_alert("请输入名称");
    }else if($.trim($("#supplier_contact").val())==""){
        tishi_alert("请输入联系人");
    }else if($.trim($("#supplier_phone").val())==""){
        tishi_alert("请输入联系电话");
    }else{
        if (parseInt($("#refuse").val()) == 0){
            back_good_validate
            $(obj).parents("form").submit();
            $(obj).attr('disabled','disabled');
        }else{
            tishi_alert("助记码已存在");
        }
    }
}

function checkMaterial(obj){              //编辑物料验证
    var pattern = new RegExp("[=,-]")
    if($.trim($("#material_name").val())==""){
        tishi_alert("请输入物料名称");
        return false;
    }
    else if($("#material_name").val().match(pattern)!=null){
        tishi_alert("物料名称不能包含非法字符");
        return false;
    }
    else if($("#material_div #material_types").val()==""){
        tishi_alert("请输入类型");
        return false;
    }else if($("#material_sale_price").val().match(reg2)==null){
        tishi_alert("请输入物料零售价");
        return false;
    }else if($("#material_unit").val()==""){
        tishi_alert("请输入物料规格");
        return false;
    }else if($("#new_material .old_code").attr("checked")=="checked" && ($.trim($("#new_material #use_existed_code").val()).match(reg1)==null || $.trim($("#new_material #use_existed_code").val()).length!=13)){
        tishi_alert("请输入条形码, 条形码为数字，长度为13");
        return false;
    }
    if (parseInt($("#create_prod").val())==1){
        var pattern = new RegExp("[=-]")
        var name=$.trim($("#prod_name").val());
        var base= $.trim($("#base_price").val());
        var t_price = $.trim($("#t_price").val());
        var sale= $.trim($("#sale_price").val());
        var standard =$("#standard").val();
        var point =$("#prod_point").val();
        var pic_format =["png","gif","jpg","bmp"];
        if (name =="" || name.length==0){
            tishi_alert("请输入产品的名称");
            return false;
        }
        if(base == "" || base.length==0 || isNaN(parseFloat(base)) || parseFloat(base)<0){
            tishi_alert("请输入产品的零售价格,价格为数字");
            return false;
        }
        if(sale == "" || sale.length==0 || isNaN(parseFloat(sale)) || parseFloat(sale)<0){
            tishi_alert("请输入产品的促销价格,价格为数字");
            return false;
        }
        if (standard=="" || standard.length==0){
            tishi_alert("请输入产品的规格");
            return false;
        }
        if ((point!="" && point.length!=0) && isNaN(parseFloat(point)) || parseFloat(point)<0){
            tishi_alert("积分不能小于0");
            return false;
        }
        if($("#auto_revist")[0].checked){
            var time_revist =$("#time_revist option:selected").val();
            var con_revist =$("#con_revist").val();
            if (time_revist =="" || time_revist.length==0 || isNaN(parseFloat(time_revist))){
                tishi_alert("请选择回访间隔");
                return false;
            }
            if (con_revist =="" || con_revist.length==0){
                tishi_alert("请输入回访的内容");
                return false;
            }
        }
        var img_f  = false
        $(".add_img #img_div input[name$='img_url']").each(function (){
            if (this.value!="" || this.value.length!=0){
                var pic_type =this.value.substring(this.value.lastIndexOf(".")).toLowerCase();
                var img_name = this.value.substring(this.value.lastIndexOf("\\")).toLowerCase();
                var g_name = img_name.substring(1,img_name.length);
                if (pic_format.indexOf(pic_type.substring(1,pic_type.length))== -1 || pattern.test(g_name.split(".")[0]) || set_default_to_pic(this)){
                    img_f = true
                }else{
                    $(this).attr("name","img_url["+this.id+"]");
                }
            }
        })
        if(img_f){
            tishi_alert("请选择"+pic_format+"格式的图片，且名称不能包含非法字符" );
            return false
        }
        $("#desc").val(serv_editor.html());
    }
    $(obj).parents("form").submit();
    $(obj).attr('disabled','disabled');
}

function commit_in(obj){
    if($.trim($("#name").val())==""){
        tishi_alert("请输入物料名称");
    }else if($("#ruku_tab #material_types").val()==""){
        tishi_alert("请选择物料类型");
    }
    else if($.trim($("#code").val())==""){
        tishi_alert("请输入订货单号");
    }else if($.trim($("#barcode").val())==""){
        tishi_alert("请输入条形码");
    }else if($.trim($("#price").val())==""){
        tishi_alert("请输入单价");
    }else if($("#num").val()==0 || $.trim($("#num").val())=="" || $("#num").val().match(reg1)==null){
        tishi_alert("请输入有效数字");
    }else{
        var barcode = $.trim($("#barcode").val());
        var mo_code = $.trim($("#code").val());
        var store_id = $("#hidden_store_id").val();
        $(obj).attr("disabled","disabled");
        $.ajax({
            url:"/stores/" + store_id + "/materials/check_nums",
            dataType:"text",
            type:"GET",
            data:{
                barcode: barcode,
                mo_code: mo_code,
                num: $("#num").val()
            },
            success:function(data){
                if(data=="1")
                {
                    if(confirm("商品入库数目大于订单中的商品数目，仍然要入库吗？")){
                        $("#ruku_tab_form").submit();
                    }else
                    {
                        $(obj).attr("disabled",false);
                        return false;
                    }
                }else if(data=="0"){
                    $("#ruku_tab_form").submit();
                }
                else{
                    $(obj).attr("disabled",false);
                    tishi_alert("未找到物料或者订单！");
                    return false;
                }
            },
            error:function(err){
                $(obj).attr("disabled",false);
                tishi_alert("出错了...");
                return false;
            }
        });
      
    }
}

function ruku(){
    $("#ruku_tab").find('input[type="text"]').val("");
    $("#ruku_tab").find('select').get(0).selectedIndex = 0;
    $("#ruku_tab .mat-out-list").html("");
    $("#ruku_tab .search_result_mat").html("");
    popup('#ruku_tab');
    return false;
}

function chuku(){
    $("#selected_materials").html("");
    $("#search_result").hide();
    $("#out_order_form").find("#name").attr("value","");
    var objs = $("#chuku_tab").find("select");
    for(var x=0;x<objs.length;x++){
        $(objs[x]).get(0).selectedIndex = 0;
    }
    $("#selected_items").attr("value","");
    popup('#chuku_tab');
    return false;
}

function dinghuo(s_id){
    $("#dinghuo_selected_materials").html("");
    $("#dinghuo_search_result").hide();
    $("#total_count").text("0");
    var objs = $("#dinghuo_tab").find("#material_types");
    for(var x=0;x<objs.length;x++){
        $(objs[x]).get(0).selectedIndex = 0;
    }
    $("#selected_items_dinghuo").attr("value","");
    popup("#dinghuo_tab");
    if(s_id==0)
    {
        $("#add_material").hide();
        $("#activity_code").show();
    }
    else{
        $("#add_material").show();
        $("#activity_code").hide();
    }
    
    $("#order_selected_materials").html("");
}

function search_head_order(store_id){
    $.ajax({
        url:"/stores/"+store_id+"/materials/search_head_orders",
        dataType:"script",
        type:"GET",
        data:"from="+$("#date01").val()+"&to="+$("#date02").val()+"&m_status="+$("#select_h_order").val()+"&status="+$("#h_pay_status").val(),
        success:function(){
        //           alert(1);
        },
        error:function(){
        //            alert("error");
        }
    });
}

function search_supplier_order(store_id){
    $.ajax({
        url:"/stores/"+store_id+"/materials/search_supplier_orders",
        dataType:"script",
        type:"GET",
        data:"from="+$("#date03").val()+"&to="+$("#date04").val()+"&m_status="+$("#select_s_order").val()+"&type=1&status="+$("#s_pay_status").val()+"&supp="+$("#select_supplier").val(),
        success:function(){
        //           alert(1);
        },
        error:function(){
        //            alert("error");
        }
    });
}

function save_order_remark(mo_id, store_id, obj){
    var content = $("#order_remark").val();
    if(mo_id!=null && content.length>0){
        $(obj).attr("disabled", "disabled");
        $.ajax({
            url:"/stores/"+store_id+"/materials/"+mo_id+"/order_remark",
            dataType:"json",
            type:"POST",
            data:"remark="+content,
            success: function(data){
                if(data == "1"){
                    hide_mask("#order_remark_div");
                    tishi_alert("操作成功");
                }
            },
            error:function(err){
                tishi_alert("出错了");
            }
        });
    }
    else{
        tishi_alert("请输入备注内容");
    }
}

function cuihuo(order_id,type,store_id){
    $.ajax({
        url:"/stores/"+store_id+"/materials/cuihuo",
        dataType:"json",
        type:"GET",
        data:"order_id="+order_id+"&type="+type,
        success:function(data,status){
            tishi_alert("已催货");
            hide_mask('#mat_order_detail_tab');
        },
        error:function(){
        //            alert("error");
        }
    });
}

function cancel_order(order_id,type,store_id,mo_type){
    if(confirm("确认要取消订单吗？")){
        $.ajax({
            url:"/stores/"+store_id+"/materials/cancel_order",
            dataType:"json",
            type:"GET",
            data:"order_id="+order_id+"&type="+type,
            success:function(data,status){
                tishi_alert(data["content"]);
                if(mo_type==1){
                    $("#merchant_"+order_id+" ul").find("li:nth-child(6) span").text("已取消")
                }else{
                    $("#merchant_"+order_id+" ul").find("li:nth-child(4) span").text("已取消")
                }
                hide_mask("#mat_order_detail_tab")
            },
            error:function(){
                tishi_alert("数据出错!");
            }
        });
    }
}

function pay_order(mo_id,store_id){
    $.ajax({
        url: "/stores/"+store_id+"/materials/material_order" + "_pay",
        data:{
            mo_id:mo_id
        },
        dataType:"script",
        type:"GET",
        success:function(data){
            $('#mat_order_detail_tab').hide();
            $('#final_fukuan_tab #if_refresh').val("0")
        }
    })
       
}

function toggle_notice(obj){
    if($(obj).text()=="点击查看"){
        $(obj).text(" 隐藏");
    }else{
        $(obj).text("点击查看")
    }
    $(obj).next().toggle();
}
function toggle_low_materials(obj){
    if($(obj).text()=="点击查看"){
        $(obj).text(" 隐藏");
    }else{
        $(obj).text("点击查看")
    };
    $(obj).next().toggle();
}
function close_notice(obj){
    $(obj).parent().hide();
    $(obj).parent().next().hide();

/* $.ajax({
        url:"/stores/"+store_id+"/materials/update_notices",
        dataType:"json",
        type:"GET",
        data:"ids="+ids,
        success:function(){
            window.location.reload();
        }
    });*/
}
function setMaterialLow(){            //设置库存预警
    popup("#setMaterialLow");
    $("#material_low_value").focus();
}
function set_validate(){   //设置库存预警验证
    var num_flag = (new RegExp(/^\d+$/)).test($.trim($("#material_low_value").val()));
    if(num_flag == false ){
        tishi_alert("请输入正确的正整数!");
        return false;
    }else{
        $("#set_material_low_commit_button").click(function(){
            return false;
        })
    }
}
function set_material_low_count_validate(store_id,material_id){ //设置单个物料的库存预警
    //var a = $("#kucunliebiao .pageTurn").find("em").text();
    var num_flag = (new RegExp(/^\d+$/)).test($.trim($("#material_low_count").val()));
    var low_count = $("#material_low_count").val();
    if(num_flag){
        $("#remark_div").hide();
        $(".mask").hide();
        var url = "/stores/"+store_id+"/materials/set_material_low_count_commit";
        var data = {
            low_count : low_count,
            mat_id : material_id
        }
        request_ajax(url,data)
    }else{
        tishi_alert("请输入合法的数量!");
    }
}

function set_ignore(m_id, store_id,obj){   //忽略库存预警
    $.ajax({
        url: "/stores/"+store_id+"/materials/set_ignore",
        dataType: "json",
        type: "get",
        data: {
            m_id : m_id,
            store_id : store_id
        },
        success: function(data){
            if(data.status==0){
                tishi_alert("操作失败!");
            }else if(data.status==1){
                tishi_alert("操作成功!");
                $(obj).parent().parent().find("td:first").removeAttr("class");
                $(obj).parent().parent().find("td:nth-child(4)").text("存货");
                $(obj).text("取消忽略");
                $(obj).attr("onclick", "cancel_ignore("+m_id+","+store_id+","+"this);return false;")
                if(data.material_storage <= data.material_low){         //如果设置忽略,且该物料小于库存预警，则要在缺货信息提示里把相应的物料删除掉
                    $.ajax({
                        url: "/stores/"+store_id+"/materials/reflesh_low_materials",
                        dataType: "script",
                        type: "get",
                        data: {
                            store_id : store_id
                        }
                    })
                }
            }
        }
    })
}
function cancel_ignore(m_id,store_id,obj){   //取消忽略库存预警
    var obj_td = $(obj).parent();
    $.ajax({
        url: "/stores/"+store_id+"/materials/cancel_ignore",
        dataType: "json",
        type: "get",
        data: {
            m_id : m_id,
            store_id : store_id
        },
        success: function(data){
            if(data.status==0){
                tishi_alert("操作失败!");
            }else if(data.status==1){
                tishi_alert("操作成功!");
                if(data.material_storage <= data.material_low){
                    $(obj).parent().parent().find("td:first").removeAttr("class");
                    $(obj).parent().parent().find("td:first").attr("class", "data_table_error");
                    $(obj).parent().parent().find("td:nth-child(4)").text("缺货");
                    $.ajax({
                        url: "/stores/"+store_id+"/materials/reflesh_low_materials",
                        dataType: "script",
                        type: "get",
                        data: {
                            store_id : store_id
                        }
                    })
                };
                //obj_td.append("<a href='JavaScript:void(0)' onclick='set_ignore("+m_id+","+store_id+","+"this);return false;'>忽略</a>");
                $(obj).text("忽略");
                $(obj).attr("onclick", "set_ignore("+m_id+","+store_id+","+"this);return false;")
            }
        }
    })
}
function search_materials(tab_name, store_id, obj, mat_in_flag){
    var mat_code = $.trim($(obj).parents(".search").find("#search_material_code").val());
    var mat_name = $.trim($(obj).parents(".search").find("#search_material_name").val());
    var mat_type = $.trim($(obj).parents(".search").find("#search_material_type").val());
    var mo_code = $.trim($(obj).parents(".search").find("#material_order_code").val());
    var first_time = $.trim($(obj).parents(".search").find("#c_first").val());
    var last_time = $.trim($(obj).parents(".search").find("#c_last").val());
    var url = "/stores/"+store_id+"/materials/search_materials";
    var data = {
        tab_name : tab_name,
        mat_name : mat_name,
        mat_type : mat_type,
        store_id : store_id,
        mat_in_flag : mat_in_flag,
        mo_code : mo_code,
        last_time : last_time,
        first_time : first_time
    }
    if (tab_name == "out_records"){
        data["out_types"] = $("#out_types option:selected").val()
    }else{
        data["mat_code"] = mat_code;
    }
    request_ajax(url,data)
}


function deleteMaterails_loss(store_id,materials_loss_id){
    var url = "/stores/" +store_id+ "/materials/mat_loss_delete";
    var data = {
        materials_loss_id : materials_loss_id
    }
    if(confirm("删除该确定删除吗？"))
        request_ajax(url,data)
}


function fetchMatIn(obj, store_id, print_flag){
    var saved_mat_mos = "";
    var flag = true;
    if($("#ruku_tab .mat-out-list").find("tr").length==0){
        tishi_alert("请选择物料！")
    }else{
        $("#ruku_tab .mat-out-list").find("tr").each(function(index){
            var mat_code = $(this).find(".mat_code").text();
            var mo_code = $(this).find(".mo_code").text();
            var num = $.trim($(this).find(".mat_item_num").val());
            if(num.match(reg1)==null){
                flag = false;
                tishi_alert("请输入有效数字！")
            }
            var each_item = "";
            each_item += mat_code + "_";
            each_item += mo_code + "_";
            each_item += num;
            saved_mat_mos += each_item + ",";
        })
        $("#ruku_tab #mat_in_hidden_value").val(saved_mat_mos);
        $("#ruku_tab #mat_in_create").val(0);
        if(print_flag==1){
            $(obj).parents("#create_mat_in_form").attr("action", "/stores/"+ store_id +"/materials/output_barcode")
        }else{
            $(obj).parents("#create_mat_in_form").attr("action", "/stores/"+ store_id +"/create_materials_in")
        }
        if(saved_mat_mos != "" && flag)
        {
            $("#ruku_tab #mat_in_hidden_value").val(saved_mat_mos);
            $(obj).parents("#create_mat_in_form").submit();
        }
    }
}

function checkPrintNum(obj){
    var f = true;
    var is_empty = false;
    if($("#print_code_tab #selected_materials").find('tr').length==0){
        f = false;
        tishi_alert("请选择物料！")
    }
    $("#print_code_tab #selected_materials").find('input.print_code').each(function(){
        if($.trim($(this).val()).match(reg1)==null || $(this).val()==0){
            //             var code = $(this).attr('alt');
            f = false;
            is_empty = true;
        }
    })
    if(is_empty){
        tishi_alert("物料数量不正确！");
    }
    return f;
}

function checkMatLossNum(obj){
    var msg = "";
    var f = true;
    var mat_loss_length =$("#MaterialsLoss #selected_materials").find("tr").length - 1;
    if(mat_loss_length==-1){
        tishi_alert('请选择物料！');
        f = false;
    }
    $("#MaterialsLoss #selected_materials").find('input.mat_loss_num').each(function(){
        var name = $(this).attr('alt');
        var num = $(this).attr('value');
        var st_num = parseInt($(this).parent().prev().text());
        if($(this).val().match(reg1)==null){
            var msg1 = "物料名称为'"+ name + "'的报损数量不正确！";
            if(msg == "")
                msg = msg1;
            else
                msg = msg + "<br/>" +msg1;
            f = false;
        }else if(parseInt(num)<=0){
            var msg2 = "物料名称为'"+ name + "'的报损数量不能小于1！";
            msg = msg + "<br/>" + msg2;
            f = false;
        }else if(num > st_num){
            var msg3 = "物料名称为'"+ name + "'的报损数量超过了库存数量!";
            msg = msg + "<br/>" + msg3;
            f = false;
        }
    });

    if(msg != ""){
        tishi_alert(msg);
    }

    if(f == true){
        $("#add_MaterialsLoss_btn").attr('disabled',true);
        $("#MaterialsLoss_form").submit();
    }
}

function change_code(obj){
    var code = $(obj).text();
    var width = $(obj).parent().width();
    $(obj).css("display","none");
    $(obj).prev().find("input").first().css("width",width+20);
    $(obj).prev().find("input").first().css("height","30px");
    $(obj).prev().find("input").first().val(code);
    $(obj).prev().css("display","");
    $(obj).prev().find("input").first().focus();
}

function submit_code(obj,store_id){
    var new_code = $(obj).val().trim();
    var old_code = $(obj).parent().next().text();
    var mat_id = $(obj).attr("id").split("_")[1];
    var reg = /^\b\d{13}\b$/;
    if(new_code=="")
    {
        $(obj).parent().css("display","none");
        $(obj).parent().next().css("display","");
        $(obj).val(old_code);
        tishi_alert("条形码不能为空！");
    }
    else if(new_code == old_code)
    {
        $(obj).parent().css("display","none");
        $(obj).parent().next().css("display","");
    }
    else if(!reg.test(new_code))
    {
        $(obj).parent().css("display","none");
        $(obj).parent().next().css("display","");
        $(obj).val(old_code);
        tishi_alert("条形码必须为13位数字!");
    }
    else
    {
        new_code = new_code.substr(0,12);
        $.ajax({
            async:false,
            url: "materials/modify_code",
            type: "post",
            dataType: "json",
            data: {
                store_id : store_id,
                new_code : new_code,
                mat_id : mat_id
            },
            success: function(data){
                if(data.status==0){
                    tishi_alert("修改失败!");
                    $(obj).parent().hide();
                    $(obj).parent().next().show();
                    $(obj).val(old_code);
                };
                if(data.status==2){
                    tishi_alert("修改失败,该条形码已存在!");
                    $(obj).parent().hide();
                    $(obj).parent().next().show();
                    $(obj).val(old_code);
                };
                if(data.status==1){
                    tishi_alert("修改成功!");
                    $(obj).parent().hide();
                    $(obj).parent().next().text(data.new_code);
                    $(obj).parent().next().show();
                }
            }
        })
    }
}

function enableNextInput(obj, flag){
    if(flag){
        $("#ifuse_code #use_existed_code").attr('disabled', false);
    }else{
        $("#ifuse_code #use_existed_code").attr('disabled', true);
    }
}

function search_material_barcode(store_id, obj){
    var code = $(obj).parent().prev().find(".search-barcode").val();
    if(code != "" && code.length > 0){
        var url = "/materials/search_by_code";
        var data = {
            code : code,
            store_id : store_id
        }
        request_ajax(url,data)
    }
    else{
        tishi_alert("请输入条形码！");
    }
}

function back_good_records_button(store_id){
    var type = $("#back_good_records_search_type").val();
    var name = $("#back_good_records_search_name").val();
    var code = $("#back_good_records_search_code").val();
    var supplier = $("#back_good_records_search_supp").val();
    var url = "/stores/"+store_id+"/materials/page_back_records";
    var data = {
        back_type : type,
        back_name : name,
        back_code : code,
        back_supp : supplier
    }
    request_ajax(url,data)
}

function back_good_search(store_id){
    var type = $("#back_good_supplier").val();
    var type2 = $("#back_good_type").val();
    var name = $.trim($("#back_good_name").val());
    var c = new Array();
    $("input[name='good_id']").each(function(){
        c.push($(this).val());
    })
    var url = "/stores/"+store_id+"/materials/back_good_search";
    var data = {
        supplier_id : type,
        good_type : type2,
        good_name : name,
        checked : c
    }
    request_ajax(url,data)
}

function back_good_select(mat,obj){
    var c_name = mat.cname;
    if($(obj).attr("checked")=="checked"){
        $("#back_good_tbody").append("<tr id=back_good_tr"+mat.mid+"><input type='hidden' name='good_id' value='"+mat.mid+"'/>\n\
       <td>"+mat.mname+"</td><td>"+c_name+"</td><td>"+mat.mstorage+
            "</td><td>"+parseInt(mat.mnum)+"</td><td><input type='text' name='back_good_count' style='width:50px' value='1'></td>\n\
            <td><input type='text' name='back_good_price' style='width:50px' value='"+ mat.import_price+"'></td>\n\
           <td><a href='javascript:void(0)' onclick='back_good_remove_tr("+mat.mid+")'>删除</a></td></tr>")
    }else{
        $("#back_good_tr"+mat.mid).remove();
    }
}

function back_good_remove_tr(mid){          //退货时删除已选择的物料
    $("#back_good_tr"+mid).remove();
    $("#back_good_li"+mid+" input").attr("checked",false);
}




function print_out(tab_name,store_id, obj){
    var mat_type = $.trim($(obj).parents(".search").find("#search_material_type").val());
    var first_time = $.trim($(obj).parents(".search").find("#c_first").val());
    var last_time = $.trim($(obj).parents(".search").find("#c_last").val());
    var checked_mat = $("#"+tab_name+" :checkbox:checked");
    var url = '/stores/'+store_id+'/materials/print_out?first_time='+first_time+
    "&last_time="+last_time+"&mat_type="+mat_type+"&tab_name="+tab_name
 var  out_types = $("#out_types option:selected").val();
    var checked_ids = []
    if (checked_mat.length>0){
        for(var i=0;i<checked_mat.length;i++){
            checked_ids.push(checked_mat[i].id)
        }
        url += ("&mat_ids="+checked_ids.join(","))
    }
    if (out_types != ""){
        url += ("&out_types="+out_types)
    }
    window.open(url,"_blank")
}