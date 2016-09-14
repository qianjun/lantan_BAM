function new_save_card(){   //新建储值卡
    popup("#save_cards_div");
}

function create_save_card_valid(obj){
    var checked_len = $("input[id*='sv_card_']:checked").length;
    var name = $.trim($("#scard_name").val());
    var img = $.trim($("#scard_img").val());
    var s_money = $.trim($("#scard_started_money").val());
    var e_money = $.trim($("#scard_ended_money").val());
    var desc = $.trim($("#scard_desc").val());
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
        tishi_alert("请输入储值卡名称!");
    }else if(get_str_len(name)>36){
        tishi_alert("储值卡名称最长36个字符!");
    }else if(checked_len<=0){
        tishi_alert("至少选择一个项目!")
    }else if((img!="" || img.length!=0) && (img_format.indexOf(img_type.substring(1,img_type.length))==-1 || set_default_to_pic($("#scard_img")[0]))){
        tishi_alert("图片不能超过200KB,格式必须是:"+img_format);
    }else if((img!="" || img.length!=0) && pattern.test(g_name.split(".")[0])){
        tishi_alert("图片名称包含非法字符!");
    }else if(s_money==""){
        tishi_alert("请输入充值金额!");
    }else if(isNaN(s_money) || parseInt(s_money)<=0){
        tishi_alert("请输入正确的充值金额!");
    }else if(e_money==""){
        tishi_alert("请输入赠送金额!");
    }else if(isNaN(e_money) || parseInt(e_money)<0){
        tishi_alert("请输入正确的赠送金额!");
    }else if(desc==""){
        tishi_alert("请输入储值卡说明!");
    }else{
        $(obj).parents("form").submit();
    }
}

function edit_save_card(store_id, cid){
    $.ajax({
        type: "get",
        url: "/stores/"+store_id+"/save_cards/"+cid+"/edit",
        dataType: "script"
    })
}

function update_save_card_valid(obj){
    var name = $.trim($("#edit_scard_name").val());
    var checked_len = $("input[id*='sv_card_']:checked").length;
    var s_money = $.trim($("#edit_scard_started_money").val());
    var e_money = $.trim($("#edit_scard_ended_money").val());
    var desc = $.trim($("#edit_scard_desc").val());
    var img = $.trim($("#edit_scard_img").val());
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
        tishi_alert("请输入储值卡名称");
    }else if(checked_len<=0){
        tishi_alert("至少选择一个项目!");
    }else if(get_str_len(name)>36){
        tishi_alert("储值卡名称最多36个字符!");
    }else if((img!="" || img.length!=0) && (img_format.indexOf(img_type.substring(1,img_type.length))==-1 || set_default_to_pic($("#edit_scard_img")[0]))){
        tishi_alert("图片不能超过200KB,格式必须是:"+img_format);
    }else if((img!="" || img.length!=0) && pattern.test(g_name.split(".")[0]) ){
        tishi_alert("图片名称包含非法字符!");
    }else if(s_money==""){
        tishi_alert("请输入充值金额!");
    }else if(isNaN(s_money) || parseInt(s_money)<=0){
        tishi_alert("请输入正确的充值金额!");
    }else if(e_money==""){
        tishi_alert("请输入赠送金额!");
    }else if(isNaN(e_money) || parseInt(e_money)<0){
        tishi_alert("请输入正确的赠送金额!");
    }else if(desc==""){
        tishi_alert("请输入储值卡说明!");
    }else{
        $(obj).parents("form").submit();
    }
}

function get_del_scards(obj){
    var arr = $("input[name='del_scards']");
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

function del_all_scards(store_id){
    var arr = $("input[name='del_scards']:checked");
    if(arr.length==0){
        tishi_alert("至少选中一个需要删除的储值卡!");
    }else{
        var flag = confirm("是否删除选中的储值卡?");
        if(flag){
            var ids = new Array();
            arr.each(function(){
                ids.push($(this).val());
            });
            $.ajax({
                async: false,
                type: "post",
                url: "/stores/"+store_id+"/save_cards/del_all_scards",
                dataType: "json",
                data: {
                    ids : ids
                },
                success: function(data){
                    tishi_alert("删除成功!");
                    window.location.href="/stores/"+store_id+"/save_cards"
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

