function edit_store_validate(obj){
    var flag = true;
    if($("#store_city").val()==0){
        tishi_alert("请选择门店所属城市!");
        flag = false;
    }
    if($.trim($("#store_name").val()) == "" || $.trim($("#store_name").val()) == null){
        tishi_alert("请输入门店名称!");
        flag = false;
    };
    if($.trim($("#store_contact").val()) == "" || $.trim($("#store_contact").val()) == null){
        tishi_alert("请输入负责人名称!");
        flag = false;
    };
    if($.trim($("#store_phone").val()) == "" || $.trim($("#store_phone").val()) == null){
        tishi_alert("请输入联系电话号码!");
        flag = false;
    };
    if($.trim($("#store_address").val()) == "" || $.trim($("#store_address").val()) == null){
        tishi_alert("请输入门店地址!");
        flag = false;
    };
    if($.trim($("#store_opened_at").val()) == "" || $.trim($("#store_opened_at").val()) == null){
        tishi_alert("请选择开店时间!");
        flag = false;
    };
    if($.trim($("#store_position_x").val()) == null || $.trim($("#store_position_x").val()) == "" || $.trim($("#store_position_y").val()) == null || $.trim($("#store_position_y").val()) == ""){
        tishi_alert("请输入门店坐标!");
        flag = false;
    };
    if(flag){
        $(obj).parents("form").submit();
        $(obj).removeAttr("onclick");
    }
}

function select_city(province_id,store_id){
    if(province_id==0){
        $("#store_city").html("<option value='0'>------</option>")
    }else{
        $.ajax({
            type: "get",
            url: "/stores/"+store_id+"/set_stores/select_cities",
            dataType: "script",
            data: {
                p_id : province_id
            }
        })
    }
}

function load_register(store_id){
    var url = "/stores/"+store_id+"/set_stores/cash_register";
    $("#cash_refresh").removeAttr("onclick");
    var time = 60;
    var local_timer=setInterval(function(){
        $("#cash_refresh").html("刷新("+time+")");
        if (time <=0){
            $("#cash_refresh").attr("onclick","load_register("+store_id+")");
            window.clearInterval(local_timer);
            $("#cash_refresh").html("刷新")
        }
        time -= 1;
    },1000)
    request_ajax(url)
}

function load_search(store_id){
    var c_time = $("#c_first").val();
    var s_time = $("#c_last").val();
    var c_num = $("#c_num").val();
    var url = "/stores/"+store_id+"/set_stores/complete_pay";
    var data = {
        first : c_time,
        last : s_time,
        c_num : c_num
    }
    if (c_time != "" && c_time.length !=0 && s_time != "" && s_time.length !=0){
        if (c_time > s_time){
            tishi_alert("开始时间必须小于结束时间");
            return false;
        }
    }
    request_ajax(url,data)
}

function show_current(e){
    $("div[id*='page_']").css("display",'none');
    $("#page_"+e.id).css("display",'');
    var em = $(e).parent().find("em");
    var a = "<a id='"+ em[0].id+"' onclick='show_current(this)' href='javascript:void(0)'>"+(parseInt(em[0].id)+1)+"</a>"
    var b_em = "<em id='"+e.id+"' class='current'>"+(parseInt(e.id)+1)+"</em>"
    em.replaceWith(a);
    $(e).replaceWith(b_em);
}

function pay_this_order(store_id,c_id,n_id){
    var url = "/stores/"+store_id+"/set_stores/load_order"
    var data = {
        customer_id : c_id,
        car_num_id : n_id
    }
    request_ajax(url,data,"post")
}



function check_sum(card_id,e){
    $("#order_"+card_id+",#pwd_"+card_id).attr("disabled",!e.checked);
    if (!e.checked){
        $("#order_"+card_id).val(0);
        check_num();
    }
}

function limit_float(num){
    var t_num = parseInt(parseFloat(num)*100);
    return  round((t_num%10 == 0 ? t_num : t_num-5)/100.0,2);
}


function check_num(){
    var total = 0;
    var due_pay = round($.trim($("#due_pay").html()),4);
    $("#due_over").css("display","none");
    //    $('div.at_way_b > div').find("input[id*='cash_'],input[id*='change_']").val(0);//当调动其他选项则清零付款方式的输入框，也可以选择重新计算

    $("input[id*='order_']").each(function(){
        var left_price = round($.trim($("#left_"+this.id.split("_")[1]).html()),2);
        var price = round($.trim(this.value),2)
        var this_value = 0;
        if (!isNaN($.trim(this.value)) && price > 0){
            if (left_price < price){
                this_value = left_price;
            }else{
                this_value = price;
            }
        }
        this.value = this_value;
        total = round(total+this_value,2);
    })
    if ( due_pay < total){
        tishi_alert("付款额度超过应付金额额度！");
        $("#total_pay").html(0);
        $("#left_pay,#due_money").html(round(due_pay,2));
        $("#due_over").css("display","none");
        return false;
    }else{
        $("#total_pay").html(round(total,2));
        $("#left_pay,#due_money").html(round(due_pay-total,2));
        if (due_pay == total){
            $("#due_over").css("display","block");
        }
    }
    var pay_type = $("#pay_type li[class='hover']").attr("id");
    calulate_v(pay_type);
    return true;
}

//可以付款功能
function check_post(store_id,c_id,n_id){
    if (!check_num()){ //判断储值卡的金额是否符合
        return false;
    }
    var url = "/stores/"+store_id+"/set_stores/pay_order"
    var pay_order = set_pay_order();
    if (pay_order[0]){
        tishi_alert("储值卡密码不能为空");
        return false;
    }else{
        var time = 5;
        var local_timer=setInterval(function(){
            if (time <=0){
                $("#due_over").attr("onclick","check_post("+store_id+","+c_id+","+n_id+")");
                window.clearInterval(local_timer);
            }
            time -= 1;
        },1000)
        $("#due_over").attr("onclick","");
        var data = {
            customer_id : c_id,
            car_num_id : n_id,
            pay_order : pay_order[1]
        }
        request_ajax(url,data,"post")
    }
}

//获取退单，优惠，储值卡和抹零和打印发票的数据
function set_pay_order(){
    var pay_order = {};
    var loss = $("#input_loss").css("display");
    var turn = $("#return_order").css("display");
    if (turn == "block"){
        var return_ids = []
        $(".at_client_con  td input:checkbox").each(function(){
            if(this.checked){
                return_ids.push(this.id.split("_")[1]);
            }
        })
        if (return_ids != []){
            pay_order["return_ids"] = return_ids;
        }
    }
    if (loss == "block"){
        var loss_ids = {};
        var reasons = {};
        $(".at_client_con  td input[id*='in_']").each(function(){
            if (round($.trim(this.value),2)>0){
                loss_ids[this.id.split("_")[1]]= round($.trim(this.value),2);
                reasons[this.id.split("_")[1]] = $("#reason_"+this.id.split("_")[1] +" input").val();
            }
            if (!set_reward(this)){ //判断优惠额度是否符合
                return false;
            }
        })
        if(loss_ids != {}){
            pay_order["loss_ids"] = loss_ids;
            pay_order["loss_reason"] = reasons;
        }
    }
    var is_password = false;
    if ($("#sv_card_used input:not(:disabled):text").length>0){
        var text = {};
        $("#sv_card_used input:not(:disabled):text").each(function(){
            var pwd = $.trim($("#pwd_"+this.id.split("_")[1]).val());
            if(pwd == "" || pwd.length ==0){
                is_password = true;
            }else{
                if (round($.trim(this.value),2) > 0 ){
                    text[this.id.split("_")[1]] = round($.trim(this.value),2);
                    pay_order[this.id.split("_")[1]] = pwd;
                }
            }
        })
        if (text != {} ){
            pay_order["text"] = text;
        }
    }
    var clear_value = round($.trim($("#clear_value").val()),2);
    if (clear_value > 0){
        pay_order["clear_value"] = clear_value;
    }
    pay_order["is_billing"] = $("#is_biling")[0].checked ? 1 : 0;
    return [is_password,pay_order]
}


function change_order(store_id){
    var c_n = $("#customer_orders option:selected").first().attr("id").split("_");
    $("#discount").val(0);
    pay_this_order(store_id,c_n[0],c_n[1])
}

function change_pay(e){
    var due_pay = round($.trim($("#hidden_pay").html()),4);
    var left_pay = round($.trim($("#left_pay").html()),4);
    if(e.checked){
        $("#due_pay").html(due_pay-due_pay%10);
        $("#left_pay,#due_money").html(round(left_pay-due_pay%10),2);
        if (due_pay%10 >0){
            $("#clear_value").val(due_pay%10);
        }
    }else{
        $("#due_pay").html(due_pay);
        $("#left_pay,#due_money").html(round(left_pay+round($.trim($("#hidden_pay").html()))%10,4),2);
        $("#clear_value").val(0);
    }
    check_num();
}

function show_loss(obj_id){
    if (obj_id == "input"){
        $("thead #code_num,tbody #code_num").css("display",'none');
        $(".at_client_con table td[id*='reason']").css("display",'');
    }
    $(".at_client_con table td[id*='"+obj_id+"']").css("display",'block');
    if (obj_id == "input" && "block" == $("#return_order").css("display")){
        $(".at_client_con table td[id*='"+obj_id+"']").each(function(){
            if ($(this).attr("class")!='hbg'){
                this.disabled = $(this).find("checkbox").attr("checked");
            }
        })
    }
}

function return_check(e){
    var clear_per = $("#clear_per")[0];
    var hidden_pay = round($.trim($("#hidden_pay").html()),4);
    var total = round($.trim( $("#loss_"+e.id.split("_")[1]).val()),4);
    var cards = $("#sv_card_used span[id*='"+e.id.split("_")[1] +"_']").find(":checkbox");
    clear_per.checked = false;
    if (e.checked){
        $(e).parent().siblings().css("background","#ebebe3");
        $("#due_pay").html(round(hidden_pay-total,2));
        $("#left_pay,#due_money").html(round(hidden_pay-total,2));
        if (hidden_pay==total){
            clear_per.disabled = true;
        }
        $("#hidden_pay").html(round(hidden_pay-total,2));
        var  this_value = $("#in_"+e.id.split("_")[1]).val(0).attr("disabled",true);
        set_reward(this_value[0])
        if (cards.length >0){
            var card_check = cards[0];
            var card_id = card_check.id.split("_")[1];
            card_check.checked = false
            card_check.disabled = true
            $("#order_"+card_id+",#pwd_"+card_id).attr("disabled",e.checked);
            check_num();
        }
    }else{
        $(e).parent().siblings().css("background","");
        $("#due_pay").html(round(hidden_pay+total,2));
        $("#left_pay,#due_money").html(round(hidden_pay+total,2));
        $("#hidden_pay").html(round(hidden_pay+total,2));
        $("#in_"+e.id.split("_")[1]).attr("disabled",false);
        if ((hidden_pay+total)>0){
            clear_per.disabled = false;
        }
        if (cards.length >0){
            cards[0].disabled = false;
        }
    }
//    change_pay(clear_per);
}

function set_reward(e){
    var clear_per = $("#clear_per")[0];
    var hidden_pay = round($.trim($("#hidden_pay").html()),4);
    var still_pay = round($.trim($("#hipay_"+e.id.split("_")[1]).val()),4);
    var loss = round($.trim($("#loss_"+e.id.split("_")[1]).val()),4);
    var this_value = 0 ;
    var  price = round($.trim(e.value),2);
    if (!isNaN(price) && price > 0){
        this_value = price;
    }
    e.value = this_value;
    clear_per.checked = false;
    if (this_value > loss){
        tishi_alert("优惠金额超过本单金额！");
        return false;
    }
    else{
        $("#hipay_"+e.id.split("_")[1]).val(round(this_value,2));
        $("#due_pay").html(round(hidden_pay+still_pay-this_value,2));
        $("#left_pay,#due_money").html(round(hidden_pay+still_pay-this_value,2));
        $("#hidden_pay").html(round(hidden_pay+still_pay-this_value,2));
        if ((hidden_pay+still_pay-this_value)<= 10){
            clear_per.disabled = true;
        }else{
            clear_per.disabled = false;
        }
        check_num();
        return true;
    //        change_pay(clear_per);
    }
}

function set_change(pay_type){
    var pay_cash = round($.trim($("#cash_"+pay_type).val()),4);
    var left_pay = round($.trim($("#left_pay").html()),4);
    $("#change_"+pay_type).val(0);
    if (isNaN(pay_cash) || pay_cash <0){
        $("#cash_"+pay_type).val(0);
        return false;
    }else{
        $("#cash_"+pay_type).val(pay_cash);
        if(left_pay > pay_cash){
            tishi_alert("实收金额不足！");
            return false;
        }else{
            $("#change_"+pay_type).val(round(pay_cash-left_pay,2));
            return true;
        }
    }
}

function set_card(pay_type){
    var pay_cash = round($.trim($("#cash_"+pay_type).val()),2);
    var left_pay = round($.trim($("#left_pay").html()),4);
    if (isNaN(pay_cash) || pay_cash < 0){
        pay_cash = 0;
    }
    $("#cash_"+pay_type).val(pay_cash);
    if(left_pay > pay_cash){
        tishi_alert("实收金额不足！");
        return false;
    }else{
        return true;
    }
}

function confirm_pay_order(store_id,c_id,n_id){
    var left_pay = round($.trim($("#left_pay").html()),2);
    var pay_order = set_pay_order();
    if (!check_num()){ //判断储值卡的金额是否符合
        return false;
    }
    if (left_pay == 0 && $("#due_over").css("display")=="block"){
        tishi_alert("快捷支付可用");
        return false;
    }else{
        var pay_type = $("#pay_type li[class='hover']").attr("id");
        var second_parm = "";
        var pay_cash = round($.trim($("#cash_"+pay_type).val()),2);
        if(parseInt(pay_type) == 0){   //如果使用现金支付
            if (!set_change(pay_type)){
                tishi_alert("实收金额不足！");
                return false;
            }
            second_parm = round($.trim($("#change_"+pay_type).val()),2);
        }
        if(parseInt(pay_type) == 1){   //如果使用刷卡支付
            set_card(pay_type);
            second_parm = $.trim($("#c_set_"+pay_type).val());
        }
        if(parseInt(pay_type) == 5){
            var pay_cash =$.trim($("#cash_"+pay_type).val());
            if (pay_cash == "" || pay_cash.length ==0 || pay_cash.length <0){
                tishi_alert("请求验证权限！");
                return false;
            }
        }
        if(parseInt(pay_type) == 9){   //如果使用挂账支付
            pay_cash = left_pay;
        }
        if (pay_order[0]){
            tishi_alert("储值卡密码不能为空");
            return false;
        }else{
            var t_data ={
                customer_id : c_id,
                car_num_id : n_id,
                pay_order : pay_order[1],
                pay_type : pay_type,
                pay_cash : pay_cash,
                second_parm : second_parm,
                show_btn : 1
            }
            $("#confirm_order,#spinner_user").toggle();
            var url = "/stores/"+store_id+"/set_stores/pay_order";
            request_ajax(url,t_data,"post","script");
        }
    }
}


function single_order_print(store_id){
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
        tishi_alert("只能打印一个客户的小票");
        return false;
    }
    window.open("/stores/"+store_id+"/set_stores/single_print?order_id="+nums.join(','),'_blank', 'height=520,width=625,left=10,top=100');
}



function calulate_v(pay_type){
    if (parseInt(pay_type) == 0){
        var pay_cash = round($.trim($("#cash_"+pay_type).val()),4);
        var left_pay = round($.trim($("#left_pay").html()),4);
        var  v = round(pay_cash>left_pay ? pay_cash-left_pay : 0,2);
        $("#cash_"+pay_type).val(pay_cash)
        $("#change_"+pay_type).val(v);
    }
}

function edit_id_svcard(store_id,card_id){
    var url = "/stores/"+store_id+"/set_stores/edit_svcard";
    var number = $("#id_card").val();
    var pattern = new RegExp("[0-9]")
    if(number =="" || number.length <7 || !pattern.test(number)){
        $(".tab_alert").css("z-index",121);
        tishi_alert("卡号至少为八位数字");
        return false;
    }else{
        $.ajax({
            type:"post",
            url:url,
            dataType: "json",
            data: {
                card_id : card_id,
                number : number
            },
            success : function(data){
                $("#svc_"+data.card_id).html(data.number);
                $("#edit_card .close").trigger("click");
                tishi_alert("修改成功！");
            }
        })
    }
    
}

function show_edit(store_id,card_id){
    $("#id_card").val($("#svc_"+card_id).html());
    $("#confirm_card").attr("onclick","edit_id_svcard("+store_id+","+card_id+")");
    before_center("#edit_card");
    $("#id_card").focus();
}

function auth_car_num(e,store_id){
    var old_c = $("#old_customer").val();
    if(e.value !=""  && old_c != e.value && e.value.length == 7){
        $("#submit_item,#submit_spinner").toggle();
        var url = "/stores/"+store_id+"/set_stores/search_info";
        var data ={
            car_num : e.value
        }
        request_ajax(url,data,"post")
    }else{
        if($.trim(e.value) !="" && $.trim(e.value) != "无牌" && $.trim(e.value).length != 7 ){
            tishi_alert("车牌有误！");
        }
        $("#bill_user_info input").removeAttr("readonly");
    }
}

function search_item(store_id){
    var item_id = $("#search_item .hover")[0].id;
    var item_name = $("#search_item #item_name").val();
    var checked_item = $("#checked_item").val();
    var url = "/stores/"+store_id+"/set_stores/search_item";
    var data ={
        item_id : item_id,
        item_name : item_name,
        checked_item : checked_item.split(",")
    }
    $("#spinner_user,#item_btn").toggle();
    request_ajax(url,data,"post")
}


function show_div(e){
    $(".card").css("display","none");
    $("#div_"+e.id).css("display","block");
    $(e).addClass('hover').siblings().removeClass('hover')
}

function add_cart(e){
    var price = $(e).parent().find("#price").html();
    var total_price = $("#total_price").html();
    var storage = $(e).parent().find("#storage").html();
    var name = $(e).parent().find("#name").html()
    put_add(e,e.id,storage,name,total_price,price);
}


function add_num(e){
    var max = $(e).parent().parent().eq(0).attr("class");
    var num = $(e).parent().find("input").val();
    var single_price = $(e).parent().parent().find("#price").html(); //单价
    var total_price = $("#total_price").html();
    if (parseInt(max) > parseInt(num)){
        $(e).parent().find("input").val(parseInt(num)+1);
        alert(single_price);
        alert(parseInt(num)+1);
        $(e).parent().parent().find("#t_price").html(change_dot(single_price*(parseInt(num)+1))); //小计价格
        $("#total_price").html(change_dot(round(total_price,2)+round(single_price,2),2)); //设置总价
        if (parseInt(max) == (parseInt(num)+1)){
            e.title = "最大可购买数量";
        }
    }else{
        e.title = "最大可购买数量";
    }
}

function del_num(e){
    var num = $(e).parent().find("input").val();
    var single_price = $(e).parent().parent().find("#price").html(); //单价
    var total_price = $("#total_price").html();
    if (parseInt(num) > 1 ){
        $(e).parent().find("input").val(parseInt(num)-1);
        $(e).parent().parent().find("#t_price").html(change_dot(single_price*(parseInt(num)-1))); //小计价格
        $("#total_price").html(change_dot(round(total_price,2)-round(single_price,2),2)); //设置总价
        if (parseInt(num)==2){
            e.title = "最小购买数量：1";
        }
    }else{
        e.title = "最小购买数量：1";
    }
}

function add_prod(e){
    var price_storage = e.value;
    var price = price_storage.split("_")[0];
    var storage = price_storage.split("_")[1];
    var total_price = $("#total_price").html();
    var e_id = $(e).parent().parent().attr("id");
    var name = $(e).parent().parent().find("td").eq(0).html();
    put_add(e,e_id,storage,name,total_price,price);
}


function put_add(e,e_id,storage,name,total_price,price){
    if(e.checked){
        var total_item = $("#checked_item").val();
        var  total = total_item.split(",");
        if (total_item == "" || total_item.length ==0){
            $("#checked_item").val(e_id);
            add_item(e_id,storage,name,total_price,price);
        }
        else{
            var  is_new = true;
            var same_id = e_id;
            var pid = e_id.split("_");
            if ( parseInt(pid[1]) == 4 || parseInt(pid[1]) == 5 || parseInt(pid[1]) == 6){ //当下单为产品，服务和打折卡下单时判断是不是已经存在
                for(var i=0;  i < total.length;i++){
                    var d_t = total[i].split("_");
                    if(pid[2] == d_t[2] && parseInt(d_t[1]) != 3){
                        is_new = false;
                        e_id = total[i];
                    }
                }
            }
            if (is_new){
                total.push(e_id);
                $("#checked_item").val(total.join(','));
                add_item(e_id,storage,name,total_price,price);
            }else{
                $("#"+e_id).find("a").eq(1).trigger("onclick"); //如果产品或者服务重复则只增加数量
                var left_item = [];
                if (parseInt(pid[1]) == 4){ //当后选择打折卡时默认设置使用打折卡下单
                    for(var k=0;k< total.length;k++){
                        if(total[k] != e_id){
                            left_item.push(total[k]);
                        }else{
                            $("#table_item #"+e_id).attr("id",same_id);
                            $("#"+e_id ).attr("checked",false);
                        }
                    }
                    left_item.push(same_id);
                    $("#checked_item").val(left_item.join(","));
                }else{
                    $("#"+same_id ).attr("checked",false);
                    tishi_alert("已添加！");
                }
            }
        }
    }
    else{
        del_item(e_id,total_price);
    }
}
function add_item(e_id,storage,name,total_price,price){
    var types_name = "后台下单";
    if (parseInt(e_id.split("_")[1]) == 3){
        types_name = "后台套餐卡下单";
    }else if(parseInt(e_id.split("_")[1]) == 4){
        types_name = "后台打折卡下单";
    }
    $("#table_item").append("<tr id='"+ e_id +"' class='"+(storage == undefined ? 1 : storage)+"'><td>"+ name +"</td>\n\
       <td id='price'>"+price+"</td><td>\n\<a href='javascript:void(0)' class='addre_a' style='font-size:15px;' onclick='del_num(this)'>-</a>\n\
       <span style='margin:5px;'><input type='text' class='addre_input' value='1' readonly /></span><a href='javascript:void(0)' \n\
       class='addre_a' style='font-size:15px;' onclick='add_num(this)'>+</a></td><td id='t_price'>"+price +"</td><td>"+types_name+"</td>\n\
       <td><a href='javascript:void(0)'onclick='del_self(this)';>删除</a></td></tr>");
    $("#total_price").html(change_dot(round(total_price,2)+round(price,2),2));
}

function del_self(e){
    var total_price = $('#total_price').html();
    var e_id = $(e).parent().parent().attr("id");
    del_item(e_id,total_price);
}


function del_item(e_id,total_price){
    var checked_item = $("#checked_item").val().split(",");
    var left_item = [];
    var same_id = e_id.split("_");
    if ( parseInt(same_id[1]) == 4 || parseInt(same_id[1]) == 5 || parseInt(same_id[1]) == 6){
        for(var m=0;  m < checked_item.length;m++){
            var del_t = checked_item[m].split("_");
            if(same_id[2] == del_t[2] && parseInt(del_t[1]) != 3){
                e_id = checked_item[m];
            }
        }
    }
    var e_price = $("#table_item #"+e_id+" #t_price").html();
    $("#total_price").html(change_dot(round(total_price,2)-round(e_price,2),2));
    $("#table_item #"+e_id).remove();
    $("#"+e_id +" :checkbox").attr("checked",false);
    $("#"+e_id).attr("checked",false);
    for(var k=0;k<checked_item.length;k++){
        if(checked_item[k] != e_id){
            left_item.push(checked_item[k]);
        }
    }
    $("#checked_item").val(left_item.join(","));
}

function search_card(store_id){
    var e = $("#car_num")[0];
    if (e.value !="" && e.value.length == 7 ){
        $("#old_customer").val("");
        auth_car_num(e,store_id);
    }
}

function submit_item(store_id){
    var e = $("#car_num")[0];
    var checked_item = $("#checked_item").val();
    var c_name = $("#c_name").val();
    var c_number = $("#c_number").val();
    var other_way = $("#other_way").val();
    var c_group = $("#c_group").val();
    var c_address = $("#c_address").val();
    var customer_id = $("input[name='customer_types']:checked").val();
    var car_model_id = $("#add_car_models option:selected").val();
    var buy_year = $("#add_car_buy_year option:selected").val();
    var distance = $("#add_car_distance").val();
    var check_phone = false;
    var check_card =  false;
    if (e.value !="" && (e.value.length == 7 || $.trim(e.value) == "无牌") ){
        if (checked_item != "" && checked_item.length > 4){
            if(c_number != "" && c_number.length != 11){
                tishi_alert("手机号码不正确！");
                return false;
            }
            if(confirm("确认提交订单?")){
                var items = checked_item.split(",");
                var sub_items = {};
                var url = "/stores/"+store_id+"/set_stores/submit_item";
                var data ={
                    car_num : e.value,
                    customer_id : customer_id,
                    customer : {},
                    car_info : {}
                }
                if (parseInt(customer_id) > 0){
                    data["car_info"]["car_model_id"]= car_model_id;
                    data["car_info"]["buy_year"]= buy_year;
                    data["car_info"]["distance"]= distance;
                }
                data["customer"]["name"]=c_name;
                data["customer"]["mobilephone"]= c_number;
                data["customer"]["other_way"]= other_way;
                data["customer"]["address"]= c_address;
                if(c_group != "" && c_group.length !=0){
                    data["customer"]["group_name"]= c_group;
                }
                for(var i=0; i< items.length;i++){
                    if ((parseInt(items[i].split("_")[1])==1 ||  parseInt(items[i].split("_")[1])==2)  &&  (c_number == "" || c_number.length != 11)){
                        check_phone = true;
                    }
                    if (parseInt(customer_id) > 0 && (parseInt(items[i].split("_")[1])==3 ||parseInt(items[i].split("_")[1])==4) ){
                        check_card = true
                    }
                    sub_items[items[i]] = $("#table_item #"+items[i] +" :text").val();
                }
                if (check_phone){
                    tishi_alert("购买储值卡需要客户手机号！")
                }else{
                    if (check_card){
                        tishi_alert("合并客户不能使用当前车牌的卡类信息！");
                        return false;
                    }
                    if (c_number != "" && c_number.length == 11){
                        if(confirm("请确认手机号 "+c_number)){
                            $("#submit_item,#submit_spinner").toggle();
                            data["sub_items"] = sub_items;
                            request_ajax(url,data,"post")
                        }
                    }else{
                        $("#submit_item,#submit_spinner").toggle();
                        data["sub_items"] = sub_items;
                        request_ajax(url,data,"post")
                    }
                }
            }
        }else{
            tishi_alert("请选择项目！")
        }
    }else{
        tishi_alert("车牌号码不正确！")
    }
}

function edit_deduct(order_id,store_id){
    var url = "/stores/"+store_id+"/set_stores/edit_deduct";
    var data ={
        order_id : order_id
    }
    request_ajax(url,data,"post")
}

function post_deduct(store_id,order_id){
    var url = "/stores/"+store_id+"/set_stores/post_deduct";
    var data = {
        ids:{},
        order_id : order_id
    };
    var ok = true;
    var wrong_id = null;
    var total_tech = $("#tech_order_popup :text");
    for(var i =0;i<total_tech.length;i++){
        data["ids"][total_tech[i].id]=total_tech[i].value;
        if (isNaN(total_tech[i].value)){
            wrong_id = total_tech[i].id;
            ok = false;
            break;
        }
    }
    if (ok){
        if(confirm("确认更改提成金额吗？")){
            $.ajax({
                type:"post",
                url:url,
                dataType: "json",
                data: data,
                success : function(data){
                    if (data.status==0){
                        tishi_alert("修改成功！");
                        $("#edit_deduct .close").trigger("click");
                    }else{
                        tishi_alert("修改失败！");
                    }
                }
            })
        }
    }else{
        tishi_alert("数据有误!");
        $("#tech_order_popup #" +wrong_id).focus();
    }
}


function auth_number(e,store_id){
    if (e.value != "" && e.value.length == 11 ){
        var url = "/stores/"+store_id+"/set_stores/search_num";
        var old_number = $("#old_number").val();
        if (e.value != old_number){
            var data ={
                mobilephone : e.value
            }
            $.ajax({
                type:"post",
                url:url,
                dataType: "script",
                data: data
            })
        }
    }
}


function confirm_btn(){
    var customer = $("input[name='customer_types']:checked")[0];
    if (customer.value != "0"){
        var customer_name = $(customer).parents("tr").find("td").eq(1).html();
        var group_name = $(customer).parents("tr").find("td").eq(2).html();
        var address = $(customer).parents("tr").find("td").eq(3).html();
        $("#c_group").val(group_name);
        $("#c_address").val(address);
        $("#c_name").val(customer_name);
    }else{
        $("#c_group,#c_address,#c_name").val("");
    }
    $('#customer_popup .close').trigger('click');
}