var version_update = function(){
    var updates = [
	{date: "2015-10-11",
	 content: [
	     "销售（退货），入库（退货）单修改，该单之后的每一单价格会联动修改，以方便对帐",
	     "均色均码退货，输入数量1秒后自动保存",
	     "开启前台查找时，销售（退货），采购（退货）时货号联想采用任意匹配模式，不再需要从首字母开始输入联想，【用户-基本设置->系统设置->提示方式】，开启前台查找",
	     "查询保留每次查询条件与状态，再次查询时，自动获取上次的查询条件",
	     "按【返回】按钮时，自动回到上次查询的页面",
	     "增大换页标签，避免在pad上显示过小问题"]
	}
    ]; 

    return {
	init: function(){
	    var content="";

	    for (var i=0, l=updates.length; i<l; i++){
		var s =  "<div class='update-content'><div class='text-left'>"
		 + "<h4 class='text-center' style='margin-top:40px'><span class='fg-red'><strong>"
		    + "<u>" + updates[i].date + "日更新</u>"
		    + "</strong></span></h4>"
		    + "<h5 class='text-center'><span class='fg-darkRed'>注：首次登录时，请清除浏览器缓存后再登陆！！</span></h5>"
		    + "<ol style='padding:0;color:orange'>"

		var c = ""
		for (var j=0, k=updates[i].content.length; j<k; j++){
		    c += "<li style='padding-bottom:5px'><span class='fg-orange'>"
			+ updates[i].content[j] + "</span></li>" 
		}
		var e = "</ol></div></div>";

		content += s + c + e;
	    }

	    $('body').append(content).append("<div class='copyright'> 2015-2025 &copy; 钱掌柜 </div>");
	}
    } 
}();
