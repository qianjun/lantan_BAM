function market_new(store_id,types){     //营销-新建产品/服务类别
    var url = "/stores/"+store_id+"/set_functions/market_new";
    var data = {
        types : types
    }
    request_ajax(url,data)
}

function new_market_commit(store_id, types){   //营销-新建产品/服务类别 提交
    var name = $.trim($("#market_name").val());
    if(name==""){
        tishi_alert("名字不能为空!")
    }else if(get_str_len(name)>16){
        tishi_alert("名字长度不能超过16个字符!")
    }
    else{
        $.ajax({
            type: "get",
            url: "/stores/"+store_id+"/set_functions/market_new_commit",
            dataType: "json",
            data: {
                store_id : store_id,
                name : name,
                types : types
            },
            success: function(data){
                if(data.status==2){
                    tishi_alert("新建失败，已有同名的项目类别!");
                }else if(data.status==0){
                    tishi_alert("新建失败!");
                }else{
                    tishi_alert("新建成功!");
                    var url = "/stores/"+store_id+"/set_functions";
                    var t_data = {
                        init : "market_init"
                    }
                    request_ajax(url,t_data)
                }
            }
        })
    }
}

function market_edit(id, store_id){   //营销-编辑服务/产品
    var url = "/stores/"+store_id+"/set_functions/market_edit";
    var data = {
        market_id : id
    }
    request_ajax(url,data)
}

function edit_market_commit(id, store_id){    //营销-编辑服务/产品 提交
    var name = $.trim($("#market_edit_name").val());
    if(name==""){
        tishi_alert("名字不能为空!");
    }else if(get_str_len(name)>16){
        tishi_alert("名字长度不能超过16个字符!");
    }else{
        $.ajax({
            type: "get",
            url: "/stores/"+store_id+"/set_functions/market_edit_commit",
            dataType: "json",
            data: {
                market_id : id,
                name : name
            },
            success: function(data){
                if(data.status==2){
                    tishi_alert("编辑失败，已有同名的项目类别!");
                }else if(data.status==0){
                    tishi_alert("编辑失败!");
                }else{
                    tishi_alert("编辑成功!");
                    var url = "/stores/"+store_id+"/set_functions";
                    var t_data = {
                        init : "market_init"
                    }
                    request_ajax(url,t_data)
                }
            }
        })
    }
}

function storage_new(store_id){     //库存-新建物料类别
    var url = "/stores/"+store_id+"/set_functions/storage_new";
    request_ajax(url)
}

function new_storage_commit(store_id){  //库存-新建物料类别 提交
    var name = $.trim($("#storage_name").val());
    if(name==""){
        tishi_alert("名字不能为空!");
    }else if(get_str_len(name)>16){
        tishi_alert("名字长度不能超过16个字符!");
    }else{
        $.ajax({
            type: "get",
            url: "/stores/"+store_id+"/set_functions/storage_new_commit",
            dataType: "json",
            data: {
                name : name
            },
            success: function(data){
                if(data.status==2){
                    tishi_alert("新建失败，已有同名的项目类别!")
                }else if(data.status==0){
                    tishi_alert("创建失败!")
                }else{
                    tishi_alert("创建成功!");
                    var url = "/stores/"+store_id+"/set_functions";
                    var t_data = {
                        init : "storage_init"
                    }
                    request_ajax(url,t_data)
                }
            }
        })
    }
}

function edit_storage(id, store_id){    //库存-编辑物料类别
    var url = "/stores/"+store_id+"/set_functions/storage_edit";
    var data = {
        storage_id : id
    }
    request_ajax(url,data)
}

function edit_storage_commit(id, store_id){      //库存-编辑物料类别 提交
    var name = $.trim($("#storage_edit_name").val());
    if(name==""){
        tishi_alert("名字不能为空!");
    }else if(get_str_len(name)>16){
        tishi_alert("名字长度不能超过16个字符!");
    }else{
        $.ajax({
            type: "get",
            url: "/stores/"+store_id+"/set_functions/storage_edit_commit",
            dataType: "json",
            data: {
                storage_id : id,
                name : name
            },
            success: function(data){
                if(data.status==2){
                    tishi_alert("编辑失败，已有同名的项目类别!");
                }else if(data.status==0){
                    tishi_alert("编辑失败!");
                }else{
                    tishi_alert("编辑成功!");
                    var url = "/stores/"+store_id+"/set_functions";
                    var t_data = {
                        init : "storage_init"
                    }
                    request_ajax(url,t_data)
                }
            }
        })
    }
}

function depart_new(store_id){      //组织架构-新建部门
    var url = "/stores/"+store_id+"/set_functions/depart_new"
    request_ajax(url)
}

function depart_new_commit(store_id){   //组织架构-新建部门 提交
    var name = $.trim($("#depart_name").val());
    if(name==""){
        tishi_alert("部门名称不能为空!");
    }else if(get_str_len(name)>14){
        tishi_alert("部门名称长度不能超过14个字符!");
    }else{
        $.ajax({
            type: "get",
            url: "/stores/"+store_id+"/set_functions/depart_new_commit",
            dataType: "json",
            data: {
                name : name
            },
            success: function(data){
                if(data.status==2){
                    tishi_alert("创建失败，已有同名的部门!");
                }else if(data.status==0){
                    tishi_alert("创建失败!");
                }else{
                    tishi_alert("创建成功!");
                    var url = "/stores/"+store_id+"/set_functions";
                    var t_data = {
                        init : "depart_init"
                    }
                    request_ajax(url,t_data)
                }
            }
        })
    }
}

function sibling_depart_new(store_id, lv){      //组织架构-新建同级部门
    var url = "/stores/"+store_id+"/set_functions/sibling_depart_new";
    var data = {
        lv : lv
    }
    request_ajax(url,data)
}

function sibling_depart_new_commit(store_id, lv){   //组织架构-新建同级部门 提交
    var name = $.trim($("#sibling_depart_name").val());
    if(name==""){
        tishi_alert("部门名称不能为空!");
    }else if(get_str_len(name)>14){
        tishi_alert("部门名称长度不能超过14个字符!");
    }else{
        $.ajax({
            type: "get",
            url: "/stores/"+store_id+"/set_functions/sibling_depart_new_commit",
            dataType: "json",
            data: {
                name : name,
                lv : lv
            },
            success: function(data){
                if(data.status==2){
                    tishi_alert("创建失败，已有同名的部门!");
                }else if(data.status==0){
                    tishi_alert("创建失败!");
                }else{
                    tishi_alert("创建成功!");
                    var url = "/stores/"+store_id+"/set_functions";
                    var t_data = {
                        init : "depart_init"
                    }
                    request_ajax(url,t_data)
                }
            }
        })
    }
}

function depart_edit(store_id, depart_id){  //组织架构-编辑部门
    var url = "/stores/"+store_id+"/set_functions/depart_edit";
    var data = {
        depart_id : depart_id
    }
    request_ajax(url,data)
}

function position_new(store_id, dpt_id){    //组织架构-新建职务
    $.ajax({
        type: "get",
        url: "/stores/"+store_id+"/set_functions/position_new",
        dataType: "script",
        data: {
            dpt_id : dpt_id
        }
    })
}

function position_new_commit(store_id, dpt_id){         //组织架构-新建职务 提交
    var name = $.trim($("#position_name").val());
    if(name==""){
        tishi_alert("职务名称不能为空!");
    }else if(get_str_len(name)>18){
        tishi_alert("职务名称长度不能超过18个字符!")
    }else{
        $.ajax({
            type: "get",
            url: "/stores/"+store_id+"/set_functions/position_new_commit",
            dataType: "json",
            data: {
                name : name,
                dpt_id : dpt_id
            },
            success: function(data){
                if(data.status==2){
                    tishi_alert("创建失败，已有同名的职务!");
                }else if(data.status==0){
                    tishi_alert("创建失败!");
                }else{
                    tishi_alert("创建成功!");
                    $("#set_functions_position_new").empty();
                    $("#set_functions_position_new").hide();
                    $(".maskOne").hide();
                    $.ajax({        //重新加载编辑部门弹出层
                        type: "get",
                        url: "/stores/"+store_id+"/set_functions/depart_edit",
                        dataType: "script",
                        data: {
                            depart_id : dpt_id
                        }
                    });
                    $.ajax({        //重新加载组织架构主页面
                        type: "get",
                        url: "/stores/"+store_id+"/set_functions",
                        dataType: "script",
                        data: {
                            init : "set_positions"
                        }
                    });
                }
            }
        })
    }
}

function position_edit(obj){              //组织架构-编辑职务
    $(obj).parent("li").find("label").hide();
    $(obj).parent("li").find("input").show();
    $(obj).parent("li").find("input").focus();
    $(obj).hide();
    $(obj).next().hide();
}

function position_edit_commit(store_id, pid, obj){      //组织架构-编辑职务 提交
    var new_name = $.trim($(obj).val());
    var old_name = $(obj).parent("li").find("label").text();
    if(new_name==old_name || new_name==""){
        $(obj).hide();
        $(obj).val(old_name);
        $(obj).parent("li").find("label").show();
        $(obj).parent("li").find("a").show();
    }else if(get_str_len(new_name)>18){
        tishi_alert("职务名称长度不能超过18个字符!");
        $(obj).hide();
        $(obj).val(old_name);
        $(obj).parent("li").find("label").show();
        $(obj).parent("li").find("a").show();
    }else{
        $.ajax({
            type: "get",
            url: "/stores/"+store_id+"/set_functions/position_edit_commit",
            dataType: "json",
            data: {
                pid : pid,
                name : new_name
            },
            success: function(data){
                if(data.status==2){
                    tishi_alert("编辑失败，该部门下已有同名的职务!");
                    $(obj).hide();
                    $(obj).val(old_name);
                    $(obj).parent("li").find("label").show();
                    $(obj).parent("li").find("a").show();
                }else if(data.status==0){
                    tishi_alert("编辑失败!");
                    $(obj).hide();
                    $(obj).val(old_name);
                    $(obj).parent("li").find("label").show();
                    $(obj).parent("li").find("a").show();
                }else{
                    tishi_alert("编辑成功!");
                    $(obj).parent("li").find("label").text(new_name);
                    $(obj).hide();
                    $(obj).parent("li").find("label").show();
                    $(obj).parent("li").find("a").show();
                    var dpt_id = data.depart_id;
                    $.ajax({        //重新加载编辑部门弹出层
                        type: "get",
                        url: "/stores/"+store_id+"/set_functions/depart_edit",
                        dataType: "script",
                        data: {
                            depart_id : dpt_id
                        }
                    });
                    $.ajax({        //重新加载组织架构主页面
                        type: "get",
                        url: "/stores/"+store_id+"/set_functions",
                        dataType: "script",
                        data: {
                            init : "set_positions"
                        }
                    });
                }
            }
        })
    }
}

function position_del(store_id, pid, obj){  //组织架构-删除职务
    var flag = confirm("确定删除该职务?");
    if(flag){
        $.ajax({
            type: "get",
            url: "/stores/"+store_id+"/set_functions/position_del_commit",
            dataType: "json",
            data: {
                pid : pid
            },
            success: function(data){
                if(data.status==0){
                    tishi_alert("删除失败!");
                }else{
                    tishi_alert("删除成功!");
                    $(obj).parent("li").remove();
                    var dpt_id=data.depart_id
                    $.ajax({        //重新加载编辑部门弹出层
                        type: "get",
                        url: "/stores/"+store_id+"/set_functions/depart_edit",
                        dataType: "script",
                        data: {
                            depart_id : dpt_id
                        }
                    });
                    $.ajax({        //重新加载组织架构主页面
                        type: "get",
                        url: "/stores/"+store_id+"/set_functions",
                        dataType: "script",
                        data: {
                            init : "set_positions"
                        }
                    });
                }
            }
        })
    }
}

function depart_edit_commit(store_id, did){     //组织架构-编辑部门 提交
    var name = $.trim($("#depart_edit_name").val());
    if(name==""){
        tishi_alert("部门名称不能为空!");
    }else if(get_str_len(name)>14){
        tishi_alert("部门名称长度不能超过14个字符!");
    }else{
        $.ajax({
            type: "get",
            url: "/stores/"+store_id+"/set_functions/depart_edit_commit",
            dataType: "json",
            data: {
                name : name,
                did : did
            },
            success: function(data){
                if(data.status==2){
                    tishi_alert("编辑失败，已有同名的部门!")
                }else if(data.status==0){
                    tishi_alert("编辑失败!")
                }else{
                    tishi_alert("编辑成功!");
                    $.ajax({
                        type: "get",
                        url: "/stores/"+store_id+"/set_functions",
                        dataType: "script",
                        data: {
                            init : "depart_init"
                        }
                    })
                }
            }
        })
    }
}

function depart_del(store_id, did){
    var flag = confirm("确定删除该部门?");
    if(flag){
        $.ajax({
            type: "get",
            url: "/stores/"+store_id+"/set_functions/depart_del",
            dataType: "json",
            data: {
                did : did
            },
            success: function(data){
                if(data.status==0){
                    tishi_alert("删除失败!");
                }else{
                    tishi_alert("删除成功!");
                    $.ajax({
                        type: "get",
                        url: "/stores/"+store_id+"/set_functions",
                        dataType: "script",
                        data: {
                            init : "depart_init"
                        }
                    })
                }
            }
        })
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