function show_hihglight(e){
    $('#'+e.id).find('span').toggleClass('highlight');
}

function on_weixin(model,object_id,e){
    $(e).parents('tr').find("#on_weixin,#off_weixin").toggle();
    $.ajax({
        async:true,
        dataType: "json",
        type: "post",
        url: "/package_cards/on_weixin",
        data: {
            model : model,
            object_id : object_id
        },
        success:function(data){
            if(data.status == 1){
                var mode =  data.change ?  "不" : ""
                e.title= mode + "在微信上推荐该套餐卡"
                e.innerHTML = mode + "推荐"
                tishi_alert("设置成功");
            }else{
                tishi_alert("设置失败，请重试！")
            }
        }
    })
}


//设置ajax请求 request_ajax(url,data,type,data_type)
function request_ajax(url){
    var data = arguments[1] ?  arguments[1] : null;
    var type = arguments[2] ?  arguments[2] : "get";
    var data_type = arguments[3] ?  arguments[3] : "script";
    $.ajax({
        type:type,
        url:url,
        dataType: data_type,
        data: data,
        success:function(data){
            eval(arguments[4])
        }
    })
}

//打印单据  收银 已付款 和主营收入使用此方法
function three_order_print(store_id){
    var print_nums = $(".di_list_l input[id*='print_']:checkbox:checked");
    if (print_nums.length <= 0){
        tishi_alert("请选择打印订单");
        return false;
    }
    var nums = [];
    var customer_id = 0;
    var suit = false;
    for(var i=0;i<print_nums.length;i++){
        nums.push(print_nums[i].value);
        if (i==0){
            customer_id = $(print_nums[i]).parent().attr("id");
        }
        if(customer_id != $(print_nums[i]).parent().attr("id")){
            suit = true
        }
    }
    if (suit){
        tishi_alert("只能打印一个客户的单据");
        return false;
    }
    window.open("/stores/"+store_id+"/set_stores/three_line_print?o_id="+nums.join(','),'_blank' ,'height=585,width=825,left=10,top=100');
}

function add_car_get_datas(type,obj, store_id){
    var ob = $(obj).val();
    if(type==0 && ob==""){
        $("#add_car_brands").html("<option value=''>--</option>");
        $("#add_car_models").html("<option value=''>--</option>");
    }else if(type==1 && ob==""){
        $("#add_car_models").html("<option value=''>--</option>");
    }else{
        var url = "/stores/"+store_id+"/customers/add_car_get_datas";
        var data = {
            type : type,
            id : ob
        }
        request_ajax(url,data)
    }
}

function recommand_prod(store_id){
    var recommand_prods = $("#recommand_prods :checkbox:checked");
    var url="/stores/"+store_id+"/micro_stores";
    var recommand_ids = [];
    if(recommand_prods.length<=0){
        tishi_alert("请选择产品！")
        return false;
    }
    if (recommand_prods.length >8){
        tishi_alert("建议推荐产品不超过8个！");
        return false;
    }
    for(var i=0;i<recommand_prods.length;i++){
        recommand_ids.push(recommand_prods[i].id)
    }
    $.ajax({
        type : "post",
        url:url,
        dataType: "json",
        data: {
            recommand_ids : recommand_ids.join(",")
        },
        success:function(data){
            if(data.status==0){
                tishi_alert("发布成功！")
            }else{
                tishi_alert("发布失败，刷新后重新提交！")
            }
        }
    })
}

function change_types(id){
    $("#types_"+id+",#change_"+id).toggle();
    $("#edit_know_"+id+",#types_know_"+id).toggle();
}

function submit_types(id,store_id){
    var types = $("#change_"+id).val();
    if (types.length<=0 || types.length >4){
        tishi_alert("建议的长度少于四个汉字");
        return false;
    }
    var url = "/stores/"+store_id+"/micro_stores/"+id;
    var data = {
        name : types
    };
    $.ajax({
        type : "put",
        url:url,
        dataType: "json",
        data: data,
        success:function(data){
            if(data.status == 0){
                $("#types_"+data.id).val(data.name);
                $("#types_"+data.id+",#change_"+data.id).toggle();
                $("#edit_know_"+data.id+",#types_know_"+data.id).toggle();
                tishi_alert("编辑成功！")
            }else{
                tishi_alert("编辑失败，刷新后重新提交！")
            }
        }
    })
}

function upload_know_img(){
    var pattern = new RegExp("[=-]")
    var pic_format =["png","gif","jpg","bmp"];
    var img_url = $("#upload_img_file")[0];
    var title = $("#title").val();
    var description = $("#description").val();
    if (img_url.value != "" || img_url.value.length != 0){
        var pic_type = img_url.value.substring(img_url.value.lastIndexOf(".")).toLowerCase();
        var img_name = img_url.value.substring(img_url.value.lastIndexOf("\\")).toLowerCase();
        var g_name = img_name.substring(1,img_name.length);
        if (pic_format.indexOf(pic_type.substring(1,pic_type.length))== -1 || pattern.test(g_name.split(".")[0]) || (img_url.files[0].size/1024).toFixed(0) > 150){
            tishi_alert("图片大小不能超过150kb!");
            return false;
        }
    }
    if(title== "" || title.length == 0 || title.length > 20){
        tishi_alert("标题不能为空，长度不超过20个字");
        return false;
    }
    if(description == "" || description.length == 0 || description.length > 30){
        tishi_alert("摘要不能为空，长度不超过20个字");
        return false;
    }
    $("#content").val(serv_editor.html());
    $("#create_know").submit();

}

function del_know(id,store_id){
    var url = "/stores/"+store_id+"/micro_stores/"+id;
    if(confirm('确定要删除该知识吗？')){
        $.ajax({
            type : "delete",
            url:url,
            dataType: "json",
            success:function(data){
                if(data.status == 0){
                    tishi_alert("删除成功！");
                    setTimeout(function(){
                        window.location.href='/stores/'+ data.store+'/micro_stores/upload_content';
                    },1500)
                }else{
                    tishi_alert("删除失败，刷新后重新提交！")
                }
            }
        })
    }
   
}


