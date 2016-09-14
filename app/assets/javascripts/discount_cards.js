
function new_discount_card(){       //新建打折卡按钮
    popup("#discount_card_div");
}
function dcard_add_products(){   //新建打折卡添加按钮
    before_center("#add_products");
}

function add_products_search(store_id, obj){    //新建打折卡 查询服务或产品
    var type = $(obj).parents("div .search").find("select").val();
    var name = $(obj).parents("div .search").find("input").val();
    var arr = new Array();
    $("div[name='p_div']").each(function(){
        var id = $(this).find("input[name='p_hidden']").val();
        arr.push(id);
    })
    var  url= "/stores/"+store_id+"/discount_cards/add_products_search";
    var data = {
        type : type,
        name : name,
        arr : arr
    }
    request_ajax(url,data)
}

function selected_product(obj, name){       //选中产品或服务
    var id = $(obj).val();
    if($(obj).attr("checked")=="checked"){
        $("#selected_products_div").append("<div id='product_"+id+"_div' name='p_div'><em>"+name+"</em>\n\
            <span><input type='text' value='1' name='p_text' class='addre_input'/></span>\n\
           <a href='javascript:void(0)' class='remove_a' onclick='\n\
           cancel_product("+id+")'>删除</a><input type='hidden' id='hidden_"+id+"' name='p_hidden' value='"+id+"'/></div>");
    }
    else{
        $("#product_"+id+"_div").remove();
    }
}

function selected_product_submit(){     //添加产品或服务中的确定按钮
    var flag = true;
    if($("input[name='p_text']").length<=0){
        tishi_alert("请至少选择一个项目!");
        flag = false;
        return false;
    }else{
        $("input[name='p_text']").each(function(){
            var discount = $.trim($(this).val());
            if((new RegExp(/^\d+$/)).test(discount)==false || parseInt(discount)<1 || parseInt(discount)>100){
                tishi_alert("请输入正确的折扣， 必须为1~100之间的整数!");
                flag = false;
                return false;
            }
        });
    };
    if(flag){
        var h_str = ""
        $("div[name='p_div']").each(function(){
            var name = $(this).find("em").text();
            //var discount = parseInt($.trim($(this).find("input[name='p_text']").val()))*0.1;
            var discount = Math.round(parseInt($.trim($(this).find("input[name='p_text']").val()))*10)/100;
            var id = $(this).find("input[name='p_hidden']").val();
            h_str += "<li>"+name+"<span>/"+discount+"折</span><input type='hidden' name='dcard_products[]'\n\
            value='"+id+"-"+discount+"'/></li>";
        });
        $("#discount_card_div .srw_ul").html(h_str);
        $("#add_products").hide();
        $(".maskOne").hide();
    }
}

function cancel_product(pid){          //新建打折卡-删除按钮
    $("#product_"+pid+"_div").remove();
    if($("#product_"+pid+"_li input").attr("checked")=="checked"){
        $("#product_"+pid+"_li input").removeAttr("checked");
    }
}

function create_dcard_valid(obj){     //新建打折卡验证
    var name = $.trim($("#dcard_name").val());
    var price = $.trim($("#dcard_price").val());
    var img = $.trim($("#dcard_img").val());
    var desc = $.trim($("#dcard_description").val());
    var len = $("input[name='dcard_products[]']").length;
    var img_format =["png","gif","jpg","bmp"];
    var img_type = img.substring(img.lastIndexOf(".")).toLowerCase();
    var pattern = new RegExp("[`~@#$^&*()=:;,\\[\\].<>?~！@#￥……&*（）——|{}。，、？-]");
    var img_name = img.substring(img.lastIndexOf("\\")).toLowerCase();
    var g_name = img_name.substring(1,img_name.length);
    Array.prototype.indexOf=function(el, index){
        var n = this.length>>>0, i = ~~index;
        if(i < 0) i += n;
        for(; i < n; i++) if(i in this && this[i] === el) return i;
        return -1;
    }
    if(name==""){
        tishi_alert("请输入打折卡名称!");
    }
    else if(get_str_len(name)>36){
        tishi_alert("打折卡名称最多36个字符!");
    }else if(price=="" || isNaN(price) || parseInt(price)<0){
        tishi_alert("请输入正确的打折卡金额!");
    }else if(len<=0){
        tishi_alert("至少选择一个项目!");
    }else if((img!="" || img.length!=0) && ((img_format.indexOf(img_type.substring(1,img_type.length))==-1 || set_default_to_pic($("#dcard_img")[0])))){
        tishi_alert("图片大小不超过200KB,格式必须是:"+img_format);
    }else if((img!="" || img.length!=0) && pattern.test(g_name.split(".")[0])){
        tishi_alert("图片名称包含非法字符!");
    }else if(desc==""){
        tishi_alert("请输入具体内容!");
    }else{
        $(obj).parents("form").submit();
    }
}

function edit_discount_card(cid, store_id){     //编辑打折卡按钮
    var url = "/stores/"+store_id+"/discount_cards/edit";
    var data = {
        cid : cid
    }
    request_ajax(url,data)
}

function edit_dcard_add_products(cid, store_id){   //编辑打折卡添加按钮
    var url = "/stores/"+store_id+"/discount_cards/edit_dcard_add_products";
    var data = {
        cid : cid
    }
    request_ajax(url,data)
}

function edit_add_products_search(store_id, obj){    //编辑打折卡 查询服务或产品
    var type = $(obj).parents("div .search").find("select").val();
    var name = $(obj).parents("div .search").find("input").val();
    var arr = new Array();
    $("div[name='edit_p_div']").each(function(){
        var id = $(this).find("input[name='edit_p_hidden']").val();
        arr.push(id);
    })
    var url = "/stores/"+store_id+"/discount_cards/edit_add_products_search";
    var data = {
        type : type,
        name : name,
        arr : arr
    }
    request_ajax(url,data)
}

function edit_selected_product(obj, name){       //编辑-选中产品或服务
    var id = $(obj).val();
    if($(obj).attr("checked")=="checked"){
        $("#edit_selected_products_div").append("<div id='edit_product_"+id+"_div' name='edit_p_div'><em>"+name+"</em>\n\
            <span><input type='text' value='1' name='edit_p_text' class='addre_input'/></span>\n\
           <a href='javascript:void(0)' class='remove_a' onclick='\n\
           edit_cancel_product("+id+")'>删除</a><input type='hidden' id='edit_hidden_"+id+"' name='edit_p_hidden' value='"+id+"'/></div>");
    }else{
        $("#edit_product_"+id+"_div").remove();
    }
}

function edit_cancel_product(pid){          //编辑-删除按钮
    $("#edit_product_"+pid+"_div").remove();
    if($("#edit_product_"+pid+"_li input").attr("checked")=="checked"){
        $("#edit_product_"+pid+"_li input").removeAttr("checked");
    }
}

function edit_selected_product_submit(){     //编辑时添加产品或服务中的确定按钮
    var flag = true;
    if($("input[name='edit_p_text']").length<=0){
        tishi_alert("请至少选择一个项目!");
        flag = false;
        return false;
    }else{
        $("input[name='edit_p_text']").each(function(){
            var discount = $.trim($(this).val());
            if((new RegExp(/^\d+$/)).test(discount)==false || parseInt(discount)<1 || parseInt(discount)>100){
                tishi_alert("请输入正确的折扣，必须为1~100之间的整数!");
                flag = false;
                return false;
            }
        });
    };
    if(flag){
        var h_str = ""
        $("div[name='edit_p_div']").each(function(){
            var name = $(this).find("em").text();
            //var discount = parseInt($.trim($(this).find("input[name='edit_p_text']").val()))*0.1;
            var discount = Math.round(parseInt($.trim($(this).find("input[name='edit_p_text']").val()))*10)/100;
            var id = $(this).find("input[name='edit_p_hidden']").val();
            h_str += "<li>"+name+"<span>/"+discount+"折</span><input type='hidden' name='edit_dcard_products[]'\n\
            value='"+id+"-"+discount+"'/></li>";
        });
        $("#edit_discount_card_div .srw_ul").html(h_str);
        $("#edit_add_products").hide();
        $(".maskOne").hide();
    }
}

function edit_dcard_valid(obj){     //编辑打折卡验证
    var name = $.trim($("#edit_dcard_name").val());
    var price = $.trim($("#edit_dcard_price").val());
    var desc = $.trim($("#edit_dcard_description").val());
    var len = $("input[name='edit_dcard_products[]']").length;
    var img = $.trim($("#edit_dcard_img").val());
    var img_format =["png","gif","jpg","bmp"];
    var img_type = img.substring(img.lastIndexOf(".")).toLowerCase();
    var pattern = new RegExp("[`~@#$^&*()=:;,\\[\\].<>?~！@#￥……&*（）——|{}。，、？-]");
    var img_name = img.substring(img.lastIndexOf("\\")).toLowerCase();
    var g_name = img_name.substring(1,img_name.length);
    Array.prototype.indexOf=function(el, index){
        var n = this.length>>>0, i = ~~index;
        if(i < 0) i += n;
        for(; i < n; i++) if(i in this && this[i] === el) return i;
        return -1;
    }
    if(name==""){
        tishi_alert("请输入打折卡名称!");
    }else if(get_str_len(name)>36){
        tishi_alert("打折卡名称最多36个字符!");
    }else if(price=="" || isNaN(price) || parseInt(price)<0){
        tishi_alert("请输入正确的打折卡金额!");
    }else if(len<=0){
        tishi_alert("至少选择一个项目!");
    }else if((img!= "" || img.length!=0) && (set_default_to_pic($("#edit_dcard_img")[0] || img_format.indexOf(img_type.substring(1,img_type.length))==-1 ))){
        tishi_alert("图片不能超过200KB,格式必须是:"+img_format);
    }else if((img!= "" || img.length!=0) && pattern.test(g_name.split(".")[0])){
        tishi_alert("图片名称包含非法字符!");
    }else if(desc==""){
        tishi_alert("请输入具体内容!")
    }else{
        $(obj).parents("form").submit();
    }
}

function get_del_dcards(obj){
    var arr = $("input[name='del_dcards']");
    if($(obj).attr("checked")=="checked"){
        arr.each(function(){
            $(this).attr("checked", true);
        })
    }else{
        arr.each(function(){
            $(this).removeAttr("checked");
        })
    }
}

function del_all_dcards(store_id){
    var arr = $("input[name='del_dcards']:checked");
    if(arr.length==0){
        tishi_alert("至少选中一个需要删除的打折卡!");
    }else{
        var flag = confirm("是否删除选中的打折卡?");
        if(flag){
            var ids = new Array();
            arr.each(function(){
                ids.push($(this).val());
            });
            $.ajax({
                async: false,
                type: "post",
                url: "/stores/"+store_id+"/discount_cards/del_all_dcards",
                dataType: "json",
                data: {
                    ids : ids
                },
                success: function(data){
                    tishi_alert("删除成功!");
                    window.location.href="/stores/"+store_id+"/discount_cards"
                }
            })
        }
    }
}

function get_str_len(str){      //获取名称长度
    var length = str.length;
    var a = 0;
    for(var i=0;i<length;i++){
        var charCode = str.charCodeAt(i);
        if(charCode>=0 && charCode<=128){
            a += 1;
        }else{
            a += 2;
        }
    }
    return a;
}

function select_all(e){
    var all_checked = $(e).parent().parent().find("li :checkbox");
    for(var i=0;i<all_checked.length;i++){
        if (e.checked){
            if (!all_checked[i].checked){
                all_checked[i].checked = true;
                $(all_checked[i]).trigger("onclick");
            }
        }else{
            if (all_checked[i].checked){
                all_checked[i].checked = false;
                $(all_checked[i]).trigger("onclick");
            }
        }
    }
}