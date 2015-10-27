var baseApp = angular.module(
    'baseApp', ['ngRoute', 'ngResource', 'ui.bootstrap',
		'diabloPattern', 'diabloUtils', 'diabloAuthenApp',
		'userApp', 'wprintApp'])
    .config(function($httpProvider, authenProvider){
	$httpProvider.interceptors.push(authenProvider.interceptor); 
    });

baseApp.config(['$routeProvider', function($routeProvider){
    $routeProvider.
	when('/passwd', {
	    templateUrl: '/private/base/html/reset_password.html',
            controller: 'resetPasswdCtrl'
	}).
	when('/bank/new_bank_card/:cardId?', {
	    templateUrl: '/private/base/html/bank_card_new.html',
            controller: 'bankCardNewCtrl'
	}).
	when('/bank/bank_card_detail', {
	    templateUrl: '/private/base/html/bank_card_detail.html',
            controller: 'bankCardDetailCtrl'
	}).
	when('/setting/print_option', {
	    templateUrl: '/private/base/html/print_detail.html',
            controller: 'printOptionCtrl',
	    resolve: {"user": function(userService){
		return userService()}}
	}).
	when('/setting/print_format', {
	    templateUrl: '/private/base/html/base_print_format.html',
            controller: 'printFormatCtrl',
	    resolve: {"user": function(userService){
		return userService()}}
	}). 
	when('/setting/table_detail', {
	    templateUrl: '/private/base/html/table_detail.html',
            controller: 'tableDetailCtrl'
	}).
	when('/printer/connect_new', {
	    templateUrl: '/private/base/html/base_printer_connect.html',
            controller: 'basePrinterConnectNewCtrl',
	    resolve: {"user": function(userService){
		return userService()}}
	}). 
	when('/printer/connect_detail', {
	    templateUrl: '/private/base/html/base_printer_connect_detail.html',
            controller: 'basePrinterConnectDetailCtrl',
	    resolve: {"user": function(userService){
		return userService()}}
	}).
	otherwise({
	    templateUrl: '/private/base/html/base_printer_connect_detail.html',
            controller: 'basePrinterConnectDetailCtrl',
	    resolve: {"user": function(userService){
		return userService()}}
        })
}]);


baseApp.service("baseService", function($resource){
    // error
    this.error = {8010: "修改前后信息一致，请重新编辑修改项！！",
		  8001: "该银行卡已存在！！",
		  8002: "该设置项已存在，请选择其它设置项！！",
		  8003: "旧密码不正确，请重新输入！！",
		  9001: "数据库操作失败，请联系服务人员！！"};

    this.print_setting = 0;
    this.table_setting = 1;

    this.option_names = [
	{cname: "电话1", ename: "phone1"},
	{cname: "电话2", ename: "phone2"},
	{cname: "备注1", ename: "comment1"},
	{cname: "备注2", ename: "comment2"},
	{cname: "备注3", ename: "comment3"}];

    this.print_types = [{cname:"前台打印", value: 0},
			{cname:"后台打印", value: 1}];
    this.print_formats = [
	{cname:"尺码竖打", value: 0},
	{cname:"尺码横打", value: 1}, 
    ];

    this.yes_no = [
	{cname:"否", value: 0},
	{cname:"是", value: 1}, 
    ];

    this.prompt_types = [{cname:"前台查找", value: 0},
			 {cname:"后台查找", value: 1}];

    this.time_length = [{cname:"1个月", value: 30},
			{cname:"1季度", value: 90},
			{cname:"半年",  value: 180},
			{cname:"1年",   value: 365},
			{cname:"2年",   value: 730}];

    this.round_names = [
	{cname:"整单四舍五入", value: 0},
	{cname:"单款四舍五入", value: 1}
    ];

    var http = $resource("/wbase/:operation/:id", {operation: '@operation'},
			 {
			     query_by_post: {method: 'POST', isArray: true}
			 });

    
    this.new_card = function(card){
	return http.save({operation: 'new_w_bank_card'}, card).$promise;
    };

    this.list_card = function(){
	return http.query({operation: 'list_w_bank_card'}).$promise; 
    };

    this.update_card = function(card){
	return http.save({operation: 'update_w_bank_card'},
			 {no:   card.no,
			  bank: card.bank,
			  id:   card.id}).$promise;
    };

    this.delete_card = function(card){
	return http.save({operation: 'del_w_bank_card'},
			 {id: card.id}).$promise;
    };

    // base
    this.list_setting = function(type){
	return http.query_by_post({operation: 'list_base_setting'},
				  {type: type}).$promise;
    };

    this.add_setting = function(s){
	return http.save({operation: 'add_base_setting'}, s).$promise
    };
    
    this.update_setting = function(s){
	return http.save({operation: 'update_base_setting'},
			 {id: s.id, ename: s.ename, value: s.value, shop:s.shop}).$promise;
    };

    this.add_shop_setting = function(shop) {
	return http.save({operation: 'add_shop_setting'}, {shop:shop}).$promise;
    };

    /*
     * passwd
     */
    this.reset_passwd = function(p){
	return http.save({operation: 'update_user_passwd'},p).$promise;
    }
    
});
    
baseApp.controller("bankCardNewCtrl", function($scope, baseService, diabloUtilsService){
    console.log($scope);

    $scope.new_card = function(){
	console.log($scope.card);
	baseService.new_card($scope.card).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		diabloUtilsService.response_with_callback(
		    true, "新增银行卡", "恭喜您，银行卡 " + $scope.card.no + " 成功创建！！",
		    $scope, function(){diablo_goto_page("#/bank/bank_card_detail")});
	    } else{
		diabloUtilsService.response(
		    false, "新增银行卡", "新增银行卡失败：" + baseService.error[state.ecode]); 
	    }
	})
    };

    $scope.refresh = function(){
	baseService.list_card().then(function(cards){
	    console.log(cards);
	})
    }

    $scope.cancel_new_card = function(){
	diablo_goto_page("#/bank/bank_card_detail");
    }
});


baseApp.controller("bankCardDetailCtrl", function($scope, baseService, diabloUtilsService){
    console.log($scope); 

    $scope.goto_page = diablo_goto_page;
    var dialog = diabloUtilsService;
    
    $scope.refresh = function(){
	baseService.list_card().then(function(cards){
	    console.log(cards);
	    diablo_order(cards);
	    $scope.cards = cards;
	})
    };

    $scope.refresh();

    $scope.update_card = function(card){
	var callback = function(params){
	    console.log(params);

	    if (card.no === params.card.no && card.bank === params.card.bank){
		dialog.response(
		    false, "银行卡编辑",
		    "银行卡编辑失败：" + baseService.error[8010]);
	    } else {
		baseService.update_card(params.card).then(function(state){
		    console.log(state);
		    if (state.ecode == 0){
			dialog.response_with_callback(
			    true, "银行卡编辑", "银行卡 " + card.no + " 修改成功！！",
			    $scope, function(){$scope.refresh()});
		    } else{
			dialog.response(
			    false, "银行卡编辑", "银行卡编辑失败：" + baseService.error[state.ecode]); 
		    }
		})
	    } 
	};

	dialog.edit_with_modal(
	    "edit-card.html", undefined, callback, $scope, {card:card});
    };

    $scope.delete_card = function(card){

	var callback = function(){
	    baseService.delete_card(card).then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    dialog.response_with_callback(
			true, "银行卡删除", "银行卡 " + card.no + " 删除成功！！",
			$scope, function(){$scope.refresh()});
		} else{
		    dialog.response(
			false, "银行卡删除", "银行卡删除失败：" + baseService.error[state.ecode]); 
		}
	    }) 
	};

	dialog.request(
	    "删除银行卡", "确定要删除该银行卡吗？", callback, undefined, $scope);
	
	
    }
});


baseApp.controller("printOptionCtrl", function(
    $scope, dateFilter, baseService, diabloPattern, diabloUtilsService, user){
    $scope.shops = [{id: -1, name:"== 请选择店铺或仓库，默认所有店铺配置相同 =="}]
	.concat(user.sortShops, user.sortRepoes);
    
    $scope.print_types   = baseService.print_types;
    $scope.print_formats = baseService.print_formats;
    $scope.yes_no        = baseService.yes_no;
    $scope.time_length   = baseService.time_length;
    $scope.prompt_types  = baseService.prompt_types;
    $scope.round_names   = baseService.round_names;
    console.log($scope.print_formats);

    $scope.show_switch = function(name){
	if (name === 'pum'
	    || name === 'qtime_start'
	    || name === 'qtime_length'
	    || name === 'phone1'
	    || name === 'phone2'
	    || name === 'comment1'
	    || name === 'comment2'
	    || name === 'comment3'
	   ){
	    return false;
	}

	return true;
    };
    
    // console.log($scope.print_types);

    var dialog = diabloUtilsService;

    $scope.shop_setting = function(shop){
	console.log(shop);
	for(var i=0, l=$scope.settings.length; i<l; i++){
	    var s = $scope.settings[i];
	    if (shop.id === s.shop.id){
		if (s.setting.length === 0){
		    var callback = function(){
			baseService.add_shop_setting(shop.id).then(function(result){
			    if (result.ecode == 0){
				dialog.response_with_callback(
				    true, "新增打印选项", "店铺 " + shop.name
					+ " 打印选项新增成功！！",
				    $scope, function(){$scope.refresh(shop)});
			    } else {
				dialog.response(
				    false, "新增打印选项",
				    "店铺 " + shop.name + " 打印选项新增失败："
					+ baseService.error[result.ecode]); 
			    }
			})
		    };
		    
		    dialog.request(
			"新增打印选项", "该店铺无打印选项，确定要新增打印选项吗？",
			callback, undefined, $scope);
		}
		// $scope.pformats[i].$new = false;
		return s.setting;
	    }
	}
    };
    
    $scope.refresh = function(shop){
	baseService.list_setting(baseService.print_setting).then(function(data){
	    console.log(data);
	    $scope.settings = 
		$scope.shops.map(function(s){
		    setting = data.filter(function(d){
			return d.shop === s.id;
		    });

		    return {shop:s, setting:diablo_order(setting)};
		})
	    
	    console.log($scope.settings); 
	    $scope.select = {shop:shop,
			     setting: $scope.shop_setting(shop)};
	})
    };

    $scope.refresh($scope.shops[0]);
    // console.log($scope.select.shop);

    $scope.add_setting = function(){
	var callback = function(params){
	    console.log(params.setting);
	    var s = params.setting;
	    baseService.add_setting({
		cname: s.name.cname,
		ename: s.name.ename,
		value: s.value,
		type:  baseService.print_setting,
		shop:  $scope.select.shop.id
	    }).then(function(result){
		console.log(result)
		if (result.ecode === 0){
		    dialog.response_with_callback(
			true, "新增系统选项", "系统选项 " + s.name.cname + " 新增成功！！",
			$scope, function(){$scope.refresh($scope.select.shop)});
		} else {
		    dialog.response(
			false, "新增系统选项", "新增系统选项失败："
			    + baseService.error[result.ecode]); 
		}
	    })
	}

	dialog.edit_with_modal(
	    "add-setting.html", undefined, callback, $scope,
	    {names:    baseService.option_names,
	     patterns: {tel_mobile: diabloPattern.tel_mobile,
			comment:    diabloPattern.comment},
	     setting:  {name: baseService.option_names[0]}
	    });
    }
    
    $scope.update_setting = function(s){
	console.log(s);

	var callback = function(params){
	    console.log(params);

	    var setting = params.setting;

	    var update;
	    if (s.ename==="qtime_start"){
		update = dateFilter(setting.value, "yyyy-MM-dd");
	    } else {
		update = typeof(setting.value) === 'object' ? setting.value.value : setting.value;
	    };
	    
	    baseService.update_setting({
		id:    setting.id,
		ename: setting.ename,
		value: update,
		shop:  $scope.select.shop.id
	    }).then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    dialog.response_with_callback(
			true, "系统选项编辑", "系统选项 " + s.cname + " 编辑成功！！",
			$scope, function(){$scope.refresh($scope.select.shop)});
		} else{
		    dialog.response(
			false, "系统选项编辑", "系统选项 " + s.cname + " 编辑失败："
			    + baseService.error[state.ecode]); 
		}
	    })
	};

	var v;
	if (s.ename === 'ptype'){
	    angular.extend(s, {ptypes: $scope.print_types}); 
	};
	if (s.ename === 'pformat'){
	    angular.extend(s, {pformats: $scope.print_formats}); 
	};
	if (s.ename === 'qtypeahead'){
	    angular.extend(s, {prompt_types: $scope.prompt_types}); 
	};
	if (s.ename === 'pround'){
	    angular.extend(s, {round_names: $scope.round_names}); 
	};
	
	if (s.ename === 'ptable'
	    || s.ename === 'pretailer'
	    // || s.ename === 'pround'
	    || s.ename === 'ptrace_price'
	    || s.ename === 'pim_print'
	    || s.ename === 'reject_negative'
	    || s.ename === 'check_sale'
	    || s.ename === 'show_discount'
	    || s.ename === 'se_pagination'
	    || s.ename === 'stock_alarm'){
	    angular.extend(s, {yes_no: $scope.yes_no}); 
	};
	if (s.ename === 'qtime_length'){
	    v = function(){
		for (var i=0, l=$scope.time_length.length; i<l; i++){
		    if (parseInt(s.value) === $scope.time_length[i].value){
			return $scope.time_length[i]
		    }
		}

		return undefined;
	    }(),
	    angular.extend(s, {time_length: $scope.time_length}); 
	};

	var qtime = {};
	if (s.ename === 'qtime_start'){
	    qtime.isOpened = false;
	    qtime.open_calendar = function(event){
		event.preventDefault();
		event.stopPropagation();
		// qtime.isOpened = true;
	    };
	};
	
	
	dialog.edit_with_modal(
	    "edit-setting.html", undefined, callback, $scope,
	    {setting: s,
	     init_v: v,
	     qtime: qtime,
	     patterns: {tel_mobile: diabloPattern.tel_mobile,
			comment:    diabloPattern.comment}});
    }
});


baseApp.controller("printFormatCtrl", function(
    $scope, dateFilter, baseService, diabloPattern, diabloUtilsService, wprintService, user){
    // shop and repo
    $scope.shops = [{id: -1, name:"== 请选择店铺或仓库，默认所有配置相同 =="}]
	.concat(user.sortShops, user.sortRepoes); 

    // var gen_format = function(shopId){
    // 	console.log($scope.shop_format($scope.shops[0]));
    // 	$scope.shop_format($scope.shops[0]).pformat.map(function(p){
    // 	    return {name:p.name, print:0, width:0, shop:shopId}
    // 	})
    // };
        
    // $scope.print_types = baseService.print_types;

    $scope.select       = {shop: $scope.shops[0]};
    $scope.print_fields = diablo_print_field;
    $scope.actions      = wprintService.print_actions;

    var dialog = diabloUtilsService;

    /*
     * select by the shop, new was created when empty
     */ 
    $scope.shop_format = function(shop){
	console.log(shop);
	for(var i=0, l=$scope.pformats.length; i<l; i++){
	    var p = $scope.pformats[i];
	    if (shop.id === p.shop.id){
		if (p.pformat.length === 0){
		    var callback = function(){
			wprintService.add_shop_format(shop.id).then(function(result){
			    if (result.ecode == 0){
				dialog.response_with_callback(
				    true, "新增打印格式", "店铺 " + shop.name
					+ " 打印格式新增成功！！",
				    $scope, function(){$scope.refresh(shop)});
			    } else {
				dialog.response(
				    false, "新增打印格式",
				    "店铺 " + shop.name + " 打印格式新增失败："
					+ baseService.error[result.ecode]); 
			    }
			})
		    };
		    
		    dialog.request(
			"新增打印格式", "该店铺无打印格式，确定要新增打印格式吗？",
			callback, undefined, $scope);
		}
		return p.pformat;
	    }
	} 
    };
    
    $scope.refresh = function(shop){
	// console.log(shop);
	wprintService.list_printer_format().then(function(data){
	    console.log(data);
	    // class by shop
	    $scope.pformats = 
		$scope.shops.map(function(s){
		    pformat = data.filter(function(d){
			return d.shop === s.id;
		    });

		    return {shop:s, pformat:diablo_order(pformat)};
		})
	    // console.log($scope.pformats); 
	    
	    console.log($scope.pformats); 
	    
	    $scope.select = {shop:shop, pformat: $scope.shop_format(shop)}; 
	})
    }; 

    $scope.refresh($scope.select.shop);
        
    $scope.update_printer_format = function(f){
	console.log(f);

	// check format
	// var check_format = function(format){
	//     if (format.name === "hand"){
	// 	get_field("size").print = 0;
	//     }

	//     if (format.name === "size_name"){
	// 	get_field("size").print = 0;
	//     }

	//     if (format.name === "size"){
	// 	get_field("hand").print = 0;
	// 	get_field("size_name").print = 0;
	//     }
	// }
	
	var callback = function(params){
	    console.log(params);
	    // check_format(params.pformat); 
	    console.log($scope.select);
	    wprintService.update_printer_format({
		id:     f.id,
		name:   f.name,
		print:  params.pformat.print.value,
		width:  params.pformat.width,
		shop:   $scope.select.shop.id
	    }).then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    dialog.response_with_callback(
			true, "打印格式编辑", "打印格式编辑 "
			    + $scope.print_fields[f.name] + " 修改成功！！",
			$scope, function(){
			    f.print = params.pformat.print.value;
			    f.width = params.pformat.width;
			});
		} else{
		    dialog.response(
			false, "打印格式编辑", "打印格式编辑失败："
			    + wprintService.error[state.ecode]); 
		}
	    })
	}; 

	var check_same = function(newValue){
	    if (newValue.print == f.print && newValue.width == f.width){
		return true;
	    }
	    return false;
	}

	var print_action = $scope.actions.filter(function(a){
	    return f.print === a.value;
	});

	var change_format = function(format){
	    // console.log(format);
	    if (format.print.value === 0){
		format.width = 0;
	    }
	}; 

	console.log(print_action);
	dialog.edit_with_modal(
	    "update-print-format.html", undefined, callback, $scope,
	    {
		pformat:    {name:f.name, print:print_action[0], width:f.width},
		fields:     $scope.print_fields,
		actions:    $scope.actions,
		// shops:      $scope.shops,
		check_same: check_same,
		change_format: change_format
	    });
    }
});


baseApp.controller("tableDetailCtrl", function($scope, baseService, diabloUtilsService){
    
    $scope.refresh = function(){
	baseService.list_setting(baseService.table_setting).then(function(data){
	    console.log(data);
	    diablo_order(data);
	    $scope.settings = data;
	})
    };

    $scope.refresh();


    var dialog = diabloUtilsService;
    $scope.update_setting = function(s){
	console.log(s);

	var callback = function(params){
	    console.log(params);

	    var setting = params.setting;
	    baseService.update_setting({
		id:    setting.id,
		ename: setting.ename,
		value: setting.value
	    }).then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    dialog.response_with_callback(
			true, "表格编辑", "表格编辑 " + s.cname + " 修改成功！！",
			$scope, function(){$scope.refresh()});
		} else{
		    dialog.response(
			false, "表格编辑", "表格编辑失败：" + baseService.error[state.ecode]); 
		}
	    })
	}; 
	
	dialog.edit_with_modal(
	    "table-setting.html", undefined, callback, $scope, {setting: s});
    }
});


baseApp.controller("basePrinterConnectNewCtrl", function(
    $scope, diabloPattern, wprintService, diabloUtilsService, user){

    $scope.shops = [].concat(user.sortShops, user.sortRepoes);

    $scope.paper_columns = wprintService.paper_columns;
    $scope.paper_heights = wprintService.paper_heights;
    
    $scope.printer = {
	column: $scope.paper_columns[0],
	height: $scope.paper_heights[0]
    }; 

    // printer
    wprintService.list_wprinter().then(function(printers){
	console.log(printers);
	$scope.brands = printers.map(function(p){
	    return {id      :p.id,
		    brand   :p.brand,
		    model   :p.model,
		    column  :p.col_width,
		    remark  :wprintService.get_chinese_brand(p.brand) + "，" + p.model}
	});
	
	if ($scope.brands.length !== 0){
	    $scope.printer.brand = $scope.brands[0];
	}
    });
    
    // server
    wprintService.list_wprint_server().then(function(servers){
	console.log(servers);
	$scope.servers = servers.map(function(s){
	    return {id: s.id, name:s.name}
	});
	
	if ($scope.servers.length !== 0){
	    $scope.printer.server = $scope.servers[0]
	};
    }); 

    $scope.new_printer = function(){
	console.log($scope.printer);
	wprintService.new_wprinter_conn($scope.printer).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		diabloUtilsService.response_with_callback(
	    	    true, "打印机关联",
		    "打印机 " + $scope.printer.sn + " 关联成功！！",
	    	    $scope,
		    function(){diablo_goto_page("#/printer/connect_detail");});
	    } else{
		diabloUtilsService.response(
	    	    false, "打印机关联",
	    	    "打印机关联失败：" + wprintService.error[state.ecode]);
	    };
	})
    };

    $scope.cancel = function(){
	diablo_goto_page("#/print/connect_detail");
    }
    
    
});


baseApp.controller("basePrinterConnectDetailCtrl", function(
    $scope, $q, $location, wprintService, diabloPromise, diabloUtilsService, user){

    // $scope.shops = user.sortShops;
    $scope.shops = [].concat(user.sortShops, user.sortRepoes);
    $scope.goto_page = diablo_goto_page;
    $scope.print_status = wprintService.print_status;
    
    var dialog = diabloUtilsService;

    $scope.refresh = function(){
	wprintService.list_wprinter_conn().then(function(printers){
	    console.log(printers); 
	    $scope.printers = printers;
	    angular.forEach($scope.printers, function(p){
		p.brand_chinese = wprintService.get_chinese_brand(p.brand)
	    });
	    diablo_order($scope.printers);
	});
    };
    

    $scope.refresh();

    $scope.test_printer = function(p){
	console.log(p);
	wprintService.test_printer(p).then(function(result){
	    console.log(result);
	    if (result.ecode === 0){
		dialog.response(
		    true, "打印机测试", "打印机测试成功，请等待打印！！", $scope);
	    } else{
		var error = "";
		angular.forEach(result.einfo, function(e){
		    console.log(wprintService.error[e.ecode]);
		    error += (e.device ? "[" + e.device + "]":"") + wprintService.error[e.ecode]
		});
		
		dialog.response(
		    false, "打印机测试", "打印机测试失败：" + error, $scope);
	    }
	})
    };

    // var get_object = function(id, objs){
    // 	for (var i=0, l=objs.length; i<l; i++){
    // 	    if (id === objs[i].id){
    // 		return objs[i];
    // 	    }
    // 	}
    // };
    
    $scope.update_printer = function(p){
	console.log(p);
	var has_update = function(new_printer){
	    // console.log(new_printer);
	    if (new_printer.server.id         === p.server_id
		&& new_printer.brand.id       === p.printer_id
		&& new_printer.shop.id        === p.shop_id
		&& new_printer.column         === p.pcolumn
		&& new_printer.height         === p.pheight
		&& new_printer.sn             === p.sn
		&& new_printer.key            === p.code
		&& new_printer.status.value   === p.status){
		return false;
	    }

	    return true;
	};
	
	var promise = diabloPromise.promise;
	$q.all([
	    promise(wprintService.list_wprint_server)(),
	    promise(wprintService.list_wprinter)(),
	    // promise(wprintService.list_shop_by_merchant, p.merchant_id)()
	]).then(function(result){
	    console.log(result);
	    // result[0] are the servers
	    // result[1] are the printers
	    // result[2] are the shops
	    var servers = result[0].map(function(s){
		return {id:s.id, name:s.name, path:s.path};
	    });

	    var brands = result[1].map(function(p){
		return {id      :p.id,
			brand   :p.brand,
			model   :p.model,
			column  :p.col_width,
			remark  :wprintService.get_chinese_brand(p.brand) + "，" + p.model
		       }
	    });
	    
	    // var shops = result[2].map(function(s){
	    // 	return {id:s.id, name:s.name, py:diablo_pinyin(s.name)};
	    // });
	    var get_object = diablo_get_object;
	    var printer = {
		// servers: servers,
		// brands : brands,
		// shops:   shops,
		status:  $scope.print_status.filter(
		    function(s) {
			return s.value===p.status
		    })[0],
		server:  get_object(p.server_id, servers),
		brand:   get_object(p.printer_id, brands), 
		shop:    get_object(p.shop_id, $scope.shops),
		column:  p.pcolumn,
		height:  p.pheight,
		sn:      p.sn,
		key:     p.code, 
	    };

	    var callback = function(params){
	        console.log(params);

		var update = {id: p.id};
		for (var o in params.printer){
		    if (!angular.equals(params.printer[o], printer[o])){
			update[o] = params.printer[o];
		    }
		}

		console.log(update);

		wprintService.update_wprinter_conn(update).then(function(result){
		    console.log(result);
		    if (result.ecode == 0){
			dialog.response_with_callback(
			    true, "打印机编辑", "打印机关联信息修改成功！！",
			    $scope, function(){$scope.refresh()});
    		    } else{
			dialog.response(
			    false, "打印机编辑",
			    "打印机关联信息编辑失败：" + wprintService.error[result.ecode]);
    		    }
		})
	    };
	    
	    dialog.edit_with_modal(
	        "update-printer.html", undefined, callback, $scope,
		{has_update: has_update,
		 paper_columns: wprintService.paper_columns,
		 paper_heights: wprintService.paper_heights,
		 servers: servers,
		 brands:  brands,
		 shops:   $scope.shops,
		 status:  $scope.print_status, 
		 printer: printer});
	}) 
	
    };

    $scope.delete_printer = function(printer){
	var callback = function(){
	    wprintService.delete_wprinter_conn(printer.id).then(function(result){
		console.log(result);
		if (result.ecode == 0){
		    dialog.response_with_callback(
			true, "删除关联", "打印机 [" + printer.sn + "] 关联信息成功删除！！",
			$scope, function(){$scope.refresh()})
		} else{
		    dialog.response(
			false, "删除关联",
			"删除打印机关联信息失败：" + wprintService.error[result.ecode], $scope);
		}
	    })
	};
	
	dialog.request(
	    "删除打印机关联信息", "确定要删除该打印机关联信息吗？", callback, undefined, $scope);
    }
});


baseApp.controller("resetPasswdCtrl", function(
    $scope, diabloPattern, diabloUtilsService, baseService){
    $scope.passwd_pattern = diabloPattern.passwd;

    var dialog = diabloUtilsService;

    $scope.ok = function(){
	console.log($scope.p);

	if ($scope.p.newp !== $scope.p.checkp){
	    dialog.response(
		false, "密码重置", "密码重置失败：两次输入密码不匹配，请重新输入！！", undefined);
	} else {
	    baseService.reset_passwd($scope.p).then(function(result){
		console.log(result);
		if (result.ecode == 0){
		    dialog.response(
			true, "密码重置", "密码重置成功！！", undefined);
		} else{
		    dialog.response(
			false, "密码重置失败", "密码重置失败："
			    + baseService.error[result.ecode], undefined);
		}
	    });
	}
    }
});

baseApp.controller("baseCtrl", function($scope){
    // diablo_goto_page("#/printer/connect_detail");
});

baseApp.controller("loginOutCtrl", function($scope, $resource){
    $scope.home = function () {
	diablo_login_out($resource)
    };
    
    // $scope.max_screen = function(){
    // 	console.log("max_screen");
    // }
});
