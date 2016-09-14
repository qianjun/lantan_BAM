//编辑产品
function edit_prod(id,store_id){
    prod_request(id,store_id,"edit_prod")
}

//显示产品
function show_prod(id,store_id){
    prod_request(id,store_id,"show_prod")
}

function prod_request(id,store_id,action){
    var url = "/stores/"+store_id+"/products/"+ id;
    request_ajax(url+"/"+action,'',"post")
}

//添加或者编辑产品
function add_product(e){
    var pattern = new RegExp("[=-]")
    var name=$("#name").val();
    var base=$("#base_price").val();
    var t_price =$("#t_price").val();
    var sale=$("#sale_price").val();
    var standard =$("#standard").val();
    var point =$("#prod_point").val();
    var pic_format =["png","gif","jpg","bmp"];
    if ($("#prod_material option").length==0){
        tishi_alert("请添加产品的物料");
        return false;
    }
    if (name=="" || name.length==0 || pattern.test(name)){
        tishi_alert("请输入产品的名称,不能包含非法字符");
        return false;
    }
    if(t_price == "" || t_price.length==0 || isNaN(parseFloat(t_price)) || parseFloat(t_price)<0){
        tishi_alert("请输入产品的成本价,价格为数字");
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
        tishi_alert("图片格式必须是："+pic_format+"，名称不能包含非法字符，单个大小不能超过200KB;" );
        return false
    }
    $("#desc").val(serv_editor.html());
    $("#add_prod").submit();
    $(e).removeAttr("onclick");
}


//显示服务
function show_service(store_id,id){
    prod_request(id,store_id,"show_serv")
}

// 添加服务
function add_service(store_id){
    request_ajax("/stores/"+ store_id+"/products/add_serv",'',"post")
}

//编辑服务
function edit_service(store_id,id){
    prod_request(id,store_id,"edit_serv")
}

//添加或者编辑服务
function edit_serv(e){
    var pattern = new RegExp("[=-]");
    var name=$("#name").val();
    var base=$("#base_price").val();
    var sale=$("#sale_price").val();
    var origin =$("#t_price").val();
    var time=$("#cost_time").val();
    var point =$("#prod_point").val();
    var pic_format =["png","gif","jpg","bmp"];
    if (name=="" || name.length==0 || pattern.test(name)){
        tishi_alert("请输入服务的名称,不能包含非法字符");
        return false;
    }
    var is_num=false
    $("#add_products input").each(function(){
        if(isNaN(parseInt(this.value)) || parseInt(this.value)<=0){
            is_num=true
        }
    })
    if (is_num){
        tishi_alert("产品或服务的数量必须大于1");
        return false;
    }
    if(base == "" || base.length==0 || isNaN(parseFloat(base)) || parseFloat(base)<0){
        tishi_alert("请输入服务的零售价格,价格为数字");
        return false;
    }
    if(sale == "" || sale.length==0 || isNaN(parseFloat(sale)) || parseFloat(sale)<0){
        tishi_alert("请输入服务的促销价格,价格为数字");
        return false;
    }
    if(origin == "" || origin.length==0 || isNaN(parseFloat(origin)) || parseFloat(origin)<0){
        tishi_alert("请输入服务的成本价,价格为数字");
        return false;
    }
    if(time== "" || time.length==0 || isNaN(parseInt(time)) || parseInt(time)<0){
        tishi_alert("请输入服务的施工时间");
        return false;
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
        tishi_alert("图片格式必须是："+pic_format+"，名称不能包含非法字符，大小不超过200KB。" );
        return false
    }
    if (point=="" || point.length==0 || isNaN(parseFloat(point)) || parseFloat(point)<0){
        tishi_alert("请输入产品的积分，积分是数字");
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
    $("#desc").val(serv_editor.html());
    $(e).removeAttr("onclick");
    $("#edit_serv").submit();
}

//请求加载产品或服务类别
function load_material(store_id){
    var types=$("#sale_types option:checked").val();
    var name=$("#sale_name").val();
    var url = "/stores/"+ store_id+"/products/load_material";
    var data = {
        mat_types : types,
        mat_name : name
    }
    if (types != "" || name != ""){
        request_ajax(url,data,"post")
    }else{
        tishi_alert("请选择类型或填写名称！");
    }
}


function show_mat(){
    var mats=""
    $("#add_products div").each(function(index,div){
        mats += "<li>"+$("#"+div.id+" em").html()+"<span>/"+$("#add_p"+div.id).val()+"</span></li>"
    })
    $(".seeProDiv_rWidth .srw_ul").html(mats);
    $('.mat_tab').css('display','none');
    $(".maskOne").hide();
}

function prod_delete(id,store_id){
    var url = "/stores/"+ store_id+"/products/"+ id+"/prod_delete";
    if (confirm("确定删除该产品吗？")){
        request_ajax(url,'',"post")
    }
  
}

function serve_delete(id,store_id){
    var url="/stores/"+ store_id+"/products/"+ id+"/serve_delete";
    if (confirm("确定删除该服务吗？")){
        request_ajax(url,'',"post")
    }
}

function check_revist(){
    $("#con_revist,#time_revist").attr("disabled",!$("#auto_revist")[0].checked);
    $("#auto_revist").val($("#auto_revist")[0].checked+0);
    if (!$("#auto_revist")[0].checked){
        $("#con_revist,#time_revist").val("");
    }
}

function update_status(){
    var checks = $("input:checkbox");
    var check_ids = [];
    var check_val = {};
    for(var i = 0;i<checks.length;i++){
        check_ids.push(checks[i].value);
        check_val[checks[i].value]=Number(!checks[i].checked);
    }
    if (confirm("确定这些服务不在前端显示吗")){
        $("#ids").val(check_ids.join(","));
        $("#vals").val(JSON.stringify(check_val));
        $("#update_ids").submit();
    }
   
}

function control_deduct(e){
    var display = e.checked ? "" : "none";
    $("#techin_p,#techin_t,#techin_lable").css("display",display);
    $("#is_added").val(e.checked+0);
}

function change_input(front,back){
    $(front).attr('disabled',true).val('');
    $(back).attr('disabled',false).val('0.0');
}

// 添加服务
function add_package(store_id){
    request_ajax("/stores/"+ store_id+"/products/add_package",'',"post")
}

//编辑服务
function edit_pack(store_id,id){
    prod_request(id,store_id,"edit_pack")
}

//添加或者编辑服务
function edit_package(e){
    var pattern = new RegExp("[=-]");
    var name=$("#name").val();
    var time=$("#cost_time").val();
    var pic_format =["png","gif","jpg","bmp"];
    if (name=="" || name.length==0 || pattern.test(name)){
        tishi_alert("请输入服务的名称,不能包含非法字符");
        return false;
    }
    if(time== "" || time.length==0 || isNaN(parseInt(time)) || parseInt(time)<0){
        tishi_alert("请输入服务的施工时间");
        return false;
    }
    var img_f  = false
    $(".add_img #img_div input[name$='img_url']").each(function (){
        if (this.value!="" || this.value.length!=0){
            var pic_type =this.value.substring(this.value.lastIndexOf(".")).toLowerCase();
            var img_name = this.value.substring(this.value.lastIndexOf("\\")).toLowerCase();
            var g_name = img_name.substring(1,img_name.length);
            if (pic_format.indexOf(pic_type.substring(1,pic_type.length))== -1 || pattern.test(g_name.split(".")[0])){
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
    $(e).removeAttr("onclick");
    $("#edit_serv").submit();
}

function set_value(e){
    $("input[id^='line']").attr('checked',e.checked)
}

function delete_prods(store_id){
    var checked_ids = $("input[id^='line']:checked");
    var ids = [];
    for(var i=0; i < checked_ids.length; i++){
        ids.push(checked_ids[i].value)
    }
    if (checked_ids.length == 0){
        tishi_alert("请选择删除的对象");
    }else{
        if(confirm("确认删除选中的对象吗？")){
            $.ajax({
                async:true,
                type : 'post',
                dataType : 'json',
                url : "/stores/"+ store_id+"/products/destroy_prod",
                data : {
                    ids : ids
                },
                success : function(data){
                    $(":checked").attr("checked",false);
                    tishi_alert(data.msg);
                    setTimeout(function(){
                        window.location.reload();
                    },1000)
                }
            });
        //        window.open("/customers/print_orders?ids="+ids.join(","),"_blank")
        }
    }
}