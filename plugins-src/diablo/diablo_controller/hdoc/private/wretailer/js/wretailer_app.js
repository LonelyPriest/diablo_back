var wretailerApp = angular.module(
    'wretailerApp',
    ['ui.bootstrap', 'ngRoute', 'ngResource', 'LocalStorageModule',
     'wgoodApp', 'diabloAuthenApp', 'diabloFilterApp',
     'diabloNormalFilterApp', 'diabloPattern', 'diabloUtils', 'userApp'])
    .config(function(localStorageServiceProvider){
	localStorageServiceProvider
	    .setPrefix('wretailerApp')
	    .setStorageType('localStorage')
	    .setNotify(true, true)
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
	  }])
    .config(function($httpProvider, authenProvider){
	// $httpProvider.responseInterceptors.push(authenProvider.interceptor);
	$httpProvider.interceptors.push(authenProvider.interceptor); 
    });

wretailerApp.config(['$routeProvider', function($routeProvider){
    var user = {"user": function(userService){
    	return userService()}};

    var brand = {"filterBrand": function(diabloFilter){
	return diabloFilter.get_brand()}};

    var firm = {"filterFirm": function(diabloFilter){
	return diabloFilter.get_firm()}};

    var type = {"filterType": function(diabloFilter){
	return diabloFilter.get_type()}};
    
    var s_group = {"filterSizeGroup": function(diabloFilter){
	return diabloFilter.get_size_group()}};
    
    var retailer = {"filterRetailer": function(diabloNormalFilter){
	return diabloNormalFilter.get_wretailer()}};
    
    var employee = {"filterEmployee": function(diabloNormalFilter){
	return diabloNormalFilter.get_employee()}};
    
    var province = {"filterProvince": function(diabloNormalFilter){
	return diabloNormalFilter.get_province()}};

    var city = {"filterCity": function(diabloNormalFilter){
	return diabloNormalFilter.get_city()}};

    var base = {"base": function(diabloNormalFilter){
	return diabloNormalFilter.get_base_setting()}};
    
    $routeProvider. 
	when('/wretailer_new', {
	    templateUrl: '/private/wretailer/html/wretailer_new.html',
	    controller: 'wretailerNewCtrl',
	    resolve: angular.extend({}, province, city, user) 
	}).
	when('/wretailer_detail', {
	    templateUrl: '/private/wretailer/html/wretailer_detail.html',
	    controller: 'wretailerDetailCtrl',
	    resolve: angular.extend({}, province, city, user)
	}).
	when('/wretailer_trans/:retailer?/:page?', {
	    templateUrl: '/private/wretailer/html/wretailer_trans.html',
	    controller: 'wretailerTransCtrl',
	    resolve: angular.extend({}, retailer, employee, user, base)
	}).
	// when('/wretailer_top', {
	//     templateUrl: '/private/wretailer/html/wretailer_top.html',
	//     controller: 'wretailerTopCtrl',
	//     resolve: angular.extend({}, retailer, province, city)
	// }).
	when('/wretailer_trans_rsn/:retailer?/:rsn?/:ppage?', {
	    templateUrl: '/private/wretailer/html/wretailer_trans_rsn_detail.html',
	    controller: 'wretailerTransRsnDetailCtrl',
	    resolve: angular.extend({}, brand, firm, retailer, employee, s_group, type, user, base)
	}).
	otherwise({
	    templateUrl: '/private/wretailer/html/wretailer_detail.html',
	    controller: 'wretailerDetailCtrl',
	    resolve: angular.extend({}, province, city, user)
        })
}]);

wretailerApp.service("wretailerService", function($resource, dateFilter){
    // error information
    // this._retailers = undefined;

    // this.set_retailer = function(retailers){
    // 	this._retailers = retailers;
    // };

    // this.get_retailer = function(){
    // 	return this._retailers;
    // };
    
    this.error = {
     	2101: "已存在同样的零售商！！",
	9001: "数据库操作失败，请联系服务人员！！"};

    this.sort_inventory = function(invs, orderSizes){
	// console.log(invs);
	// console.log(orderSizes);
	var in_sort = function(sorts, inv){
	    for(var i=0, l=sorts.length; i<l; i++){
		if(sorts[i].cid === inv.color_id
		   && sorts[i].size === inv.size){
		    sorts[i].count += parseInt(inv.amount);
		    return true;
		}
	    }
	    return false;
	};

	var total = 0;
	var used_sizes  = [];
	var colors = [];
	var sorts = [];
	angular.forEach(invs, function(inv){
	    if (angular.isDefined(inv.amount)){
		total += inv.amount; 
	    };
	    
	    if (!in_array(used_sizes, inv.size)){
		used_sizes.push(inv.size);
	    };
	    
	    var color = {cid:inv.color_id, cname: inv.color};
	    if (!in_array(colors, color)){
		colors.push(color)
	    };

	    if (!in_sort(sorts, inv)){
		sorts.push({cid:inv.color_id, size:inv.size, count:inv.amount})
	    }; 
	});

	// format size
	var order_used_sizes = [];
	if (angular.isArray(orderSizes) && orderSizes.length !== 0){
	    order_used_sizes = orderSizes.filter(function(s){
		return in_array(used_sizes, s); 
	    });
	} else{
	    order_used_sizes = used_sizes;
	};
	

	// console.log(order_used_sizes);
	// console.log(colors);
	// console.log(sorts);
	
	return {total: total, size: order_used_sizes, color:colors, sort:sorts};
    };

    
    
    var http = $resource("/wretailer/:operation/:id",
    			 {operation: '@operation', id: '@id'});

    this.new_wretailer = function(r){
	var balance = r.balance;
	var province = angular.isDefined(r.province) && r.province ? r.province.id : undefined;
	var city = angular.isDefined(r.city) && r.city ? r.city : undefined; 
	return http.save(
	    {operation:"new_w_retailer"},
	    {name:     r.name,
	     balance:  angular.isDefined(balance) ? parseFloat(balance) : 0,
	     mobile:   r.mobile,
	     address:  r.address,
	     province: province,
	     city:     angular.isDefined(city) ? (typeof(city) === 'object' ? city.name : city)
	     : undefined
	    }).$promise;
    };

    this.delete_retailer = function(wretailerId){
	return http.delete({operation: "del_w_retailer", id:wretailerId}).$promise;
    }

    this.update_retailer = function(r){
	return http.save(
	    {operation: "update_w_retailer"},
	    {id:       r.id,
	     name:     r.name,
	     balance:  r.balance,
	     mobile:   r.mobile,
	     address:  r.address,
	     province: angular.isDefined(r.province) && r.province ? r.province.id : undefined,
	     city:     angular.isDefined(r.city) && r.city
	     ? (typeof(r.city) === 'object' ? r.city.name : r.city) : undefined
	    }).$promise;
    };

    this.list_retailer = function(){
	return http.query({operation: "list_w_retailer"}).$promise
    };

    var http_wsale = $resource(
	"/wsale/:operation/:id", {operation: '@operation', id: '@id'});
    this.filter_w_sale_new = function(match, fields, currentPage, itemsPerpage){
	return http_wsale.save(
	    {operation: "filter_w_sale_new"},
	    {match:  angular.isDefined(match) ? match.op : undefined,
	     fields: fields,
	     page:   currentPage,
	     count:  itemsPerpage}).$promise;
    };

    this.filter_w_sale_rsn_group = function(match, fields, currentPage, itemsPerpage){
	return http_wsale.save(
	    {operation: "filter_w_sale_rsn_group"},
	    {match:  angular.isDefined(match) ? match.op : undefined,
	     fields: fields,
	     page:   currentPage,
	     count:  itemsPerpage}).$promise;
    };

    this.w_sale_rsn_detail = function(inv){
	return http_wsale.save(
	    {operation: "w_sale_rsn_detail"},
	    {rsn:inv.rsn, style_number:inv.style_number, brand:inv.brand}).$promise;
    };

    this.check_w_sale_new = function(rsn){
	return http_wsale.save({operation: "check_w_sale"},
			       {rsn: rsn}).$promise;
    };
});


wretailerApp.controller("wretailerNewCtrl", function(
    $scope, wretailerService, diabloPattern, diabloUtilsService,
    filterProvince, filterCity){
    // console.log(filterProvince);
    // console.log(filterCity);
    $scope.provinces = filterProvince;
    $scope.cities    = filterCity;
    // console.log($scope.cities);
    
    $scope.pattern = {name_address: diabloPattern.ch_name_address,
		      tel_mobile:   diabloPattern.tel_mobile,
		      decimal_2:    diabloPattern.decimal_2,
		      city:         diabloPattern.chinese};

    // $scope.use_province = false;

    $scope.check_city = function(city, province){
	if (city){
	    var name = typeof(city) === 'object' ? city.name : city;
	    if (!province){
		// $scope.use_province = true;
		return false;
	    }
	    return $scope.pattern.city.test(name);
	} else {
	    return true;
	}
	
    };

    $scope.city_of_province = function(pid){
	// console.log(pid);
	return $scope.cities.filter(function(c){
	    return c.pid === pid;
	});

	// console.log(filter);
    };

    // $scope.$watch(retailer.city, function(newValue, oldValue){
    // 	if (newValue === undefined) return;

    // 	if (newValue && !retailer.province){
	    
    // 	}
    // });
    
    $scope.new_wretailer = function(retailer){
	console.log(retailer); 

	wretailerService.new_wretailer(retailer).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		diabloUtilsService.response_with_callback(
	    	    true, "新增零售商",
		    "恭喜你，零售商 " + retailer.name + " 成功创建！！",
	    	    $scope,
		    function(){diablo_goto_page("#/wretailer_detail")});
	    } else{
		diabloUtilsService.response(
	    	    false, "新增零售商",
	    	    "新增零售商失败：" + wretailerService.error[state.ecode]);
	    };
	})
    };

    $scope.cancel = function(){
	diablo_goto_page("#/wretailer_detail");
    };
});


wretailerApp.controller("wretailerDetailCtrl", function(
    $scope, $location, diabloPattern, diabloUtilsService,
    diabloPagination, localStorageService, wretailerService,
    filterProvince, filterCity){
    $scope.provinces  = angular.copy(filterProvince);
    $scope.cities     = angular.copy(filterCity);
    $scope.round      = diablo_round;
    $scope.pagination = {};
    $scope.map        = {active:false};
    
    var dialog = diabloUtilsService;
    var f_add  = diablo_float_add;
    var now    = $.now();

    $scope.save_to_local = function(search, t_retailer){
	var s = localStorageService.get(diablo_key_retailer);
	if (angular.isDefined(s) && s !== null){
	    localStorageService.set(
		diablo_key_retailer, {
		    search:angular.isDefined(search) ? search:s.search,
		    t_retailer:angular.isDefined(t_retailer) ? t_retailer:s.t_retailer,
		    page:$scope.pagination.current_page,
		    t:now}
	    )
	} else {
	    localStorageService.set(
		diablo_key_retailer, {
		    search:     search,
		    t_retailer: t_retailer,
		    page:       $scope.pagination.current_page,
		    t:          now})
	}
    };

    $scope.reset_local_storage = function(){
	var s = localStorageService.get(diablo_key_retailer);
	if (angular.isDefined(s) && s !== null){
	    localStorageService.set(
		diablo_key_retailer, {
		    search:     undefined,
		    t_retailer: undefined,
		    page:       $scope.pagination.current_page,
		    t:          now}
	    ) 
	};
    };
    

    /*
     * pagination
     */
    // $scope.pagination.colspan = 9;
    $scope.pagination.max_page_size = 10;
    $scope.pagination.items_perpage = diablo_items_per_page();
    $scope.pagination.default_page  = 1;

    var storage = localStorageService.get(diablo_key_retailer);
    console.log(storage);
    
    if (angular.isDefined(storage) && storage !== null){
	$scope.pagination.current_page = storage.page;
	$scope.search                  = storage.search;
	$scope.total_items             = storage.t_retailer;
    } else {
	$scope.pagination.current_page = $scope.pagination.default_page;
	$scope.search                  = undefined;
	$scope.total_items             = undefined;
    } 
    
    $scope.page_changed = function(page){
	// console.log(page);
	// console.log($scope.pagination.current_page);
	// $scope.current_page = page;
	$scope.pagination.current_page = page;
	$scope.save_to_local();
	$scope.filter_retailers
	    = diabloPagination.get_page($scope.pagination.current_page);
    }
    
    $scope.do_search = function(search){
	console.log(search);
    	return $scope.retailers.filter(function(r){
	    return search === r.name
		|| search === r.mobile
		|| search === (r.pid === -1 ? undefined : r.province.name)
		|| search === (r.cid === -1 ? undefined : r.city.name)
		|| search === r.address
	})
    };

    $scope.on_select_retailer = function(item, model, label){
	console.log(model);
	
	var filters = $scope.do_search(model.name);
	diablo_order(filters);
	console.log(filters);

	$scope.total_balance = 0;
	angular.forEach(filters, function(f){
	    $scope.total_balance =$scope.total_balance + $scope.round(f.balance);
	});

	// re pagination
	diabloPagination.set_data(filters);
	$scope.total_items      = diabloPagination.get_length();
	$scope.filter_retailers = diabloPagination.get_page(
	    $scope.pagination.default_page);
	// save
	$scope.save_to_local(model.name, $scope.total_items);
    }

    var in_prompt = function(p, prompts){
	for (var i=0, l=prompts.length; i<l; i++){
	    if (p === prompts[i].name){
		return true;
	    }
	}

	return false;
    }

    $scope.refresh = function(){
	$scope.reset_local_storage(); 
	$scope.do_refresh($scope.pagination.default_page, undefined);
    };
    
    $scope.do_refresh = function(page, search){
	// console.log(page);
	$scope.pagination.current_page = page;
	$scope.search = search;
	
	wretailerService.list_retailer().then(function(data){
	    // console.log(data);
	    $scope.retailers = angular.copy(data);
	    $scope.total_balance = 0;
	    angular.forEach($scope.retailers, function(r){
		r.province = diablo_get_object(r.pid, $scope.provinces);
		r.city     = diablo_get_object(r.cid, $scope.cities);
		$scope.total_balance = $scope.total_balance + $scope.round(r.balance);
	    })
	    
	    diablo_order($scope.retailers);

	    var filters;
	    if (angular.isDefined(search)){
		filters = $scope.do_search(search);
	    } else {
		filters = $scope.retailers;
	    }
	    
	    diabloPagination.set_data(filters);
	    diabloPagination.set_items_perpage(
		$scope.pagination.items_perpage);
	    $scope.total_items      = diabloPagination.get_length();
	    $scope.filter_retailers = diabloPagination.get_page(
		$scope.pagination.current_page);
	    
	    // save
	    $scope.save_to_local($scope.search, $scope.total_items);
	    
	    $scope.prompts = [];
	    for(var i=0, l=$scope.retailers.length; i<l; i++){
		var r = $scope.retailers[i];

		if (!in_prompt(r.name, $scope.prompts)){
		    $scope.prompts.push({name: r.name, py:diablo_pinyin(r.name)}); 
		}
		if (!in_prompt(r.address, $scope.prompts)){
		    $scope.prompts.push({name: r.address, py:diablo_pinyin(r.address)}); 
		}
		if (!in_prompt(r.mobile, $scope.prompts)){
		    $scope.prompts.push({name: r.mobile, py:diablo_pinyin(r.mobile)}); 
		}

		if (r.pid !== -1){
		    if (!in_prompt(r.province.name, $scope.prompts)){
			$scope.prompts.push(
			    {name: r.province.name, py:diablo_pinyin(r.province.name)}); 	
		    } 
		}

		if (r.cid !== -1){
		    // console.log(r);
		    if (!in_prompt(r.city.name, $scope.prompts)){
			$scope.prompts.push(
			    {name: r.city.name, py:diablo_pinyin(r.city.name)}); 	
		    } 
		}
	    }
	})
    }; 
    
    $scope.do_refresh($scope.pagination.current_page, $scope.search);

    $scope.new_retailer = function(){
	$location.path("/wretailer_new"); 
    };

    $scope.trans_info = function(r){
	diablo_goto_page("#/wretailer_trans/" +r.id.toString());
    }

    var pattern = {name_address: diabloPattern.ch_name_address,
		   tel_mobile:   diabloPattern.tel_mobile,
		   decimal_2:    diabloPattern.decimal_2,
		   city:         diabloPattern.chinese};

    
    
    $scope.update_retailer = function(old_retailer){
	console.log(old_retailer);
	var callback = function(params){
	    console.log(params);

	    var update_retailer = {};
	    for (var o in params.retailer){
		if (!angular.equals(params.retailer[o], old_retailer[o])){
		    update_retailer[o] = params.retailer[o];
		}
	    }
	    
	    update_retailer.id = params.retailer.id;
	    if (angular.isDefined(update_retailer.city)
		&& update_retailer.city
		&& angular.isUndefined(update_retailer.province)
		&& !update_retailer.province){
		update_retailer.province = params.retailer.province;
	    }
	    
	    // console.log(update_retailer);

	    wretailerService.update_retailer(update_retailer).then(function(
		result
	    ){
    		console.log(result);
    		if (result.ecode == 0){
		    dialog.response_with_callback(
			true, "零售商编辑",
			"恭喜你，零售商 ["
			    + old_retailer.name + "] 信息修改成功！！",
			$scope, function(){
			    if (typeof(update_retailer.city) !== 'object'
				&& update_retailer.city){
				if (angular.isUndefined(
				    diablo_get_object(
					result.cid, $scope.cities))){
				    $scope.cities.push({
					id:   result.cid,
					name: update_retailer.city,
					py:   diablo_pinyin(
					    update_retailer.city)})
				} 
			    }
			    console.log($scope.cities);
			    $scope.refresh()
			});
    		} else{
		    dialog.response(
			false, "零售商编辑",
			"零售商编辑失败："
			    + wretailerService.error[result.ecode]);
    		}
    	    }) 
	};

	var check_same = function(new_retailer){
	    // console.log(angular.equals(new_retailer, old_retailer));
	    return angular.equals(new_retailer, old_retailer); 
	};

	var check_exist = function(new_retailer){
	    for(var i=0, l=$scope.retailers.length; i<l; i++){
		if (new_retailer.name === $scope.retailers[i].name
		    && new_retailer.name !== old_retailer.name){
		    return true;
		}
	    }

	    return false;
	};

	var check_city = function(city){
	    if (city){
		var name = typeof(city) === 'object' ? city.name : city;
		return pattern.city.test(name);
	    } else {
		return true;
	    }
	    
	};

	var city_of_province = function(pid){
	    // console.log(pid);
	    return $scope.cities.filter(function(c){
		return c.pid === pid;
	    })
	};
	
	dialog.edit_with_modal(
	    "update-wretailer.html", undefined, callback, $scope,
	    {retailer:    old_retailer,
	     provinces:   $scope.provinces,
	     // cities:      $scope.cities,
	     pattern:     pattern,
	     get_city:    city_of_province,
	     check_same:  check_same,
	     check_exist: check_exist,
	     check_city:  check_city})
    };

    $scope.delete_retailer = function(r){
	var callback = function(){
	    wretailerService.delete_retailer(r.id).then(function(result){
    		console.log(result);
    		if (result.ecode == 0){
		    dialog.response_with_callback(
			true, "删除零售商",
			"恭喜你，零售商 [" + r.name + "] 删除成功！！", $scope,
			function(){$scope.refresh()});
    		} else{
		    dialog.response(
			false, "删除零售商",
			"删除零售商失败："
			    + wretailerService.error[result.ecode]);
    		}
    	    })
	};

	diabloUtilsService.request(
	    "删除零售商", "确定要删除该零售商吗？",
	    callback, undefined, $scope);
    }
});

// wretailerApp.controller("wretailerTopCtrl", function(
//     $scope, wretailerService, filterRetailer, filterProvince, filterCity){
//     $scope.retailers  = filterRetailer;
//     $scope.provinces  = filterProvince;
//     $scope.cities     = filterCity;

//     angular.forEach($scope.retailers, function(r){
// 	r.province = diablo_get_object(r.pid, $scope.provinces);
// 	r.city     = diablo_get_object(r.cid, $scope.cities);
//     });
   
// });

wretailerApp.controller("wretailerCtrl", function($scope, localStorageService){
    diablo_remove_local_storage(localStorageService);
});

wretailerApp.controller("loginOutCtrl", function($scope, $resource){
    $scope.home = function () {
	diablo_login_out($resource)
    };
});
