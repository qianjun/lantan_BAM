//发送短信显示姓名
function show_name() {
    $("#content").val($("#content").val() + "%name%");
}

//发送短信显示门店名称
function show_store_name(store_name) {
    $("#content").val($("#content").val() + "--" + store_name);
}