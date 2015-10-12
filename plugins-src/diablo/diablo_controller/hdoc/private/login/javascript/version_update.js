var version_update = function(){
    var updates = [
	{date:"2015-10-13",
	 content: [
	     "修改退货到次品仓，有时退货失败的问题",
	     "修改从次品仓退货到厂商，明细无法显示的问题",
	     "新增零售商时，增加条件约束，所在城市输入时，所在省（直辖市）必须输入",
	     "优化部分查询条件智能展示",
	     "优化部分图标，统一显示"
	 ]
	},
	
	{date: "2015-10-12",
	 content: [
	     "修改用户2小时内无操作时，系统自动清理该用户，以增加系统安全性",
	     "销售（退货），入库（退货）单修改，该单之后的每一单均会联动修改，以方便零售商（厂商）对帐",
	     "均色均码退货，输入数量1秒后自动保存",
	     "开启前台查找时，销售（退货），采购（退货）时货号联想采用任意匹配模式，不再需要从首字母开始输入联想，【用户-基本设置->系统设置->提示方式】，开启前台查找",
	     "查询保留每次查询条件与状态，再次查询时，自动获取上次的查询条件",
	     "按【返回】按钮时，自动回到上次查询的页面",
	     "增大换页标签，避免在pad上显示过小问题",
	     "修改个别显示问题"]
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
		    + "<h5 class='text-center'><span class='fg-red'>注：设备首次登录时，请务必清除浏览器缓存后再登陆！！</span></h5>"
		    + "<ol style='padding:0;color:orange'>"

		var c = ""
		for (var j=0, k=updates[i].content.length; j<k; j++){
		    c += "<li style='padding-bottom:5px'><span class='fg-orange'>"
			+ updates[i].content[j] + "</span></li>" 
		}
		var e = "</ol></div></div>";

		content += s + c + e;
	    }

	    $('body').append(content).append("<div class='copyright'><span> 2015-2025 &copy;&nbsp钱掌柜&nbsp&nbsp&nbsp&nbsp</span>"
					     + "<span><i class='glyphicon glyphicon-star'></i>"
					     + "QQ群：261033201"
					     + "</span></div>");
	}
    } 
}();
