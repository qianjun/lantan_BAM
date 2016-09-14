/**
 * Created with JetBrains RubyMine.
 * User: Charles
 * Date: 13-7-11
 * Time: 下午18:33
 * To change this template use File | Settings | File Templates.
 */

function add_depot() {
    popup("#depot_form");
}

function new_depot(store_id){
    if($.trim($("#depot_name").val()).length==0){
        tishi_alert("请输入仓库名称");
    }else{
        $.ajax({
            url: "/stores/" +store_id+ "/depots/create",
            dataType: "text",
            type: "post",
            data: {
                depot_name :$.trim($("#depot_name").val())
            },
            success:function(data,status){
                tishi_alert("仓库添加成功!");
            },
            error:function(){
                tishi_alert("仓库添加失败!");
            }
        });
    }
}


function send_detailed(store_id){
    var url = "/stores/"+store_id+"/messages/send_detailed";
    var types = $("#cate_n option:selected").val();
    var first_time = $("#c_first").val();
    var last_time = $("#c_last").val();
    var data = {
        store_id:store_id,
        types:types,
        first_time : first_time,
        last_time : last_time
    }
    $("#submit_spinner,#send_search").toggle();
    request_ajax(url,data)
}