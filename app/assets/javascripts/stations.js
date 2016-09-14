function collect_info(store_id,station_id){
    if (parseInt($("#t_status").val())==0){
        $.ajax({
            async:true,
            type:'post',
            dataType:'json',
            url:"/stores/"+store_id+"/stations/collect_info",
            data:{
                store_id : store_id
            },
            success : function(data) {
                $("#t_status").val(1);
                var types=["day_num","month_num"];
                for(var i=0;i<types.length;i++){
                    var month_num = data[types[i]];
                    for(var item in month_num){
                        $($("#water_"+item+" span")[i+1]).html(month_num[item][0]);
                        $($("#gas_"+item+" span")[i+1]).html(month_num[item][1]);
                        $($("#num_"+item+" span")[i+1]).html(month_num[item][2]);
                    }
                }
                $("#site_"+station_id).css("display","");
            }
        })
    }else{
        //        $("#site_"+station_id).slideToggle("slow");
        $("#site_"+station_id).css("display","");
    }

}

function request_order(order_id){
    $.ajax({
        async:true,
        type:'get',
        dataType:'script',
        url:"/orders/"+order_id+"/order_info"
    })
}

function handle_order(order_id,types){
    if (types == "complete_pay" && !confirm("请确认客户已经付款？")){
        window.location.reload();
        return false;
    }
    $.ajax({
        async:true,
        type:'post',
        dataType:'json',
        url:"/stations/handle_order",
        data :{
            order_id : order_id,
            types : types
        },
        success : function(data){
            $("#related_order_partial h1 a").trigger("click");
            tishi_alert(data.msg);
            setTimeout(function(){
                window.location.reload();
            },1000)
        }
    })
}




function drag_self(self_attr,scope,clone){
    var attrs =    {
        cursor: "move",
        cursorAt: {
            top: 25,
            left: 25
        },
        scope: scope,
        scroll: true,
        start: function(event,ui){
            var mouse_position = document.body.scrollTop+document.documentElement.scrollTop;
            $(this).data("startingScrollTop",mouse_position);
            ui.originalPosition.top -= $(this).parent().scrollTop() - mouse_position;
        },
        drag: function(event,ui){
            var st = parseInt($(this).data("startingScrollTop"));
            ui.position.top -= $(this).parent().scrollTop() - st;
        }
    }
    if(clone){
        attrs["helper"] = "clone";
    }else{
        attrs["revert"] = "invalid";
    }
    $(self_attr).draggable(attrs);
}



function station_drop(){
    $( ".station_tech" ).droppable({
        scope: 'a',
        drop: function( event, ui ) {
            var no_exist = true;
            var exist_li = $(this).find('ul').find("li");
            var station_id = $(this).find('ul').attr("id");
            if (exist_li.length >= 8){
                tishi_alert("最多支持8个技师!");
                return false;
            }
            var li = "<li id='"+ station_id+"_"+ui.draggable.attr('id')+"'><img src='"+ ui.draggable.attr('src')+"' \n\
            alt='"+ui.draggable.attr('alt') +"' id='"+ ui.draggable.attr('id')+"' ><p>"+ ui.draggable.attr('alt')+"</p></li>"
            for(var i=0; i<exist_li.length;i++){
                if (exist_li[i].id == (station_id+"_"+ui.draggable.attr('id')) ){
                    no_exist = false;
                    break
                }
            }
            if (no_exist){
                $(this).find("ul").append(li);
                drag_self(".technician li","b",false)
            }

        }
    });
}
function compelete_station(store_id){
    var ul = $(".station_tech ul");
    var url = "/stores/"+store_id+"/stations"
    var tech_infos = {};
    if(confirm("确认提交技师设定吗？")){
        for(var i=0; i<ul.length;i++){
            tech_infos[ul[i].id] = [];
            var lis = $(ul[i]).find("img");
            for(var k=0; k < lis.length; k++){
                tech_infos[ul[i].id].push(lis[k].id)
            }
        }
        if (tech_infos == {}){
            tishi_alert("请分配技师！")
            return false;
        }
        $.ajax({
            type : "post",
            url:url,
            dataType: "json",
            data: {
                infos : tech_infos
            },
            success:function(data){
                if(data.status==0){
                    tishi_alert("提交成功！")
                }else{
                    tishi_alert("提交失败，刷新后重新提交！")
                }
            }
        })
    }
    

}
//这边是工位的开始
function new_station_valid(obj){ //新建工控机验证
    var product = $("input[name='product_ids[]']:checked").length;
    var name = $("#station_name").val();
    var code = $("#station_code").val();
    if(name==""){
        tishi_alert("工控机名称不能为空!");
    }else if(code==""){
        tishi_alert("工控机编号不能为空!");
    }else if(product==0){
        tishi_alert("至少选择一个服务项目!");
    }else{
        $(obj).parents("form").submit();
    //$(obj).attr("disabled", "disabled");
    }
}

function edit_station_valid(obj){ //编辑工控机验证
    var product = $("input[name='edit_product_ids[]']:checked").length;
    var name = $("#edit_station_name").val();
    var code = $("#edit_station_code").val();
    if(name==""){
        tishi_alert("工控机名称不能为空!");
    }else if(code==""){
        tishi_alert("工控机编号不能为空!");
    }else if(product==0){
        tishi_alert("至少选择一个服务项目!");
    }else{
        $(obj).parents("form").submit();
    //$(obj).attr("disabled", "disabled");
    }
}

function handleController(obj){            //修改是否有工控机修改采集器编号可否输入
    if($(obj).attr("checked")=="checked"){
        $(".controller_input label").prepend("<span class='red'>*</span>");
        $(".controller_input input").removeAttr("disabled");
    }else{
        $(".controller_input span").remove();
        $(".controller_input input").attr("disabled", "disabled");
    }
}


