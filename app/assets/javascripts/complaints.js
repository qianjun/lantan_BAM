function choose_brand(capital_div, car_brands, car_models) {
    if ($.trim($(capital_div).val()) != "") {
        $.ajax({
            async:true,
            dataType:'json',
            data:{
                capital_id : $(capital_div).val()
            },
            url:"/customers/get_car_brands",
            type:'post',
            success : function(data) {
                if (data != null && data != undefined) {
                    $(car_brands +" option").remove();
                    $(car_brands).append("<option value=''>--</option>");
                    $(car_models +" option").remove();
                    $(car_models).append("<option value=''>--</option>");
                    for (var i=0; i<data.length; i++) {
                        $(car_brands).append("<option value='"+ data[i].id + "'>"+ data[i].name + "</option>");
                    }
                }
            }
        })
    }
}

function choose_model(car_brands, car_models) {
    if ($.trim($(car_brands).val()) != "") {
        $.ajax({
            async:true,
            dataType:'json',
            data:{
                brand_id : $(car_brands).val()
            },
            url:"/customers/get_car_models",
            type:'post',
            success : function(data) {
                if (data != null && data != undefined) {
                    $(car_models + " option").remove();
                    $(car_models).append("<option value=''>--</option>");
                    for (var i=0; i<data.length; i++) {
                        $(car_models).append("<option value='"+ data[i].id + "'>"+ data[i].name + "</option>");
                    }
                }
            }
        })
    }
}


function load_goal(url){
    var data = {
        created : $("#created").val(),
        ended : $("#ended").val(),
        time : $("input[name=time]:checked").val()
    }
    request_ajax(url,data)
}

function search_first(){
    var arr =["load_service","load_product","load_pcard"]
    var store_id = $("#store_id").val();
    load_goal("/stores/"+ store_id+"/market_manages/"+arr[parseInt($(".tab_head .hover").attr("id"))]);
}

function complaint_type(comp_type, store_id, comp_month, div_name){
    $.ajax({
        type: "get",
        url: "/stores/"+store_id+"/complaints",
        dataType: "script",
        data: {
            comp_type : comp_type,
            comp_month : comp_month,
            div_name : div_name
        },
        error: function(data){
            tishi_alert("数据错误!")
        }
    })
}

function pleased_type(plea_type, store_id, plea_start, plea_end, div_name){
    $.ajax({
        type: "get",
        url: "/stores/"+store_id+"/complaints",
        dataType: "script",
        data: {
            plea_type : plea_type,
            plea_start : plea_start,
            plea_end : plea_end,
            div_name : div_name
        },
        error: function(data){
            tishi_alert("数据错误!")
        }
    })
}

function meta_analysis_search_checkbox(obj){
    if($(obj).attr("name")=="amount_con"){
        if($(obj).attr("checked")=="checked"){
            $("#amount_con_start").removeAttr("disabled");
            $("#amount_con_end").removeAttr("disabled");
        }else{
            $("#amount_con_start").attr("disabled", "disabled");
            $("#amount_con_end").attr("disabled", "disabled");
        }
    }else if($(obj).attr("name")=="amount_date"){
        if($(obj).attr("checked")=="checked"){
            $("#amount_date_start").removeAttr("disabled");
            $("#amount_date_end").removeAttr("disabled");
        }else{
            $("#amount_date_start").attr("disabled", "disabled");
            $("#amount_date_end").attr("disabled", "disabled");
        }
    }
}
function meta_analysis_search(store_id){
    //var t = /^[0-9]*[1-9][0-9]*$/;   
    //var js_start_time = new Date(Date.parse(amount_date_start.replace("-","/")));
    //var js_end_time = new Date(Date.parse(amount_date_end.replace("-","/")));
    var amount_con_flag = $("#amount_con").attr("checked")=="checked";
    var amount_date_flag = $("#amount_date").attr("checked")=="checked";
    if(amount_con_flag==false && amount_date_flag==false){
        tishi_alert("请输入查询条件!");
    }else{
        var t = /^\d+$/;
        var amount_con_start = $.trim($("#amount_con_start").val());
        var amount_con_end = $.trim($("#amount_con_end").val());
        var amount_date_start = $.trim($("#amount_date_start").val());
        var amount_date_end = $.trim($("#amount_date_end").val());
        var flag = true;
        if(amount_con_flag==true && amount_date_flag==true){
            if(amount_con_start=="" && amount_con_end=="" && amount_date_start=="" && amount_date_end==""){
                tishi_alert("至少输入一个查询条件!");
                flag = false;
            }else if(amount_con_start != "" && t.test(amount_con_start)==false){
                tishi_alert("起始金额必须为大于等于零的整数!");
                flag = false;
            }else if(amount_con_end != "" && t.test(amount_con_end)==false){
                tishi_alert("结束金额必须为大于等于零的整数!");
                flag = false;
            }else if(parseInt(amount_con_start) > parseInt(amount_con_end)){
                tishi_alert("结束金额必须大于等于起始金额!");
                flag = false;
            }else if(amount_date_start!="" && amount_date_end!="" && amount_date_start > amount_date_end){
                tishi_alert("结束时间必须大于起始时间!");
                flag = false;
            }
        }else if(amount_con_flag==true && amount_date_flag==false){
            if(amount_con_start=="" && amount_con_end==""){
                tishi_alert("请输入起始金额或结束金额!");
                flag = false;
            }else if(amount_con_start != "" && t.test(amount_con_start)==false){
                tishi_alert("起始金额必须为大于等于零的整数!");
                flag = false;
            }else if(amount_con_end != "" && t.test(amount_con_end)==false){
                tishi_alert("结束金额必须为大于等于零的整数!");
                flag = false;
            }else if(parseInt(amount_con_start) > parseInt(amount_con_end)){
                tishi_alert("结束金额必须大于等于起始金额!");
                flag = false;
            }
        }else if(amount_con_flag==false && amount_date_flag==true){
            if(amount_date_start=="" && amount_date_end==""){
                tishi_alert("请输入查询时间!")
                flag = false;
            }else if(amount_date_start!="" && amount_date_end!="" && amount_date_start > amount_date_end){
                tishi_alert("结束时间必须大于起始时间!");
                flag = false;
            }
        }
        if(flag==true){
            $.ajax({
                type: "get",
                url: "/stores/"+store_id+"/complaints/meta_analysis",
                dataType: "script",
                data: {
                    amount_con_start : amount_con_start,
                    amount_con_end : amount_con_end,
                    amount_date_start : amount_date_start,
                    amount_date_end : amount_date_end,
                    flag : 1
                },
                error: function(data){
                    tishi_alert("数据错误!");
                }
            })
        }
    }
    

}

$(document).ready(function(){
    $("#comp_page a").live("click", function(){     //统计管理-客户-投诉 异步分页
        var url = $(this).attr("href");
        $.ajax({
            type : 'get',
            dataType : 'script',
            url : url,
            data: {
                div_name : "s_div"
            },
            error: function(data){
                tishi_alert("数据错误!")
            }
        });
        return false;
    });

    $("#plea_page a").live("click", function(){     //统计管理-客户-满意度 异步分页
        var url = $(this).attr("href");
        $.ajax({
            type : 'get',
            dataType : 'script',
            url : url,
            data: {
                div_name : "p_div"
            },
            error: function(data){
                tishi_alert("数据错误!")
            }
        });
        return false;
    });

    $("#meta_analysis_page a").live("click", function(){    //统计管理-客户-汇总分析 异步分页
        var url = $(this).attr("href");
        $.ajax({
            type : 'get',
            dataType : 'script',
            url : url,
            data: {
                flag : 1
            },
            error: function(data){
                tishi_alert("数据错误!")
            }
        });
        return false;
    })
})