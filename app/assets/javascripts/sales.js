//发布活动验证
function publish_sale(e){
    var name=$("#sale_title").val();
    var disc=$("#s_disc input[name='discount']:checked").val();
    var time=$("#s_time input[name='disc_time']:checked").val();
    var subsidy =$("#s_sub input[name='subsidy']:checked").val();
    var pic_format =["png","gif","jpg","bmp"]
    var img =$("#img_url").val();
    var pattern = new RegExp("[`~@#$^&*()=:;,\\[\\].<>?~！@#￥……&*（）|{}。，、？]")
    var pic_type =img.substring(img.lastIndexOf(".")).toLowerCase()
    if (name=="" || name.length==0 || pattern.test(name)){
        tishi_alert("请输入本次活动的标题,不能包含非法字符")
        return false;
    }
    if($("#add_products").children().length == 0){
        tishi_alert("请选择产品或服务");
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
    if (disc == undefined){
        tishi_alert("请选择优惠类型");
        return false;
    }
    if (parseInt(disc)==1 && ($("#disc_"+disc).val().length==0 || isNaN(parseFloat($("#disc_"+disc).val())) || parseFloat($("#disc_"+disc).val())<0 )){
        tishi_alert("请填写优惠的金额，且为数字");
        return false;
    }
    if (parseInt(disc)==0 && ($("#disc_"+disc).val().length==0 || isNaN(parseFloat($("#disc_"+disc).val())) || parseFloat($("#disc_"+disc).val())<0 || parseFloat($("#disc_"+disc).val()) > 10 )){
        tishi_alert("请填写打折的折扣,且为数字，折扣额度为0到10之间");
        return false;
    }
    if (time == undefined){
        tishi_alert("请选择时间的类型")
        return false;
    }
    if (parseInt(time)==0 && ($("#started_at").val().length == 0 || $("#ended_at").val().length == 0 || $("#started_at").val() > $("#ended_at").val())){
        tishi_alert("请输入活动开始和结束的时间,且开始日期小于结束日期");
        return false;
    }
    var disc_times = $("#disc_times").val();
    if ( disc_times == " " || disc_times.length ==0 || isNaN(parseInt(disc_times)) || parseInt(disc_times)<0){
        tishi_alert("请输入优惠次数");
        return false;
    }
    var car_nums = $("#disc_car_nums").val();
    if ( car_nums == " " || car_nums.length==0 || isNaN(parseInt(car_nums))||parseInt(car_nums)<0){
        tishi_alert("请输入参加活动的总车辆数");
        return false;
    }
    if (subsidy == undefined){
        tishi_alert("请选择是否需要总店补贴")
        return false;
    }
    Array.prototype.indexOf=function(el, index){
        var n = this.length>>>0, i = ~~index;
        if(i < 0) i += n;
        for(; i < n; i++) if(i in this && this[i] === el) return i;
        return -1;
    }
    //    if ((img != "" || img.length !=0) && pic_format.indexOf(pic_type.substring(1,pic_type.length))== -1){
    //        tishi_alert("请选择正确格式的图片,正确格式是："+pic_format )
    //        return false;
    //    }
    var img_name = img.substring(img.lastIndexOf("\\")).toLowerCase();
    var g_name = img_name.substring(1,img_name.length);
    if ((img != "" || img.length !=0) && pattern.test(g_name.split(".")[0])){
        tishi_alert("图片名称不能包含特殊字符")
        return false;
    }
    if (parseInt(subsidy)==1 && $("#sub_content").val().length == 0){
        tishi_alert("请输入补贴金额");
        return false;
    }

    $("#intro").val(editor.html());
    $("#one_sale").submit();
    $(e).removeAttr("onclick");
}

function input_time(){
    if ($("#is_checked")[0].checked){
        $("#started_at,#ended_at").removeAttr("disabled");
    }else{
        $("#started_at,#ended_at").val("").attr("disabled","");
    }
}

function delete_sale(store_id){
    var checked_ids = $("input[id^='line']:checked");
    var ids = [];
    for(var i=0; i < checked_ids.length; i++){
        ids.push(checked_ids[i].value)
    }
    if (checked_ids.length == 0){
        tishi_alert("请选择删除的活动");
    }else{
        if(confirm("确认删除选中的活动吗？")){
            $.ajax({
                async:true,
                type : 'post',
                dataType : 'json',
                url : "/stores/"+ store_id+"/sales/delete_sale",
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

function public_sale(sale_id,store_id){
    if(confirm("确定要发布这项活动吗？")){
        $.ajax({
            async:true,
            type : 'post',
            dataType : 'json',
            url : "/stores/"+ store_id+"/sales/public_sale",
            data : {
                sale_id : sale_id
            },
            success:function(data){
                tishi_alert(data.message);
                setTimeout(function(){
                    window.location.reload();
                },1000)
            }
        });
    }
}

//向活动加载产品或服务类别
function load_types(store_id){
    var types=$("#sale_types option:checked").val();
    var name=$("#sale_name").val();
    var url = "/stores/"+ store_id+"/sales/load_types";
    var data = {
        sale_types : types,
        sale_name : name
    }
    if (types != "" || name != ""){
        request_ajax(url,data,"post")
    }
    else{
        tishi_alert("请选择类型或填写名称！");
    }
}

//为套餐卡加载产品和服务
function pcard_types(store_id){
    var types=$("#t_prod #sale_types option:checked").val();
    var name=$("#t_prod #sale_name").val();
    var url = "/stores/"+ store_id+"/package_cards/pcard_types";
    var data = {
        sale_types : types,
        sale_name : name
    }
    if (types != "" || name != ""){
        request_ajax(url,data,"post");
    }else{
        tishi_alert("请选择类型或填写名称！");
    }
}

//添加套餐卡
function add_pcard(store_id){
    var url = "/stores/"+ store_id+"/package_cards/add_pcard";
    request_ajax(url,'',"post");
}

//编辑套餐卡
function edit_pcard(id,store_id){
    var url = "/stores/"+store_id+"/package_cards/"+ id+"/edit_pcard";
    request_ajax(url,'',"post");
}
function check_add(e){
    var name=$("#name").val();
    var base=$("#price").val();
    var end_time = $("#end_time").val();
    var point =$("#prod_point").val();
    var pattern = new RegExp("[`~@#$^&*()=:;,\\[\\].<>?~！@#￥……&*（）——|{}。，、？-]")
    var p_types = $("#material_types option:checked").val();
    if (p_types != undefined &&  p_types != "" && p_types.length !=0){
        var m_num = $("#material_num").val();
        if (m_num =="" || m_num.length==0 || isNaN(parseInt(m_num))||parseInt(m_num)<0){
            tishi_alert("请输入物料数量");
            return false;
        }
    }
    if (name=="" || name.length==0 || pattern.test(name)){
        tishi_alert("请输入套餐卡的名称,不能包含非法字符");
        return false;
    }
    if(base == "" || base.length==0 || isNaN(parseFloat(base)) || parseFloat(base)<0){
        tishi_alert("请输入套餐卡的价格");
        return false;
    }
    if (point=="" || point.length==0 || isNaN(parseFloat(point))||parseFloat(point)<0){
        tishi_alert("请输入产品的积分，积分是数字");
        return false;
    }
    if($("[name='time_select']:checked").val()==$("#date1").val()){
        if ( ($("#started_at").val().length == 0 || $("#ended_at").val().length == 0)){
            tishi_alert("请输入套餐卡有效时间和失效时间");
            return false;
        }
        if ( ($("#started_at").val() > $("#ended_at").val())){
            tishi_alert("套餐卡有效时间不能大于失效时间");
            return false;
        }
    }else{
        if(end_time == "" || end_time.length==0 || isNaN(parseFloat(end_time)||parseFloat(end_time)<=0||parseFloat(end_time)>10000)){
            tishi_alert("请输入套餐卡的有效时长，1-10000");
            return false;
        }
    }

    if($("#auto_revist")[0].checked){
        var time_revist =$("#time_revist option:selected").val();
        var con_revist =$("#con_revist").val();
        if (time_revist =="" || time_revist.length==0 || isNaN(parseFloat(time_revist))||parseFloat(time_revist)<0){
            tishi_alert("请选择回访的时长，时长是数字");
            return false;
        }
        if (con_revist =="" || con_revist.length==0){
            tishi_alert("请输入回访的内容");
            return false;
        }
    }
    if($("#auto_warn")[0].checked){
        var time_revist =$("#time_warn").val();
        var con_revist =$("#con_warn").val();
        if (time_revist =="" || time_revist.length==0 || isNaN(parseFloat(time_revist))){
            tishi_alert("请输入提醒的天数");
            return false;
        }
        if (con_revist =="" || con_revist.length==0){
            tishi_alert("请输入提醒的内容");
            return false;
        }
    }
    if($("#add_products").children().length == 0){
        tishi_alert("请选择产品或服务");
        return false;
    }
    var is_num=false
    $("#add_products .addre_input").each(function(){
        if(isNaN(parseInt(this.value)) || parseInt(this.value)<=0){
            is_num=true
        }
    })
    if (is_num){
        tishi_alert("产品或服务的数量必须大于1");
        return false;
    }
    Array.prototype.indexOf=function(el, index){
        var n = this.length>>>0, i = ~~index;
        if(i < 0) i += n;
        for(; i < n; i++) if(i in this && this[i] === el) return i;
        return -1;
    }
    var img =$("#sale_img").val();
    var pic_format =["png","gif","jpg","bmp"]
    var img_name = img.substring(img.lastIndexOf("\\")).toLowerCase();
    var pic_type =img.substring(img.lastIndexOf(".")).toLowerCase()
    if ((img != "" || img.length !=0) && (pic_format.indexOf(pic_type.substring(1,pic_type.length))== -1 || set_default_to_pic($("#sale_img")[0]))){
        tishi_alert("图片大小不超过200KB,格式必须是："+pic_format )
        return false;
    } 
    var g_name = img_name.substring(1,img_name.length);
    if ((img != "" || img.length !=0) && pattern.test(g_name.split(".")[0])){
        tishi_alert("图片名称不能包含特殊字符");
        return false;
    }
    $("#add_pcard").submit();
    $(e).removeAttr("onclick");
}

//删除套餐卡
function delete_pcard(store_id){
    var checked_ids = $("input[id^='line']:checked");
    var ids = [];
    for(var i=0; i < checked_ids.length; i++){
        ids.push(checked_ids[i].value)
    }
    if (checked_ids.length == 0){
        tishi_alert("请选择删除的套餐卡");
    }else{
        if(confirm("确认删除选中的套餐卡吗？")){
            $.ajax({
                async:true,
                type : 'post',
                dataType : 'json',
                url : "/stores/"+ store_id+"/package_cards/delete_pcard",
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

function check_station(){
    var status =true;
    var stations =[];
    $("select[name^=select]").each(function(){
        var station_id =$("#stat"+this.id.split("_")[1]+" option:selected").val();
        if(parseInt(station_id)==$("#station_id").val() && $(this).find("option:selected").val()== "0" 　){
            tishi_alert("工位状态正常的必须设置技师");
            status=false;
            return false;
        }
        if (parseInt(station_id)==$("#station_id").val()){
            stations.push([$(this).find("option:selected").html(),$(this).find("option:selected").val()]);
        }
    })
    if(status){
        for(var n=0;n< stations.length-1;n +=2){
            if (stations[n][0]==stations[n+1][0] && stations[n][1]==stations[n+1][1] ){
                tishi_alert("同一个工位必须设置不同的技师");
                status=false;
                return false;
            }
        }
        var nary=stations.sort();
        for(var i=0;i<nary.length-1;i++){
            if (nary[i][0]==nary[i+1][0] && nary[i][1]==nary[i+1][1] ){
                if (!confirm("技师重复使用："+nary[i][0])){
                    status=false;
                    return false;
                }
            }
        }
    }
    if(status){
        $("#change_station").submit();
    }
}

function show_pic(){
    var y = 50;
    var doc_width = $(document).width();
    $("#img_url,#sale_img").mouseover(function(){
        $(this).parent().find("#card_pic").css("display","block");
    }).mouseout(function(){
        $(this).parent().find("#card_pic").css("display","none");
    }).mousemove(function(e){
        var left = e.pageX-(doc_width-$(".add_tab").width())/2
        if ($(".add_tab").length==0){
            left=e.pageX;
            y=e.pageY;
        }
        $(this).parent().find("#card_pic").css({
            "top":y+"px",
            "left":left+"px"
        })
    })
}

function check_revist(e){
    $("#con_"+e.alt+",#time_"+e.alt).attr("disabled",!e.checked);
    e.value = e.checked+0;
    if (!e.checked){
        $("#con_"+e.alt+",#time_"+e.alt).val("");
    }
}


function request_material(store_id){
    var p_types = $("#pcard_material option:checked").val();
    if (p_types != "" || p_types.length !=0){
        $.ajax({
            async:true,
            type : 'post',
            dataType : 'json',
            url : "/stores/"+ store_id+"/package_cards/"+ p_types+"/request_material",
            success :function(data){
                $("#material_types").html("<option value=''>请选择</option>")
                for(var item in data){
                    $("#material_types").append("<option value='"+item +"'>"+data[item] +"</option>")
                }
                var types = $("#m_types").val();
                if (types != "" || types.length !=0){
                    $("#material_types option[value='"+types+"']").attr("selected",true);
                } 
            }
        });
    }else{
        $("#material_types").html("");
        $("#material_num").html("").attr("disabled",true);
    }
}
function control_input(){
    var p_types = $("#material_types option:checked").val();
    if (p_types != "" || p_types.length !=0){
        $("#material_num").attr("disabled",false);
        $("#name").val($("#material_types option:checked").html());
    }else{
        $("#material_num").attr("disabled",true);
    }
}

function change_input(front,back){
    $(front).attr('disabled',true).val('');
    $(back).attr('disabled',false).val('0.0');
}

function set_value(e){
    $("input[id^='line']").attr('checked',e.checked)
}

function cal_price(update_id){
    var price = 0;
    $("#add_products div").each(function(){
        var prod_price = parseInt($.trim($(this).find("#prod_price").val()));
        var num = parseFloat($.trim($(this).find(":text").val()));
        price += prod_price *num
    })
    $(update_id).val(price.toFixed(2));
}