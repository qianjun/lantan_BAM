// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(document).ready(function(){

    //查看员工绩效统计
    $(".staff_month_score_detail").click(function(){
        var id = $(this).attr("id");
        var store_id = $("#store_id").val();
        $.ajax({
            async:true,
            type : 'get',
            dataType : 'script',
            url : "/stores/"+ store_id+"/staff_manages/"+ id
        });
        return false;
    });

    //员工绩效  根据年份统计
    $("#statistics_year").live("change", function(){
        var year = $(this).val();
        var id = $(this).attr("name");
        var store_id = $("#store_id").val();
        $.ajax({
            type : 'get',
            url : "/stores/"+ store_id+"/staff_manages/get_year_staff_hart",
            data : {
                year:year,
                id : id
            },
            success: function(data){
                if(data == "no data"){
                    $("#staff_month_chart_detail").find(".tj_pic").find("#no_data").show();
                    $("#staff_month_chart_detail").find(".tj_pic").find('img').hide();
                }else{
                    $("#staff_month_chart_detail").find(".tj_pic").find('img').attr("src", data).show();
                    $("#staff_month_chart_detail").find(".tj_pic").find("#no_data").hide();
                }
            }
        });
        return false;
    });

    //按年份统计平均水平
    $("#statistics_year").change(function(){
        $(this).parents('form').submit();
        return false;
    });

});

function check_goal(e){
    var created  =$("#created").val();
    var ended =$("#ended").val();
    var types_name =[];
    if (created=="" || created.length==0 || ended=="" || ended.length==0 || ended < created ){
        tishi_alert("请选择目标销售额的起止日期，且开始日期小于结束日期");
        return false;
    }
    var carry_out =true;
    $(".popup_body_area div[id *='item']").each(function(){
        if ($(this).find("input").length==1){
            var label =$(this).find("label").html();
            var p_value = $(this).find("input").val();
            types_name.push(label)
            if (p_value==0 || p_value.length==0 || isNaN(parseFloat(p_value)) || parseFloat(p_value)<0){
                tishi_alert("请输入"+label+"的金额,且为数值");
                carry_out=false;
                return false
            }
        }else{
            var first=$(this).find("input").first().val();
            if (first!="" || first.length!=0 ){
                var second=$(this).find("input").last().val();
                if(second=="" || second.length==0 || isNaN(parseFloat(second)) || parseFloat(second)<0 ){
                    tishi_alert("请输入"+first+"的金额,且为数值");
                    carry_out=false;
                    return false;
                }
                if (types_name.indexOf(first)>=0 ){
                    tishi_alert("”"+first+"“ 已经存在，请检查");
                    carry_out=false;
                    return false;
                }
                types_name.push(first)
            }
        }
    })
    if(carry_out && confirm("目标销售额创建后不能更改，您确定创建该目标吗？")){
        $(e).removeAttr("onclick");
        $("#create_goal").submit();
    }
}
var tishi ="类别"
var num_n ="金额"
function add_div(){
    var num=$(".popup_body_area div[id *='item']");
    var  str='<div class="item position_re" id=item_'+ num.length+'>\n\
<input type="text" name="val['+num.length +']" size="12" class="input_s" value="'+tishi +'" onfocus="remove_v(this)" onblur="back_v(this)"  /> \n\
<input name="goal['+num.length +']" type="text" value="'+ num_n+'" onfocus="remove_v(this)" onblur="back_n(this)"  />\n\
<a href="javascript:void(0)" class="item_reItem" onclick="$(\'#item_'+ num.length+'\').remove();">-</a></div>';
    $(num[num.length-1]).after(str);
}

function remove_v(e){
    $(e).val("");
}

function back_v(e){
    if( e.value==""|| e.length == 0){
        e.value= tishi;
        $(e).attr("onfocus","remove_v(this)")
    }else{
        $(e).attr("onfocus","")
    }
}
function back_n(e){
    if( e.value==""|| e.length == 0){
        e.value= num_n;
        $(e).attr("onfocus","remove_v(this)")
    }else{
        $(e).attr("onfocus","")
    }
}

function return_value(){
    $('.goal_mark input').val('');
    var num=0
    $(".goal_mark div[id^='item']").each(function(){
        num +=1
        if (num>=5){
            $(this).remove();
        }
    })
}

function send_request(store_id){
    var c_time = $("#c_time").val();
    var s_time = $("#e_time").val();
    var types = $("#s_type option:selected").val();
    var condit = {};
    condit["created"] = c_time;
    condit["ended"] = s_time;
    if (c_time != "" && c_time.length !=0 && s_time != "" && s_time.length !=0){
        if (c_time > s_time){
            tishi_alert("开始日期必须小于结束日期");
            return false;
        }
    }
    if (types != "" && types.length !=0){
        condit["types"] = types;
    }
    var url ="/stores/"+store_id+"/complaints/cost_price?"
    for(var item in condit){
        url += item +"="+condit[item]+"&"
    }
    window.location.href = url
}
