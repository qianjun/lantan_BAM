function search_check_materials(store_id,parm,action){
    var parms = parm.split(";");
    var agvs = {};
    for(var i=0;i<parms.length;i++){
        agvs[parms[i].substr(1)] = get_value(parms[i]);
    }
    $("#check_btn,#spinner_user").toggle();
    var url = "/stores/"+ store_id+action
    request_ajax(url,agvs)
}

//目前仅支持input，checkbox和select
function get_value(obj){
    var type = $(obj)[0].type;
    if(type == "text"){
        return $(obj).val();
    }
    if(type == "select-one"){
        return $(obj+" option:selected").val();
    }
    if(type== "checkbox"){
        return $(obj).val();
    }
}

function submit_check(store_id){
    var check_records = $(".pandian_list input:checked");
    var check_status = $("#check_status option:selected").val();
    var records = {};
    if (check_records.length == 0){
        tishi_alert("请选择核实物料");
        return false;
    }else{
        for(var i=0;i<check_records.length;i++){
            var storage = $(check_records[i]).parent().parent().find(".su").html();
            var check_num = $(check_records[i]).parent().parent().find(".check_num").html();
            var remark = $(check_records[i]).parent().parent().find(".remark").html();
            records[check_records[i].value] = {
                storage : storage,
                check_num : check_num,
                remark : remark
            }
        }
        if(records != {}){
            if(confirm("确认提交核对吗？")){
                $("#check_btns,#spinner_user1").toggle();
                var url = "/stores/"+ store_id+"/check_materials/submit_check"
                var data ={
                    records :records,
                    check_status : check_status
                }
                request_ajax(url,data,"post")
            }
        }
    }
}

function submit_xls(store_id,check_ids){
    var url= "/stores/"+ store_id+"/check_materials/submit_xls";
    var data = {
        check_ids :check_ids
    }
    request_ajax(url,data,"post")
}