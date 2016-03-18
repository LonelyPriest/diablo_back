var version_update = function(){
    
    var updates = [
	{date: "2016-03-18",
	 content: [
	     "增加修改销售时可以进行中文联想",
	     "增加日报表可打印功能"
	 ]
	},
	
	{date: "2016-03-12",
	 content: [
	     "增加补单是无法退货的提示",
	     "修改开单日期为每天0点时统计的问题"
	 ]
	},
	
	{date: "2016-03-11",
	 content: [
	     "品牌最大长度由8个字符改成16个字符",
	     "序号左对齐改成居中"
	 ]
	},
	
	{date: "2016-03-10",
	 content: [
	     "用户登录时可选择默认客户开单",
	     "增加开单时，是否自动计算现金选项, 默认不计算"
	 ]
	},
	
	{date: "2016-03-09",
	 content: [
	     "增加店铺地址打印加粗选项",
	     "不打印尺码时，可以打印序号选项",
	     "单行备注可打印" 
	 ]
	},
	
	{date: "2016-03-07",
	 content: [
	     "增加开单时可以重复款号选项"
	 ]
	},
	
	{date: "2016-03-03",
	 content: [
	     "多店铺之间移仓功能完善",
	     "销售退货一起开单时，打印单据增加详细说明",
	     "帐号登录时，可选择默认员工登录"
	 ]
	},
	
	{date: "2016-02-25",
	 content: [
	     "增加用户登录时可选择默认店铺与厂商功能",
	     "增加隐藏额外价格与折扣功能"
	 ]
	},
	
	{date: "2016-01-30",
	 content: [
	     "增加店铺之间的库存调入调出功能",
	     "增加删除货品资料功能"
	 ]
	},
	
	{date: "2016-01-19",
	 content: [
	     "增加默认价格类型选择，可自由选择吊牌价，批发价",
	     "增加货品类型可输入横杠"
	 ]
	},
	
	{date: "2016-01-17",
	 content: [
	     "修正仓库功能",
	     "修正epson LQ55K打印机打印标准"
	 ]
	},
	
	{date: "2016-01-09",
	 content: [
	     "增加库存导出时的统计字段"
	 ]
	},
	
	{date: "2015-12-06",
	 content: [
	     "增加管理员可查看库存结余统计",
	     "修改打印格式，加大银行卡之间的打印距离"
	 ]
	},
	
	{date: "2015-11-14",
	 content: [
	     "增加厂商退货可修改价格功能！！"
	 ]
	},
	
	{date: "2015-11-09",
	 content: [
	     "优化服务器，请使用 120.25.212.38 直接登录！！能提高平板响应速度"
	 ]
	},
	
	{date: "2015-11-07",
	 content: [
	     "优化超大单处理",
	     "优化打印处理"
	 ]
	},
	
	{date: "2015-11-02",
	 content: [
	     "库存销售统计分布增加前进后退功能",
	     "优化打印处理",
	     "优化手机，平板横屏，竖屏内容显示"
	 ]
	},
	
	{date: "2015-10-30",
	 content: [
	     "增加库存销售统计分布示意图",
	     "增强货品修改功能",
	     "修正整单四舍五入时显示多个0的问题"
	 ]
	},
	
	{date: "2015-10-29",
	 content: [
	     "增加货品可修改款号，品牌功能" 
	 ]
	},
	
	{date: "2015-10-28",
	 content: [
	     "增加零售商地理分布示意图",
	     "增加四舍五入模式配置",
	     "优化界面显示"
	 ] 
	},
	
	{date: "2015-10-27",
	 content: [
	     "增加采购零库存退货配置，允许用户退货数量大于库存数量",
	     "增加库存告警配置，开启库存告警时，一定时间段内没有卖出的款号在库存中以红色显示",
	     "优化界面效果，pad竖屏与横屏时的优化显示",
	     "优化顺序翻页功能"
	 ]
	},
	
	{date: "2015-10-26",
	 content:[
	     "增加日报表功能",
	     "数据四舍五入计算",
	     "核销与实付分开计算",
	     "增加顺序翻页配置",
	     "优化操作界面，增加界面触摸控制",
	     "自动悬浮表头",
	     "解决库存导出bug",
	     "优化服务器，以提高系统性能"
	 ]
	},
	{date: "2015-10-16",
	 content: [
	     "增加均色均码退货可修改价格能力",
	     "增加是否开启检测库存销售配置，该配置只对均色均码生效，以加快散货开单速度",
	     "同时关闭价格跟踪与检测库存销售，系统将开启均色均码模式，大大加快开单速度",
	     "调整界面按键尺寸，优化整个界面尺寸，以获得在pad上更佳的体验"
	 ]
	},
	{date: "2015-10-15",
	 content: [
	     "增加开单是否显示折扣配置，【用户->基本设置->系统设置->开单显示折扣】，选择开启或关闭，修改后请注销后再登录",
	     "解决联动修改单据时，会对别的零售商产生影响的问题",
	     "优化操作界面，隐藏不常用的列，加大常用按键尺寸，以更适合于pad上使用"
	 ] 
	},
	{date:"2015-10-13",
	 content: [
	     "解决修改销售记录时，修改零售商有时无法成功的问题",
	     "解决退货到次品仓，有时退货失败的问题",
	     "解决从次品仓退货到厂商，明细无法显示的问题",
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
		 + "<h4 class='text-center' style='margin-top:20px'><span class='fg-red'><strong>"
		    + "<u>" + updates[i].date + "日更新</u>"
		    + "</strong></span></h4>"
		    + "<h5 class='text-center'><span class='fg-red'>注：首次登录时，请务必清除浏览器缓存后再登陆！！</span></h5>"
		    + "<ol style='padding:0;color:orange'>"

		var c = ""
		for (var j=0, k=updates[i].content.length; j<k; j++){
		    c += "<li style='padding-bottom:5px'><span class='fg-orange'>"
			+ updates[i].content[j] + "</span></li>" 
		}
		var e = "</ol></div></div>";

		content += s + c + e;
	    }

	    $('body').append(content);
		// .append("<div class='copyright'><span> 2015-2025 &copy;&nbsp钱掌柜&nbsp&nbsp&nbsp&nbsp</span>"
		// 			     + "<span><i class='glyphicon glyphicon-star'></i>"
		// 			     + "QQ群：261033201"
		// 			     + "</span></div>");
	}
    } 
}();
