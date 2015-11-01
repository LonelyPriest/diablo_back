"use strict";
var wsaleApp = angular.module(
    'wsaleApp',
    ['ui.bootstrap', 'ngRoute', 'ngResource',
     'diabloAuthenApp', 'diabloPattern', 'diabloUtils',
     'userApp', 'employApp', 'wretailerApp', 'purchaserApp'])
    .config(function(localStorageServiceProvider){
	localStorageServiceProvider
	    .setPrefix('wsaleApp')
	    .setStorageType('localStorage')
	    .setNotify(true, true)
    }) 
    .config(function($httpProvider, authenProvider){
	// console.log(authenProvider);
	// $httpProvider.responseInterceptors.push(authenProvider.interceptor);
	$httpProvider.interceptors.push(authenProvider.interceptor); 
    })
    .run(['$route', '$rootScope', '$location',
	  function ($route, $rootScope, $location) {
	      var original = $location.path;
	      $location.path = function (path, reload) {
		  if (reload === false) {
		      var lastRoute = $route.current;
		      var un = $rootScope.$on(
			  '$locationChangeSuccess',
			  function () {
			      $route.current = lastRoute;
			      un();
			  });
		  }
		  return original.apply($location, [path]);
	      };
	  }]);

wsaleApp.config(['$routeProvider', function($routeProvider){
    // $locationProvider.html5Mode(true);
    var user = {"user": function(userService){
	return userService()}}; 

    var brand = {"filterBrand": function(diabloFilter){
	return diabloFilter.get_brand()}};
    
    var firm = {"filterFirm": function(diabloFilter){
	return diabloFilter.get_firm()}}; 
    
    var type = {"filterType": function(diabloFilter){
	return diabloFilter.get_type()}};

    var employee = {"filterEmployee": function(diabloFilter){
	return diabloFilter.get_employee()}};

    var retailer = {"filterRetailer": function(diabloFilter){
	return diabloFilter.get_wretailer()}};

    var color = {"filterColor": function(diabloFilter){
	return diabloFilter.get_color()}};
    
    var s_group = {"filterSizeGroup": function(diabloFilter){
	return diabloFilter.get_size_group()}};

    var base = {"base": function(diabloNormalFilter){
	return diabloNormalFilter.get_base_setting()}};
    
    $routeProvider. 
	when('/new_wsale', {
	    templateUrl: '/private/wsale/html/new_wsale.html',
	    controller: 'wsaleNewCtrl',
	    resolve: angular.extend(
	    	{}, user, firm, retailer, employee, s_group, brand, type, color, base)
	}).
	when('/new_wsale_detail/:page?', {
	    templateUrl: '/private/wsale/html/new_wsale_detail.html',
	    controller: 'wsaleNewDetailCtrl',
	    resolve: angular.extend({}, user, retailer, employee, base) 
	}).
	when('/update_wsale_detail/:rsn?/:ppage?', {
	    templateUrl: '/private/wsale/html/update_wsale_detail.html',
	    controller: 'wsaleUpdateDetailCtrl',
	    resolve: angular.extend({}, user, retailer, employee, s_group, brand, color, type, base)
	}). 
	when('/wsale_rsn_detail/:rsn?/:ppage?', {
	    templateUrl: '/private/wsale/html/wsale_rsn_detail.html',
	    controller: 'wsaleRsnDetailCtrl',
	    resolve: angular.extend(
		{}, user, brand, retailer, employee, firm, s_group, type, color, base)
	}).
	when('/reject_wsale', {
	    templateUrl: '/private/wsale/html/reject_wsale.html',
	    controller: 'wsaleRejectCtrl',
	    resolve: angular.extend({}, user, retailer, employee, s_group, color, base) 
	}).
	when('/update_wsale_reject/:rsn?/:ppage?', {
	    templateUrl: '/private/wsale/html/update_wsale_reject.html',
	    controller: 'wsaleUpdateRejectCtrl',
	    resolve: angular.extend({}, user, retailer, employee, s_group, brand, color, type, base)
	}). 
	when('/wsale_print_preview/:rsn?', {
	    templateUrl: '/private/wsale/html/wsale_print_preview.html',
	    controller: 'wsalePrintPreviewCtrl',
	    resolve: angular.extend({}, retailer, s_group, base) 
	}).
	// when('/wsale/reject_wsale_detail', {
	//     templateUrl: '/private/wsale/html/reject_wsale_detail.html',
	//     controller: 'wsaleRejectDetailCtrl',
	//     resolve: angular.extend({}, user, retailer, employee) 
	// }).
	// otherwise({
	//     templateUrl: '/private/wsale/html/wsale_guide.html',
	//     controller: 'wsaleGuideCtrl'
        // }) 
	otherwise({
	    templateUrl: '/private/wsale/html/new_wsale_detail.html',
	    controller: 'wsaleNewDetailCtrl',
	    resolve: angular.extend({}, user, retailer, employee, base)
        })
}]);

wsaleApp.service("wsaleService", function($http, $resource, dateFilter){
    this.error = {
	2190: "该款号库存不存在！！请确认本店是否进货该款号！！",
	2191: "该货号已存在，请选择新的货号！！",
	2192: "客户或营业员不存在，请建立客户或营业员资料！！", 
	2401: "店铺打印机不存在或打印处理暂停状态！！",
	
	2411: "打印机编号错误！！",
	2412: "服务器处理订单失败！！", 
	2413: "打印内容太长！！",
    	2414: "打印请求参数错误！！",
	2415: "打印请求超时，请稍后再试或联系服务人员！！",
	2416: "未知原因，请系统服务人员！！",
	
	2417: "发送打印请求失败，请确保网络通畅！！",
	
	2418: "打印机打印失败，请联系服务人员查找原因！！",
	2419: "打印机未连接！！",
	2420: "打印机缺纸！！",
	2421: "打印状态未知，请联系服务人员！！",
	2422: "打印机连接设备不存在，请检查设备编号是否正确！！",
	2423: "打印格式缺少尺码，请在打印格式设置中选中尺码！！",
	2601: "获取零售商历史记录失败！！",
	2701: "文件导出失败，请重试或联系服务人员查找原因！！",
	2702: "文件导出失败，没有任何数据需要导出，请重新设置查询条件！！",
	2699: "修改前后信息一致，请重新编辑修改项！！",
	9001: "数据库操作失败，请联系服务人员！！"};

    this.rsn_title = ["开单明细", "退货明细", "销售明细"];

    this.direct = {wsale: 0, wreject: 1};

    this.wsale_mode = [
	{title: "普通模式"},
	{title: "图片模式"},
	{title: "新增货品"}
    ];

    this.extra_pay_types = [
	{id:0, name: "代付运费"}, 
	{id:1, name: "样衣"},
	{id:2, name: "少配饰"},
	{id:3, name: "代付现金"},
	{id:4, name: "初期欠款"}
	
    ];

    this.export_type = {trans:0, trans_note:1};
    
    // =========================================================================
    var http = $resource("/wsale/:operation/:id",
    			 {operation: '@operation', id: '@id'},
			 {
			     query_by_post: {method: 'POST', isArray: true}
			 });

    this.new_w_sale = function(inventory){
	return http.save({operation: "new_w_sale"}, inventory).$promise;
    };

    this.update_w_sale_new = function(inventory){
	return http.save({operation: "update_w_sale"}, inventory).$promise;
    };

    this.check_w_sale_new = function(rsn){
	return http.save({operation: "check_w_sale"},
			 {rsn: rsn}).$promise;
    };

    this.new_w_sale_draft = function(inventory){
	return http.save({operation: "new_w_sale_draft"}, inventory).$promise;
    };

    this.print_w_sale = function(rsn){
	return http.save({operation: "print_w_sale"}, {rsn:rsn}).$promise;
    };
    

    this.filter_w_sale_image = function(match, fields, currentPage, itemsPerpage){
	return http.save({operation: "filter_w_sale_image"},
			 {match:  angular.isDefined(match) ? match.op : undefined,
			  fields: fields,
			  page:   currentPage,
			  count:  itemsPerpage}).$promise;
    };
    
    // this.list_w_sale_new = function(condition){
    // 	return http.query_by_post({operation: "list_w_sale_new"}, condition).$promise;
    // }

    this.filter_w_sale_new = function(match, fields, currentPage, itemsPerpage){
	return http.save({operation: "filter_w_sale_new"},
			 {match:  angular.isDefined(match) ? match.op : undefined,
			  fields: fields,
			  page:   currentPage,
			  count:  itemsPerpage}).$promise;
    };

    this.filter_w_sale_rsn_group = function(match, fields, currentPage, itemsPerpage){
	return http.save({operation: "filter_w_sale_rsn_group"},
			 {match:  angular.isDefined(match) ? match.op : undefined,
			  fields: fields,
			  page:   currentPage,
			  count:  itemsPerpage}).$promise;
    };

    this.get_w_sale_new = function(rsn){
	return http.get({operation: "get_w_sale_new", id:rsn}).$promise;
    };

    this.get_w_print_content = function(rsn){
	return http.get({operation: "get_w_print_content", id:rsn}).$promise;
    };

    this.list_w_sale_draft = function(shop){
	return http.query_by_post({operation: "list_w_sale_draft"}, shop).$promise;
    };

    this.get_w_sale_draft = function(draft_sn){
	return http.save({operation: "get_w_sale_draft"}, draft_sn).$promise;
    }; 

    this.reject_w_sale = function(inventory){
	return http.save({operation: "reject_w_sale"}, inventory).$promise;
    };

    this.filter_w_sale_reject = function(match, fields, currentPage, itemsPerpage){
	return http.save({operation: "filter_w_sale_reject"},
			 {match:  angular.isDefined(match) ? match.op : undefined,
			  fields: fields,
			  page:   currentPage,
			  count:  itemsPerpage}).$promise;
    };

    this.get_last_sale = function(inv){
	return http.query_by_post({operation: "get_last_sale"},
				  {style_number: inv.style_number,
				   brand:        inv.brand,
				   shop:         inv.shop,
				   retailer:     inv.retailer}).$promise;
    };

    this.w_sale_rsn_detail = function(inv){
	return http.save(
	    {operation: "w_sale_rsn_detail"},
	    {rsn:inv.rsn, style_number:inv.style_number, brand:inv.brand}).$promise;
    };

    this.csv_export = function(e_type, condition){
	return http.save({operation: "w_sale_export"},
			 {condition: condition, e_type:e_type}).$promise;
    };
    
});

wsaleApp.controller("wsaleNewCtrl", function(
    $scope, $q, $timeout, dateFilter, localStorageService,
    diabloUtilsService, diabloPromise, diabloFilter, diabloNormalFilter,
    diabloPattern, wgoodService, purchaserService, 
    wretailerService, wsaleService, wsaleGoodService,
    user, filterFirm, filterRetailer, filterEmployee,
    filterSizeGroup, filterBrand, filterType, filterColor, base){

    $scope.pattern  = {money: diabloPattern.decimal_2,
		       sell:  diabloPattern.integer_except_zero};
    
    $scope.timeout_auto_save = undefined;
    $scope.round             = diablo_round;
    
    $scope.back  = function(){
	diablo_goto_page("#/new_wsale_detail");
    };

    $scope.setting = {q_backend     :true,
		      show_discount :true,
		      check_sale    :true,
		      trace_price   :true,
		      round         :diablo_round_record};

    // all right of user
    // console.log(user); 
    // console.log(base); 

    //  var user = wsaleGoodService.get_user();
    //  var filterFirm = wsaleGoodService.get_firm();
    //  var filterRetailer = wsaleGoodService.get_retailer();
    //  var filterEmployee = wsaleGoodService.get_employee();
    //  var filterSizeGroup = wsaleGoodService.get_size_group();
    //  var base = wsaleGoodService.get_base(); 

    wsaleGoodService.set_brand(angular.copy(filterBrand));
    wsaleGoodService.set_type(angular.copy(filterType));
    wsaleGoodService.set_size_group(angular.copy(filterSizeGroup));
    wsaleGoodService.set_firm(angular.copy(filterFirm));
    wsaleGoodService.set_color(angular.copy(filterColor));

    // base setting
    $scope.trace_price = function(shopId){
	return diablo_base_setting(
	    "ptrace_price", shopId, base, parseInt, diablo_no); 
    };

    $scope.immediately_print = function(shopId){
	return diablo_base_setting(
	    "pim_print", shopId, base, parseInt, diablo_no); 
    };

    $scope.q_typeahead = function(){
	// default prompt comes from backend
	return diablo_base_setting(
	    "qtypeahead", $scope.select.shop.id, base, parseInt, diablo_yes);
    };
    // console.log($scope.q_typeahead); 

    $scope.show_discount = function(){
	return diablo_base_setting(
	    "show_discount", $scope.select.shop.id, base, parseInt, diablo_yes);
    };

    $scope.p_round = function(){
	return diablo_base_setting(
	    "pround", $scope.select.shop.id, base, parseInt, diablo_round_record);
    };

    $scope.check_sale = function(shopId){
	return diablo_base_setting(
	    "check_sale", shopId, base, parseInt, diablo_yes);
    };
    
    // $scope.qtime_length = function(shopId){
    // 	return diablo_base_setting("qtime_length", shopId, base, diablo_yes);
    // }();

    

    // console.log($scope.q_typeahead);
    
    $scope.sexs            = diablo_sex;
    $scope.seasons         = diablo_season;
    $scope.f_add           = diablo_float_add;
    $scope.f_sub           = diablo_float_sub;
    $scope.f_mul           = diablo_float_mul;
    $scope.wsale_mode      = wsaleService.wsale_mode;
    $scope.extra_pay_types = wsaleService.extra_pay_types; 
    $scope.disable_refresh = true;
    
    $scope.select = {
	cash: undefined,
	card: undefined,
	wire: undefined,
	verificate: undefined,
	extra_pay: undefined,
	
	total: 0,
	abs_total: 0,
	has_pay: 0.00,
	should_pay: 0.00,
	extra_pay_type: $scope.extra_pay_types[0],
	// extra_pay: 0.00
    }; 

    // console.log($scope.select);
    
    

    // $scope.format_v = function(v){
    // 	if (angular.isUndefined(v) || isNaN(v) || !v){
    // 	    return 0.00;
    // 	} else{
    // 	    return parseFloat(v)
    // 	}
    // }

    // shops
    $scope.shops = user.sortShops;
    if ($scope.shops.length !== 0){
	$scope.select.shop = $scope.shops[0]; 
	$scope.setting.trace_price = $scope.trace_price($scope.select.shop.id);
	$scope.setting.check_sale = $scope.check_sale($scope.select.shop.id);
	wsaleGoodService.set_shop($scope.select.shop.id);
    }
    
    $scope.find_shop = function(shopId){
	for(var i=0, l=$scope.shops.length; i<l; i++)
	    if(shopId === $scope.shops[i].id){
		return $scope.shops[i];
	    }
    }

    $scope.change_shop = function(){
	$scope.local_save();
	$scope.setting.trace_price = $scope.trace_price($scope.select.shop.id);
	$scope.setting.check_sale = $scope.check_sale($scope.select.shop.id);
	$scope.setting.show_discount = $scope.show_discount();
	$scope.setting.round         = $scope.p_round();
	
	wsaleGoodService.set_shop($scope.select.shop.id);
    } 

    // employees
    $scope.employees = filterEmployee;
    if ($scope.employees.length !== 0){
	$scope.select.employee = $scope.employees[0];
    }
    
    $scope.find_employee = function(number){
	for(var i=0, l=$scope.employees.length; i<l; i++)
	    if(number === $scope.employees[i].id){
		return $scope.employees[i];
	    }
    };

    // retailer;
    $scope.retailers = filterRetailer;
    if ($scope.retailers.length !== 0){
	$scope.select.retailer = $scope.retailers[0];
	var balance = $scope.select.retailer.balance;
	$scope.select.surplus = angular.isDefined(balance)
	    && !isNaN(balance) && balance ? parseFloat($scope.select.retailer.balance) : 0;
	$scope.select.left_balance = $scope.select.surplus;
    };
    
    $scope.find_retailer = function(retailerId){
	for(var i=0, l=$scope.retailers.length; i<l; i++)
	    if($scope.retailers[i].id === retailerId){
		return $scope.retailers[i];
	    }
    }

    $scope.change_retailer = function(){
	var balance = $scope.select.retailer.balance;
	$scope.select.surplus = angular.isDefined(balance)
	    && !isNaN(balance) && balance ? parseFloat($scope.select.retailer.balance) : 0;
	// $scope.select.surplus = parseFloat($scope.select.retailer.balance);
	$scope.local_save();
	$scope.re_calculate();
	// image mode, refresh image
	if ($scope.wsale_mode[1].active){
	    $scope.page_changed($scope.current_page); 
	}
    }

    $scope.add_retailer = function(){
	var callback = function(params){
	    console.log(params); 
	    var retailer = {
		name:    params.retailer.name,
		mobile:  params.retailer.mobile,
		address: params.retailer.address};
	    wretailerService.new_wretailer(retailer).then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    var append_retailer = function(RetailerId){
			var newRetailer = {
			    name    :retailer.name,
			    id      :RetailerId,
			    py      :diablo_pinyin(retailer.name),
			    balance :0};
			
			$scope.retailers.push(newRetailer);
			$scope.select.retailer = newRetailer;
			$scope.change_retailer();
		    }
		    diabloUtilsService.response_with_callback(
	    		true, "新增零售商",
			"零售商 " + retailer.name + " 成功创建！！",
	    		$scope,
			function(){append_retailer(state.id)});
		} else{
		    diabloUtilsService.response(
	    		false, "新增零售商",
	    		"新增零售商失败：" + wretailerService.error[state.ecode]);
		};
	    })
	}
	diabloUtilsService.edit_with_modal(
	    "new-retailer.html", undefined, callback, $scope, {retailer: {}});
    };
    
    $scope.refresh = function(){
	$scope.inventories = [];
	$scope.inventories.push({$edit:false, $new:true});
	// $scope.sexs = diablo_sex;
	// $scope.seasons = diablo_season;
	$scope.select.form.cardForm.$invalid  = false;
	$scope.select.form.cashForm.$invalid  = false;
	$scope.select.form.vForm.$invalid     = false;
	$scope.select.form.wireForm.$invalid  = false;
	$scope.select.form.extraForm.$invalid = false;

	$scope.select.cash       = undefined;
	$scope.select.card       = undefined;
	$scope.select.verificate = undefined;
	$scope.select.wire       = undefined;
	$scope.select.extra_pay  = undefined;
	
	$scope.select.has_pay    = 0.00;
	$scope.select.should_pay = 0.00;

	$scope.select.total     = 0;
	$scope.select.abs_total = 0;
	$scope.select.comment = undefined;
	$scope.select.left_balance = $scope.select.surplus;

	$scope.disable_refresh = true;
	$scope.has_saved = false;

	// $scope.get_retailer(); 
    }; 

    var now = $.now();
    $scope.qtime_start = function(shopId){
	return diablo_base_setting(
	    "qtime_start", shopId, base, function(v){return v},
	    dateFilter(diabloFilter.default_start_time(now), "yyyy-MM-dd"));
    };
    // console.log($scope.qtime_start);

    $scope.setting.show_discount = $scope.show_discount();
    $scope.setting.round         = $scope.p_round();

    $scope.setting.q_backend = $scope.q_typeahead($scope.select.shop.id);
    if (!$scope.setting.q_backend){
	diabloNormalFilter.match_all_w_inventory(
	    {shop:$scope.select.shop.id,
	     start_time:$scope.qtime_start($scope.select.shop.id)}
	).$promise.then(function(invs){
	    // console.log(invs);
	    $scope.all_w_inventory = 
		invs.map(function(inv){
		    return angular.extend(
			inv, {name:inv.style_number + "，" + inv.brand + "，" + inv.type})
		})
	});
    };

    console.log($scope.setting);
    
    // init
    // $scope.refresh();
    $scope.inventories = [];
    $scope.inventories.push({$edit:false, $new:true});

    
    // calender
    $scope.open_calendar = function(event){
	event.preventDefault();
	event.stopPropagation();
	$scope.isOpened = true;
    };

    $scope.today = function(){
	return $.now();
    }

    // local save
    /*
     * draft
     */
    var key_re = /^ws-[0-9-]+$/; 
    var current_key = function(){
	return "ws-" + $scope.select.retailer.id.toString()
	    + "-" + $scope.select.shop.id.toString()
	    + "-" + $scope.select.employee.id.toString();
    };

    var draft_keys = function(){
	var keys = localStorageService.keys();
	return keys.filter(function(k){
	    return key_re.test(k); 
	});
    };

    $scope.local_save = function(){
	var key = current_key();
	// var now = $.now();
	localStorageService.set(
	    key,
	    {t:now, v:$scope.inventories.filter(function(inv){
		return inv.$new === false;})
	    }) 
    };

    $scope.local_remove = function(){
	var key = current_key();
	localStorageService.remove(key);
    }

    $scope.disable_draft = function(){

	if (draft_keys().length === 0){
	    return true;
	}
	
	if ($scope.inventories.length !== 1){
	    return true;
	};
	
	return false;
    };
    
    $scope.list_draft = function(){
	
	var key_fix = draft_keys();
	
	// console.log(key); 
	var drafts = key_fix.map(function(k){
	    var p = k.split("-");
	    return {sn:k,
		    retailer:diablo_get_object(parseInt(p[1]), $scope.retailers),
		    shop:diablo_get_object(parseInt(p[2]), $scope.shops),
		    employee:diablo_get_object(p[3], $scope.employees),
		   }
	});

	// console.log(drafts) 
	var callback = function(params){
	    var select_draft = params.drafts.filter(function(d){
		return angular.isDefined(d.select) && d.select
	    })[0];

	    // console.log($scope.select);
	    $scope.select.retailer =
		diablo_get_object(select_draft.retailer.id, $scope.retailers);
	    $scope.select.shop =
		diablo_get_object(select_draft.shop.id, $scope.shops);
	    $scope.select.employee =
		diablo_get_object(select_draft.employee.id, $scope.employees);
	    
	    var one = localStorageService.get(select_draft.sn);
	    
	    if (angular.isDefined(one) && null !== one){
	        $scope.inventories = angular.copy(one.v);
	        console.log($scope.inventories); 
	        $scope.inventories.unshift({$edit:false, $new:true});

		$scope.disable_refresh = false;
	        $scope.re_calculate();
		
	        // $scope.draft = true;
	    } 
	}

	console.log(drafts);
	diabloUtilsService.edit_with_modal(
	    "wsale-draft.html", undefined, callback, $scope,
	    {drafts:drafts,
	     valid: function(drafts){
		 for (var i=0, l=drafts.length; i<l; i++){
		     if (angular.isDefined(drafts[i].select) && drafts[i].select){
			 return true;
		     }
		 } 
		 return false;
	     },
	     select: function(drafts, d){
		 for (var i=0, l=drafts.length; i<l; i++){
		     if (d.sn !== drafts[i].sn){
			 drafts[i].select = false;
		     }
		 }
	     }
	    }); 
    }; 
    
    $scope.match_style_number = function(viewValue){
	return diabloFilter.match_w_sale(viewValue, $scope.select.shop.id);
    } 

    $scope.sell_styles = diablo_sell_style;

    // console.log($scope.sell_styles);

    $scope.get_sell_style = function(id){
	for (var i=0, l=$scope.sell_styles.length; i<l; i++){
	    if ($scope.sell_styles[i].id === id){
		return $scope.sell_styles[i];
	    }
	}
    }; 

    $scope.copy_select = function(add, src){
	add.id           = src.id;
	add.style_number = src.style_number;
	add.brand        = src.brand;
	add.brand_id     = src.brand_id;
	add.type_id      = src.type_id;
	add.type         = src.type;
	add.type_id      = src.type_id;
	add.firm_id      = src.firm_id;
	add.sex          = src.sex;
	add.season       = src.season;
	add.year         = src.year;

	// add.org_price    = good.org_price;
	add.tag_price    = src.tag_price;
	add.pkg_price    = src.pkg_price;
	add.price3       = src.price3;
	add.price4       = src.price4;
	add.price5       = src.price5;
	add.discount     = src.discount;
	add.path         = src.path;
	
	add.s_group      = src.s_group;
	add.free         = src.free;
	// default is pkg_price
	// add.sell_style   = $scope.sell_styles[1];
	add.sell_style   = $scope.sell_styles[0];
	// add.amount       = []; 
	// if ( (add.all_colors.length === 1 && add.all_colors[0] === "0")
	//      && (add.all_sizes.length === 1 && add.all_sizes[0] === "0") ){
	//     add.free_color_size = true;
	//     // add.amount = [{cid:0, size:0}];
	// } else{
	//     add.free_color_size = false;
	//     // add.amount = [];
	// }
	return add;
	
    };
    
    $scope.on_select_good = function(item, model, label){
	console.log(item);

	// one good can be add only once at the same time
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    if (item.style_number === $scope.inventories[i].style_number
		&& item.brand_id  === $scope.inventories[i].brand_id){
		diabloUtilsService.response_with_callback(
		    false, "销售开单", "开单失败：" + wsaleService.error[2191],
		    $scope, function(){ $scope.inventories[0] = {$edit:false, $new:true}});
		return;
	    }
	}; 
	
	// add at first allways 
	var add = $scope.inventories[0];
	add = $scope.copy_select(add, item); 

	console.log(add); 
	$scope.add_inventory(add);
	
	return;
    };

    
    /*
     * image mode
     */
    // filter
    $scope.filters = [];
    diabloFilter.reset_field();
    // diabloFilter.add_field("firm", filterFirm);
    diabloFilter.add_field("brand", wsaleGoodService.get_brand());
    diabloFilter.add_field("type",  wsaleGoodService.get_type());

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();
    $scope.time   = diabloFilter.default_time();

    // tale
    $scope.default_image_column = 6;
    $scope.default_image_row = 2;
    $scope.colspan = $scope.default_image_column;
    // $scope.image_inventories = [];
    $scope.items_perpage = 12;
    $scope.max_page_size = 10; 
    // default the first page
    $scope.default_page = 1;
    $scope.current_page = $scope.default_page;
    var last_image_page = 0;
    var last_select_shop = 0;
    var last_select_retailer = 0;
    
    $scope.row_range = diablo_range($scope.default_image_row).map(function(r){
	return r - 1;
    });
    
    $scope.select_image = function(inv){
	$scope.on_select_good(inv);
    } 
    
    $scope.image_mode = function(page){
	if (page !== last_image_page
	    || last_select_shop !== $scope.select.shop.id
	    || last_select_retailer !== $scope.select.retailer.id){
	    $scope.page_changed(page); 
	}
    };

    $scope.do_search = function(page){
	$scope.page_changed(page);
    };
    
    $scope.page_changed = function(page){
	console.log(page);
	// purchaserService.filter_purchaser_inventory_group(
	//     undefined, {shop: $scope.select.shop.id},
	//     page, $scope.items_perpage
	// ).then(function(result){

	if (angular.isUndefined($scope.select.retailer)
	    || diablo_is_empty($scope.select.retailer)){
	    diabloUtilsService.response(
		false, "销售开单", "开单失败：" + wsaleService.error[2192]);
	    return;
	};
	
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    search.shop = $scope.select.shop.id;
	    search.retailer = $scope.select.retailer.id;
	    
	    wsaleService.filter_w_sale_image(
		$scope.match, search, page, $scope.items_perpage
	    ).then(function(result){
		console.log(result);
		if (result.ecode == 0){
		    if (page === 1){
			$scope.total_items = result.total;
		    }

		    // get sale history of retailer
		    // $scope.retailer_sale_history = result.history;
		    
		    // grouping
		    $scope.image_inventories = [];
		    var row     = $scope.default_image_row; 
    		    var column  = $scope.default_image_column;
		    var history = result.history;
		    var data    = result.data;
		    for (var i=0; i<row; i++){
			var r = [];
			for(var j=0; j<column; j++){
			    // console.log(i * column + j);
			    var index = i * column + j;
			    if (index >= data.length){
    	            		break;
    			    }

			    for(var k=0, l=history.length; k<l; k++){
				if ( data[index].style_number === history[k].style_number
				     && data[index].brand_id === history[k].brand ){
				    // console.log(data[index]);
				    data[index].history = true;
				}
			    }
    			    r.push(data[index]); 
    			}

			// console.log(r);
			$scope.image_inventories[i] = r;
		    }

		    console.log($scope.image_inventories);
		    last_image_page = page;
		    last_select_shop = $scope.select.shop.id;
		    last_select_retailer = $scope.select.retailer.id;
		} else{
		    diabloUtilsService.response(
			false, "获取库存",
			"获取库存失败：" + wsaleService.error[result.ecode], $scope)
		}
		
	    })
	})
    };
    
    /*
     * save all
     */
    $scope.disable_save = function(){
	// save one time only
	if ($scope.has_saved || $scope.draft){
	    return true;
	};

	// if ($scope.select.form.cardForm.$invalid
	//     || $scope.select.form.cashForm.$invalid
	//     || $scope.select.form.vForm.$invalid
	//     || $scope.select.form.wireForm.$invalid){
	//     return true;
	// };

	// console.log($scope.select);
	// any payment of cash, card or wire or any inventory
	if (angular.isDefined($scope.select.cash) && $scope.select.cash
	    || angular.isDefined($scope.select.card) && $scope.select.card
	    || angular.isDefined($scope.select.wire) && $scope.select.wire
	    || angular.isDefined($scope.select.verificate) && $scope.select.verificate
	    || angular.isDefined($scope.select.extra_pay) && $scope.select.extra_pay
	    || $scope.inventories.length !== 1){
	    return false;
	}
	
	
	// if ($scope.inventories.length === 1){
	//     return true;
	// };

	return true;
    }; 

    $scope.recover_sell_style = function(inv){
	
	if (inv.recover){
	    // console.log("recover");
	    return $scope.get_sell_style(inv.sell_style_id);
	}

	return inv.sell_style;
    } 
    
    $scope.save_wsale = function(){
	$scope.has_saved = true; 
	console.log($scope.inventories); 
	// console.log($scope.select);
	if (angular.isUndefined($scope.select.retailer)
		|| diablo_is_empty($scope.select.retailer)
		|| angular.isUndefined($scope.select.employee)
		|| diablo_is_empty($scope.select.employee)){
		diabloUtilsService.response(
		    false, "销售开单", "开单失败：" + wsaleService.error[2192]);
		return;
	};
	
	var get_sales = function(amounts){
	    var sale_amounts = [];
	    var batch = [];
	    for(var i=0, l=amounts.length; i<l; i++){
		var a = amounts[i];
		if (angular.isDefined(a.sell_count) && a.sell_count){
		    var new_a = {
			cid:        a.cid,
			size:       a.size, 
			sell_count: parseInt(amounts[i].sell_count)};
		    
		    if (angular.isDefined(a.batch) && a.batch){
			if (!in_array(batch, parseInt(a.batch))){
			    batch.push(parseInt(a.batch)); 
			}
		    }
		    
		    sale_amounts.push(new_a); 
		}
	    }; 

	    return {amounts:sale_amounts,
		    hand: batch.length === 1 ? batch[0] : undefined};
	};

	var setv = diablo_set_float;
	var seti = diablo_set_integer;
	var sets = diablo_set_string;
	
	var added = [];
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    var add = $scope.inventories[i];
	    // var batch = add.batch;
	    // console.log(batch);
	    var amount_info = get_sales(add.amounts);
	    added.push({
		id          : add.id,
		style_number: add.style_number,
		brand       : add.brand_id,
		brand_name  : add.brand,
		type        : add.type_id,
		type_name   : add.type,
		firm        : add.firm_id,
		sex         : add.sex,
		season      : add.season,
		year        : add.year,
		sell_total  : parseInt(add.sell),
		hand        : amount_info.hand,
		fdiscount   : seti(add.fdiscount),
		fprice      : setv(add.fprice),
		path        : sets(add.path),

		sizes       : add.sizes,
		s_group     : add.s_group,
		colors      : add.colors,
		free        : add.free,
		comment     : sets(add.comment),
		
		sell_style  : add.sell_style.id,
		// draft 
		// amounts     : $scope.draft || immediately ? add.amounts   : amount_info.amounts,
		amounts     : amount_info.amounts,
		// type_name   : $scope.draft ? add.type      : undefined,
		// tag_price   : $scope.draft || immediately ? add.tag_price : undefined,
		// pkg_price   : $scope.draft || immediately ? add.pkg_price : undefined,
		// price3      : $scope.draft || immediately ? add.price3    : undefined,
		// pricd4      : $scope.draft || immediately ? add.price4    : undefined,
		// price5      : $scope.draft || immediately ? add.price5    : undefined, 
	    })
	}; 

	// console.log($scope.select);
	var e_pay = setv($scope.select.extra_pay);
	var im_print = $scope.immediately_print($scope.select.shop.id);

	// console.log(im_print);
	var base = {
	    retailer:       $scope.select.retailer.id,
	    shop:           $scope.select.shop.id,
	    datetime:       dateFilter($scope.select.date, "yyyy-MM-dd HH:mm:ss"),
	    employee:       $scope.select.employee.id,
	    comment:        sets($scope.select.comment),
	    balance:        setv($scope.select.surplus),
	    
	    cash:           setv($scope.select.cash),
	    card:           setv($scope.select.card),
	    wire:           setv($scope.select.wire),
	    verificate:     setv($scope.select.verificate),
	    should_pay:     setv($scope.select.should_pay),
	    has_pay:        setv($scope.select.has_pay),

	    e_pay_type:     angular.isUndefined(e_pay) ? undefined : $scope.select.extra_pay_type.id,
	    e_pay:          e_pay,
	    
	    // left_balance:  parseFloat($scope.select.left_balance),
	    total:         seti($scope.select.total)
	};

	var print = {
	    im_print:    im_print,
	    shop:        $scope.select.shop.name,
	    employ:      $scope.select.employee.name,
	    retailer_id: $scope.select.retailer.id,
	    retailer:    $scope.select.retailer.name
	};

	console.log(added);
	console.log(base);

	// console.log(print === diablo_yes);

	var dialog = diabloUtilsService; 
	wsaleService.new_w_sale({
	    inventory:added.length === 0 ? undefined : added,
	    base:base, print:print
	}).then(function(result){
	    console.log(result);
	    var rsn = result.rsn;

	    var print = function(result){
		var messsage = "";
		if (result.pcode == 0){
		    messsage = "成功！！单号：" + rsn + "，请等待服务器打印";
		} else {
		    if (result.pinfo.length === 0){
			messsage += wsaleService.error[result.pcode]
		    } else {
			angular.forEach(result.pinfo, function(p){
			    messsage += "[" + p.device + "] " + wsaleService.error[p.ecode]
			})
		    };
		    messsage = "成功！！单号：" + rsn + "，打印失败：" + messsage;
		}

		return messsage;
	    };

	    var show_dialog = function(title, message){
		dialog.response(true, title, message, undefined)
	    };
	    
	    if (result.ecode == 0){
		// clear local storage
		$scope.local_remove();
		$scope.disable_refresh = false;
		// modify current balance of retailer
		$scope.select.retailer.balance = $scope.select.left_balance;
		$scope.select.surplus = $scope.select.retailer.balance;
		
		if (im_print === diablo_yes){
		    var show_message = "开单" + print(result);
		    show_dialog("销售开单", show_message); 
		} else{
		    var yes_callback = function(){
			wsaleService.print_w_sale(rsn).then(function(result){
			    var show_message = "销售单打印" + print(result);
			    show_dialog("销售单打印", show_message); 
			})
		    };
		    
		    dialog.request(
			"销售单打印", "开单成功，是否打印销售单？",
			yes_callback, undefined, $scope)
		}
		
	    } else{
	    	dialog.response_with_callback(
	    	    false, "销售开单", "开单失败：" + wsaleService.error[result.ecode],
		    $scope, function(){$scope.has_saved = false});
	    }
	})
    };
    
    // watch balance
    var reset_payment = function(newValue){
	$scope.select.has_pay = 0.00;
	var e_pay = 0.00;
	var verificate = 0.00;
	if(angular.isDefined($scope.select.cash) && $scope.select.cash){
	    $scope.select.has_pay += parseFloat($scope.select.cash);
	}

	if(angular.isDefined($scope.select.card) && $scope.select.card){
	    $scope.select.has_pay += parseFloat($scope.select.card);
	}

	if(angular.isDefined($scope.select.wire) && $scope.select.wire){
	    $scope.select.has_pay += parseFloat($scope.select.wire);
	}

	if(angular.isDefined($scope.select.verificate)
	   && $scope.select.verificate){
	    verificate = parseFloat($scope.select.verificate); 
	}

	if(angular.isDefined($scope.select.extra_pay)
	   && $scope.select.extra_pay){
	    e_pay = parseFloat($scope.select.extra_pay);
	}

	// console.log($scope.float_add);
	$scope.select.left_balance =
	    $scope.select.surplus + $scope.select.should_pay + e_pay
	    - verificate - $scope.select.has_pay;
	$scope.select.left_balance = $scope.round($scope.select.left_balance);
	
	// $scope.select.left_balance = $scope.float_add(
	//     $scope.float_add($scope.select.should_pay, e_pay),
	//     $scope.float_sub($scope.select.surplus, $scope.select.has_pay));
    };
    
    $scope.$watch("select.cash", function(newValue, oldValue){
	if (newValue === oldValue || angular.isUndefined(newValue)) return;
	if ($scope.select.form.cashForm.$invalid) return; 
	reset_payment(newValue);
    });

    $scope.$watch("select.card", function(newValue, oldValue){
	if (newValue === oldValue || angular.isUndefined(newValue)) return;
	if ($scope.select.form.cardForm.$invalid) return;
	reset_payment(newValue); 
    });

    $scope.$watch("select.wire", function(newValue, oldValue){
	if (newValue === oldValue || angular.isUndefined(newValue)) return;
	if ($scope.select.form.wireForm.$invalid) return;
	reset_payment(newValue); 
    });

    $scope.$watch("select.verificate", function(newValue, oldValue){
    	if (newValue === oldValue || angular.isUndefined(newValue)) return;
    	if ($scope.select.form.vForm.$invalid) return; 
    	reset_payment(newValue); 
    });

    $scope.$watch("select.extra_pay", function(newValue, oldValue){
	// console.log(newValue);
    	if (newValue === oldValue || angular.isUndefined(newValue)) return;
    	if ($scope.select.form.extraForm.$invalid) return; 
    	$scope.re_calculate(); 
    }); 
    
    var in_amount = function(amounts, inv){
	for(var i=0, l=amounts.length; i<l; i++){
	    if(amounts[i].cid === inv.color_id && amounts[i].size === inv.size){
		amounts[i].count += parseInt(inv.amount);
		return true;
	    }
	}
	return false;
    };

    var get_amount = function(cid, sname, amounts){
	for (var i=0, l=amounts.length; i<l; i++){
	    if (amounts[i].cid === cid && amounts[i].size === sname){
		return amounts[i];
	    }
	}
	return undefined;
    };

    var set_batch = function(cid, batch, amounts){
	for (var i=0, l=amounts.length; i<l; i++){
	    var a = amounts[i];
	    if (a.cid === cid && angular.isDefined(a.size) && a.size){
		a.sell_count = batch;
		a.batch = batch;
	    } 
	}
    };

    var get_batch = function(cid, amounts){
	for (var i=0, l=amounts.length; i<l; i++){
	    var a = amounts[i];
	    if (cid === a.cid && angular.isDefined(a.batch) && a.batch){
		return a.batch;
	    }
	}

	return undefined;
    }
    
    $scope.re_calculate = function(){
	// console.log("re_calculate");
	$scope.select.total = 0;
	$scope.select.abs_total = 0;
	$scope.select.should_pay = 0.00;
	
	var e_pay = 0;
	if(angular.isDefined($scope.select.extra_pay)
	   && $scope.select.extra_pay){
	    e_pay = $scope.select.extra_pay;
	}

	console.log($scope.inventories);
	for (var i=1, l=$scope.inventories.length; i<l; i++){
	    var one = $scope.inventories[i];
	    $scope.select.total      += parseInt(one.sell);
	    $scope.select.abs_total  += Math.abs(parseInt(one.sell));

	    // var f1 = $scope.round(one.fprice * one.fdiscount * 0.01);
	    if ($scope.setting.round === diablo_round_row){
		$scope.select.should_pay
		    += $scope.round(
			one.fprice * one.fdiscount * 0.01 * one.sell);
	    } else {
		$scope.select.should_pay
		    += one.fprice * one.fdiscount * 0.01 * one.sell; 
	    }
	    
	    // console.log($scope.select.should_pay);
	    // $scope.select.should_pay
	    // 	= $scope.select.should_pay + one.fprice * one.sell * one.fdiscount * 0.01;
	}

	$scope.select.should_pay = $scope.round($scope.select.should_pay); 
	

	// console.log($scope.select.extra_pay);
	var verificate = diablo_set_float($scope.select.verificate);
	verificate = angular.isDefined(verificate) ? verificate : 0;
	    
	$scope.select.left_balance
	    = $scope.select.surplus + $scope.select.should_pay + e_pay
	    - $scope.select.has_pay - verificate;

	$scope.select.left_balance = $scope.round($scope.select.left_balance);
	// $scope.select.left_balance = $scope.float_add(
	//     $scope.float_add($scope.select.should_pay, e_pay),
	//     $scope.float_sub($scope.select.surplus, $scope.select.has_pay)); 
    };

    var valid_sell = function(amount){
	var count = amount.sell_count; 
	if (angular.isUndefined(count)){
	    return true;
	}

	if (!count) {
	    return true;
	}
	
	var renumber = /^[+|\-]?[1-9][0-9]*$/; 
	// if (renumber.test(count) && amount.count >= amount.sell_count){
	// 	return true;
	// } 

	if (renumber.test(count)){
	    return true;
	}
	
	return false
    };
    
    var valid_all_sell = function(amounts){
	var renumber = /^[+|\-]?[1-9][0-9]*$/; 
	var unchanged = 0;

	for(var i=0, l=amounts.length; i<l; i++){
	    var count = amounts[i].sell_count; 
	    if (angular.isUndefined(count)){
		unchanged++;
		continue;
	    }

	    if (!count){
		unchanged++;
		continue;
	    }

	    // console.log(count)
	    // if (!renumber.test(count) || amounts[i].count < parseInt(count)){
	    // 	return false;
	    // }
	    if (!renumber.test(count)){
		return false;
	    } 
	};

	return unchanged === l ? false : true;

    };

    var add_callback = function(params){
	console.log(params.amounts);
	
	var sell_total = 0;
	angular.forEach(params.amounts, function(a){
	    if (angular.isDefined(a.sell_count) && a.sell_count){
		sell_total += parseInt(a.sell_count);
	    }
	});

	// var batch = 0;
	// for (var i = 0, l=params.amounts.length; i<l; i++){
	//     var amount = params.amounts[i];
	//     if (angular.isDefined(amount.batch)
	// 	&& amount.batch){
	// 	batch = parseInt(params.amounts[i].batch);
	// 	if (batch !== 0){
	// 	    break;
	// 	}
	//     } 
	// }

	// console.log(batch);

	return {amounts:     params.amounts,
		sell_style:  params.sell_style,
		sell:        sell_total,
		// batch:       batch,
		fdiscount:   params.fdiscount,
		fprice:      params.fprice};
    };

    $scope.add_free_inventory = function(inv){
	console.log(inv);

	if (angular.isUndefined($scope.select.retailer)
	    || diablo_is_empty($scope.select.retailer)){
	    diabloUtilsService.response(
		false, "销售开单", "开单失败：" + wsaleService.error[2192]);
	    return;
	};
	
	inv.$edit = true;
	inv.$new  = false;
	inv.amounts[0].sell_count = inv.sell;
	// oreder
	inv.order_id = $scope.inventories.length; 
	// add new line
	$scope.inventories.unshift({$edit:false, $new:true});

	// save
	$scope.disable_refresh = false;
	$scope.local_save();
	$scope.re_calculate();
    };
    
    $scope.add_inventory = function(inv){
	// console.log(inv);
	// console.log($scope.select);
	console.log($scope.setting);
	if (angular.isUndefined($scope.select.retailer)
	    || diablo_is_empty($scope.select.retailer)){
	    diabloUtilsService.response(
		false, "销售开单", "开单失败：" + wsaleService.error[2192]);
	    return;
	};

	if ($scope.setting.check_sale === diablo_no
	    && $scope.setting.trace_price === diablo_no
	    && inv.free === 0){
	    inv.free_color_size = true;
	    inv.fdiscount       = inv.discount;
	    inv.fprice          = inv[inv.sell_style.f];
	    inv.amounts         = [{cid:0, size:0}];
	} else {
	    // avoid uncheck sale, but inventory is not free
	    // $scope.setting.check_sale = true;
	    var promise = diabloPromise.promise; 
	    var calls   = [];

	    if ($scope.setting.check_sale === diablo_yes || inv.free !== 0){
		calls.push(promise(purchaserService.list_purchaser_inventory,
				   {style_number: inv.style_number,
				    brand:        inv.brand_id,
				    shop:         $scope.select.shop.id
				   })());
	    }
	    
	    if ($scope.setting.trace_price === diablo_yes){
		calls.push(promise(wsaleService.get_last_sale,
				   {style_number: inv.style_number,
				    brand:        inv.brand_id,
				    shop:     $scope.select.shop.id,
				    retailer: $scope.select.retailer.id 
				   })());
	    };
	    
	    $q.all(calls).then(function(data){
		console.log(data);
		// data[0] is the inventory belong to the shop
		// data[1] is the last sale of the shop

		if ($scope.setting.check_sale === diablo_yes
		    || inv.free !== 0){
		    var shop_now_inv = data[0];
		    
		    var order_sizes =
			wgoodService.format_size_group(
			    inv.s_group, filterSizeGroup);
		    var sort =
			purchaserService.sort_inventory(
			    shop_now_inv, order_sizes, filterColor);
		    
		    inv.total   = sort.total;
		    inv.sizes   = sort.size;
		    inv.colors  = sort.color;
		    inv.amounts = sort.sort;

		    console.log(inv.sizes)
		    console.log(inv.colors);
		    console.log(inv.amounts); 
		} 
		
		// should use the price of inventory
		// inv.fdiscount   = inv.ldiscount ? inv.ldiscount : inv.discount;
		// inv.fprice      = inv.lprice ? inv.lprice : inv[inv.sell_style.f];
		if ($scope.setting.trace_price === diablo_yes){
		    // last sale info
		    var shop_last_inv = function(){
			if ($scope.setting.check_sale === diablo_yes
			    || inv.free !== 0){
			    return data[1];
			} else {
			    return data[0];
			}
		    }();
		    
		    inv.lprice      = shop_last_inv.length === 0
			? undefined:shop_last_inv[0].fprice;
		    
		    inv.ldiscount   = shop_last_inv.length === 0
			? undefined:shop_last_inv[0].fdiscount;
		    
		    inv.lsell_style = shop_last_inv.length === 0
			? undefined:shop_last_inv[0].sell_style;

		    if (angular.isDefined(inv.lsell_style)
			&& inv.lsell_style !== -1){
			inv.sell_style
			    = $scope.get_sell_style(inv.lsell_style);
		    } 

		    inv.fdiscount   = inv.ldiscount
			? inv.ldiscount : inv.discount;
		    inv.fprice      = inv.lprice
			? inv.lprice : inv[inv.sell_style.f];
		} else{
		    inv.fdiscount   = inv.discount;
		    inv.fprice      = inv[inv.sell_style.f];
		}

		if(inv.free === 0){
		    inv.free_color_size = true;
		    inv.amounts         = [{cid:0, size:0}];
		} else{
		    inv.free_color_size = false;

		    var after_add = function(){
			inv.$edit = true;
			inv.$new = false;
			// oreder
			inv.order_id = $scope.inventories.length; 
			// add new line 
			$scope.inventories.unshift({$edit:false, $new:true});

			$scope.disable_refresh = false;
			$scope.local_save();
			$scope.re_calculate(); 
		    };
		    
		    var callback = function(params){
			// console.log(params);
			var result  = add_callback(params);
			console.log(result);
			inv.amounts    = result.amounts;
			inv.sell_style = result.sell_style;
			inv.sell       = result.sell;
			// inv.batch      = result.batch;
			inv.fdiscount  = result.fdiscount;
			inv.fprice     = result.fprice;
			after_add();
		    };
		    
		    var modal_size = diablo_valid_dialog(inv.sizes);
		    var large_size = modal_size === 'lg' ? true : false;
		    var payload = {
			// last_discount:  inv.last_discount,
			// last_fprice:    inv.last_fprice,
			sell_styles:    $scope.sell_styles,
			sell_style:     inv.sell_style,
			fdiscount:      inv.fdiscount,
			fprice:         inv.fprice,
			sizes:          inv.sizes,
			large_size:     large_size,
			colors:         inv.colors,
			amounts:        inv.amounts,
			path:           inv.path,
			get_amount:     get_amount,
			set_batch:      set_batch,
			get_price:      function(name){return inv[name]},
			valid_sell:     valid_sell,
			valid:          valid_all_sell};

		    diabloUtilsService.edit_with_modal(
			"wsale-new.html", modal_size, callback, $scope, payload); 
		}; 
	    });
	} 
    };
    
    /*
     * delete inventory
     */
    $scope.delete_inventory = function(inv){
	console.log(inv);
	// console.log($scope.inventories)

	// var deleteIndex = -1;
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    if(inv.order_id === $scope.inventories[i].order_id){
		// $scope.inventories.splice(i, 1)
		// deleteIndex = i;
		break;
	    }
	}

	$scope.inventories.splice(i, 1);
	
	// reorder
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    $scope.inventories[i].order_id = l - i;
	}

	$scope.local_save();
	$scope.re_calculate(); 
	
    };

    /*
     * lookup inventory 
     */
    $scope.inventory_detail = function(inv){
	var payload = {sizes:        inv.sizes,
		       colors:       inv.colors, 
		       amounts:      inv.amounts,
		       path:         inv.path,
		       get_amount:   get_amount};
	diabloUtilsService.edit_with_modal(
	    "wsale-detail.html", undefined, undefined, $scope, payload)
    };

    /*
     * update inventory
     */
    $scope.update_inventory = function(inv){
	console.log(inv);
	inv.$update = true;
	// inv.$a_change = false;
	if (inv.free_color_size){
	    inv.free_update = true;
	    inv.o_fdiscount = inv.fdiscount;
	    inv.o_fprice    = inv.fprice;
	    return;
	}
	
	var callback = function(params){
	    var result  = add_callback(params);
	    console.log(result);
	    inv.amounts    = result.amounts;
	    inv.sell_style = result.sell_style;
	    // inv.batch      = result.batch;
	    inv.sell       = result.sell;
	    inv.fdiscount  = result.fdiscount;
	    inv.fprice     = result.fprice;

	    // save
	    $scope.local_save();
	    $scope.re_calculate(); 
	};

	var modal_size = diablo_valid_dialog(inv.sizes);
	var large_size = modal_size === 'lg' ? true : false;
	
	var payload = {sell_styles:  $scope.sell_styles,
		       sell_style:   $scope.get_sell_style(inv.sell_style.id),
		       // sell_style:   $scope.get_sell_style(inv.sell_style_id),
		       fdiscount:    inv.fdiscount,
		       fprice:       inv.fprice,
		       sizes:        inv.sizes,
		       large_size:   large_size,
		       colors:       inv.colors, 
		       amounts:      inv.amounts,
		       path:         inv.path,
		       get_amount:   get_amount,
		       set_batch:    set_batch,
		       get_batch:    get_batch,
		       get_price:    function(name){return inv[name]},
		       valid_sell:   valid_sell,
		       valid:        valid_all_sell}; 
	diabloUtilsService.edit_with_modal(
	    "wsale-new.html", modal_size, callback, $scope, payload)
    };

    $scope.save_free_update = function(inv){
	// console.log("save_free_update", inv);
	$timeout.cancel($scope.timeout_auto_save);
	inv.free_update = false; 
	inv.amounts[0].sell_count = inv.sell;
	
	// save
	$scope.local_save();
	$scope.re_calculate();
    };

    $scope.cancel_free_update = function(inv){
	// console.log(inv);
	$timeout.cancel($scope.timeout_auto_save);
	inv.free_update = false;
	inv.sell      = inv.amounts[0].sell_count;
	inv.fdiscount = inv.o_fdiscount;
	inv.fprice    = inv.o_fprice;
	$scope.re_calculate(); 
    };

    $scope.reset_inventory = function(inv){
	$timeout.cancel($scope.timeout_auto_save);
	$scope.inventories[0] = {$edit:false, $new:true};;
    };

    $scope.auto_save_free = function(inv){
	if (angular.isUndefined(inv.sell)
	    || !inv.sell
	    || parseInt(inv.sell) === 0){
	    return;
	} 

	$timeout.cancel($scope.timeout_auto_save);
	$scope.timeout_auto_save = $timeout(function(){
	    // console.log(inv); 
	    if (inv.$new && inv.free_color_size){
		$scope.add_free_inventory(inv);
	    }; 

	    if (!inv.$new && inv.free_update){
		$scope.save_free_update(inv); 
	    }
	}, 1000); 
    };
});


wsaleApp.controller("wsaleNewDetailCtrl", function(
    $scope, $routeParams, $location, dateFilter, diabloUtilsService,
    localStorageService, diabloFilter, wsaleService,
    user, filterRetailer, filterEmployee, base){

    $scope.shops     = user.sortShops.concat(user.sortBadRepoes);
    $scope.shopIds   = user.shopIds.concat(user.badrepoIds);
    $scope.records   = [];
    
    $scope.goto_page = diablo_goto_page;
    $scope.f_add     = diablo_float_add;
    $scope.f_sub     = diablo_float_sub;
    $scope.f_mul     = diablo_float_mul;
    $scope.round     = diablo_round;
    
    $scope.disable_print = false;
    $scope.allowed_slide = true;

    /*
     * hidden
     */
    $scope.show = {base:false, balance:false, action:true, comment:false};

    
    $scope.toggle_balance = function(){
	// console.log("toggle left");
	$scope.show.balance = !$scope.show.balance;
    };

    $scope.toggle_base = function(){
	$scope.show.base = !$scope.show.base;
    };

    // $scope.toggle_check = function(){
    // 	$scope.show.check = !$scope.show.check;
    // };

    $scope.toggle_action = function(){
	$scope.show.action = !$scope.show.action;
    };

    $scope.toggle_comment = function(){
	$scope.show.comment = !$scope.show.comment;
    }; 

    
    /* 
     * filter operation
     */
    // 0: >0 1: <0
    var has_pay =  [{name:">0", id:0, py:diablo_pinyin("大于0")},
    		    {name:"=0", id:1, py:diablo_pinyin("等于0")}];
    
    // initial 
    diabloFilter.reset_field(); 
    diabloFilter.add_field("rsn", []);
    diabloFilter.add_field("shop",     $scope.shops);
    diabloFilter.add_field("retailer", filterRetailer);
    diabloFilter.add_field("employee", filterEmployee);
    diabloFilter.add_field("has_pay",  has_pay);

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    // console.log($scope.filter);
    // console.log($scope.prompt);

    var now = $.now();

    var storage = localStorageService.get(diablo_key_wsale_trans);
    // console.log(storage);
    if (angular.isDefined(storage) && storage !== null){
    	$scope.filters        = storage.filter;
    	$scope.qtime_start    = storage.start_time;
    } else{
	$scope.filters = [];
	
	$scope.qtime_start = function(){
	    var shop = -1;
	    if ($scope.shopIds.length === 1){
		shop = $scope.shopIds[0];
	    };
	    return diablo_base_setting(
		"qtime_start", shop, base, diablo_set_date,
		diabloFilter.default_start_time(now));
	}();
    };

    $scope.time   = diabloFilter.default_time($scope.qtime_start);

    //
    $scope.sequence_pagination = function(){
	// var shop = -1;
	// if ($scope.shopIds.length === 1){
	//     shop = $scope.shopIds[0];
	// };

	return diablo_base_setting(
	    "se_pagination", -1, base, parseInt, diablo_no)
    }();

    // console.log($scope.time);

    /*
     * pagination 
     */
    $scope.colspan = 19;
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = 10;

    // console.log($routeParams);
    $scope.default_page = 1;

    console.log($routeParams);
    var back_page = diablo_set_integer($routeParams.page);
    // console.log(back_page);
    
    if (angular.isDefined(back_page)){
	$scope.current_page = back_page;
    } else{
	$scope.current_page = $scope.default_page; 
    };
    
    // console.log($scope.current_page);

    $scope.do_search = function(page){
	console.log(page);

	$scope.current_page = page;

	// save condition of query 
	localStorageService.set(
	    diablo_key_wsale_trans,
	    {filter:$scope.filters,
	     start_time: diablo_get_time($scope.time.start_time),
	     page:page, t:now});
	

	// console.log($scope.time); 
	if (angular.isDefined(back_page)){
	    var stastic = localStorageService.get("wsale-trans-stastic");
	    console.log(stastic);
	    $scope.total_items      = stastic.total_items;
	    $scope.total_amounts    = stastic.total_amounts;
	    $scope.total_spay       = stastic.total_spay;
	    $scope.total_hpay       = stastic.total_hpay;
	    $scope.total_cash       = stastic.total_cash;
	    $scope.total_card       = stastic.total_card;
	    $scope.total_wire       = stastic.total_wire;
	    $scope.total_verificate = stastic.total_verificate;

	    // recover 
	    $location.path("/new_wsale_detail", false);
	    $routeParams.page = undefined;
	    if ($scope.sequence_pagination === diablo_no){
		back_page = undefined; 
	    }
	    localStorageService.remove("wsale-trans-stastic");
	}
	
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    if (angular.isUndefined(search.shop)
		|| !search.shop || search.shop.length === 0){
		search.shop = $scope.shopIds.length === 0 ? undefined : $scope.shopIds; 
	    }

	    var items    = $scope.items_perpage;
	    var page_num = page;
	    if (angular.isDefined(back_page)
		&& $scope.sequence_pagination === diablo_yes){
		items = page * $scope.items_perpage;
		$scope.records = []; 
		page_num = 1;
		back_page = undefined;
	    }
	    
	    wsaleService.filter_w_sale_new(
		$scope.match, search, page_num, items
	    ).then(function(result){
		console.log(result);
		if (page === 1 && angular.isUndefined(back_page)){
		    $scope.total_items      = result.total;
		    $scope.total_amounts    = result.t_amount;
		    $scope.total_spay       = $scope.round(result.t_spay);
		    // $scope.total_spay       = result.t_spay;
		    $scope.total_hpay       = $scope.round(result.t_hpay);
		    $scope.total_cash       = result.t_cash;
		    $scope.total_card       = result.t_card;
		    $scope.total_wire       = result.t_wire;
		    $scope.total_verificate = result.t_verificate;

		    $scope.records = [];
		}
		
		// console.log($scope);

		angular.forEach(result.data, function(d){
		    d.shop     = diablo_get_object(d.shop_id, $scope.shops);
		    d.employee = diablo_get_object(d.employee_id, filterEmployee);
		    d.retailer = diablo_get_object(d.retailer_id, filterRetailer); 
		});

		if ($scope.sequence_pagination === diablo_no){
		    $scope.records = result.data; 
		    diablo_order_page(
			page, $scope.items_perpage, $scope.records);
		} else {
		    diablo_order(
			result.data, (page_num - 1) * $scope.items_perpage + 1);
		    $scope.records = $scope.records.concat(result.data);

		    // console.log($scope.records);
		    
		}
		
	    })
	})
    };
    
    $scope.page_changed = function(){
	// console.log($scope.num_pages);
	console.log($scope.current_page);
    	$scope.do_search($scope.current_page);
    };

    $scope.auto_pagination = function(){
	if ($scope.sequence_pagination === diablo_no){
	    return;
	} else {
	    $scope.current_page += 1;
	    $scope.do_search($scope.current_page);
	} 
    };

    $scope.do_search($scope.current_page);

    $scope.save_stastic = function(){
	localStorageService.set(
	    "wsale-trans-stastic",
	    {total_items:      $scope.total_items,
	     total_amounts:    $scope.total_amounts,
	     total_spay:       $scope.total_spay,
	     total_hpay:       $scope.total_hpay,
	     total_cash:       $scope.total_cash,
	     total_card:       $scope.total_card,
	     total_wire:       $scope.total_wire,
	     total_verificate: $scope.total_verificate,
	     t:                now});
    };
    
    $scope.rsn_detail = function(r){
	// console.log(r);
	// console.log($scope.current_page);
	$scope.save_stastic();	
	diablo_goto_page(
	    "#/wsale_rsn_detail/"
		+ r.rsn + "/" + $scope.current_page.toString()); 
    };

    $scope.f_print = function(r){
	diablo_goto_page("#/wsale_print_preview/" + r.rsn); 
    };

    var dialog = diabloUtilsService;
    $scope.print = function(r){
	$scope.disable_print = true;
	wsaleService.print_w_sale(r.rsn).then(function(result){
	    console.log(result);
	    $scope.disable_print = false; 
	    if (result.ecode == 0){
		var msg = "";
		if (result.pcode == 0){
		    msg = "销售单打印成功！！单号：" + result.rsn + "，请等待服务器打印";
		    dialog.response(true, "销售单打印", msg, $scope); 
		} else {
		    if (result.pinfo.length === 0){
			msg += wsaleService.error[result.pcode]
		    } else {
			angular.forEach(result.pinfo, function(p){
			    msg += "[" + p.device + "] " + wsaleService.error[p.ecode]
			})
		    };
		    msg = "销售单打印失败！！单号：" + result.rsn + "，打印失败：" + msg;
		    dialog.response(false, "销售单打印", msg, $scope); 
		}
		
	    } else{
	    	dialog.response(
	    	    false, "销售单打印",
		    "销售单打印失败：" + wsaleService.error[result.ecode]);
	    }
	})
    };

    $scope.update_detail = function(r){
	$scope.save_stastic();
	if (r.type === 0){
	    diablo_goto_page(
		'#/update_wsale_detail/'
		    + r.rsn + "/" + $scope.current_page.toString()); 
	} else {
	    diablo_goto_page(
		'#/update_wsale_reject/'
		    + r.rsn + "/" + $scope.current_page.toString()); 
	}
    };

    $scope.check_detail = function(r){
	// console.log(r);
	var callback = function(){
	    wsaleService.check_w_sale_new(r.rsn).then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    dialog.response_with_callback(
			true, "销售单审核", "销售单审核成功！！单号：" + state.rsn,
			$scope, function(){r.state = 1})
	    	    return;
		} else{
	    	    dialog.response(
	    		false, "销售单审核",
	    		"销售单审核失败：" + wsaleService.error[state.ecode]);
		}
	    })
	};

	diabloUtilsService.request(
	    "销售单审核", "审核完成后，销售单将无法修改，确定要审核吗？",
	    callback, undefined, $scope);
    };

    $scope.export_to = function(){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    if (angular.isUndefined(search.shop)
		|| !search.shop || search.shop.length === 0){
		search.shop = $scope.shopIds.length === 0 ? undefined : $scope.shopIds; 
	    }
	    console.log(search);
	    
	    wsaleService.csv_export(wsaleService.export_type.trans, search).then(function(result){
	    	console.log(result);
		if (result.ecode === 0){
		    dialog.response_with_callback(
			true, "文件导出成功", "创建文件成功，请点击确认下载！！", undefined,
			function(){window.location.href = result.url;}) 
		} else {
		    diablo.response(
			false, "文件导出失败", "创建文件失败：" + wsaleService.error[result.ecode]);
		} 
	    }); 
	}) 
    };
});


wsaleApp.controller("wsaleGuideCtrl", function($scope){
    $scope.goto_page = diablo_goto_page;

    $scope.new_wsale = function(){
	$scope.goto_page("#/wsale/new_wsale");
    }

    $scope.reject_wsale = function(){
	$scope.goto_page("#/wsale/reject_wsale");
    }
    
    $scope.wsale_rsn_detail = function(){
	$scope.goto_page("#/wsale_rsn_detail");
    }
})

wsaleApp.controller("wsaleCtrl", function(
    $scope, localStorageService){
    diablo_remove_local_storage(localStorageService);

    // cache 
    // var promise  = diabloPromise.promise;
    // var filter   = diabloShareFilter;
    // $q.all([
    // 	// promise(user)(),
    // 	promise(filter.get_right)(),
    // 	promise(filter.get_shop)(),
    // 	promise(filter.get_brand)(),
    // 	promise(filter.get_firm)(),
    // 	promise(filter.get_type)(),
    // 	promise(filter.get_employee)(),
    // 	promise(filter.get_retailer)(),
    // 	promise(filter.get_size_group)(),
    // 	promise(filter.get_base_setting)()

    // ]).then(function(data){
    // 	console.log(data);

    // 	// console.log(wsaleGoodService);
	
    // 	wsaleGoodService.set_user(data[0], data[1]);
    // 	// brand
    // 	wsaleGoodService.set_brand(angular.copy(data[2]));
    // 	// firm
    // 	wsaleGoodService.set_firm(angular.copy(data[3]));
    // 	// type
    // 	wsaleGoodService.set_type(angular.copy(data[4]));
    // 	// employee
    // 	wsaleGoodService.set_employee(angular.copy(data[5]));
    // 	// retailer
    // 	wsaleGoodService.set_retailer(angular.copy(data[6]));
    // 	// size
    // 	wsaleGoodService.set_size_group(data[7]);
    // 	// base
    // 	wsaleGoodService.set_base(data[8]);

    // 	// console.log(wsaleGoodService.get_user());
    // 	// console.log(wsaleGoodService.get_brand());
    // 	// console.log(wsaleGoodService.get_firm());
    // 	// console.log(wsaleGoodService.get_type());
    // 	// console.log(wsaleGoodService.get_employee());
    // 	// console.log(wsaleGoodService.get_retailer());
    // 	// console.log(wsaleGoodService.get_size_group());
    // 	// console.log(wsaleGoodService.get_base());
    // })
    
});

wsaleApp.controller("loginOutCtrl", function($scope, $resource){
    $scope.home = function () {
	diablo_login_out($resource)
    };
});
