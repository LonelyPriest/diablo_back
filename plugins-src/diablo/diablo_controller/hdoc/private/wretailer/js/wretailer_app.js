var wretailerApp = angular.module(
    'wretailerApp',
    ['ui.bootstrap', 'ngRoute', 'ngResource', 'wgoodApp',
     'diabloAuthenApp', 'diabloFilterApp', 'diabloNormalFilterApp',
     'diabloPattern', 'diabloUtils', 'userApp'])
// .config(diablo_authen);
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
	when('/wretailer_detail/:page?', {
	    templateUrl: '/private/wretailer/html/wretailer_detail.html',
	    controller: 'wretailerDetailCtrl',
	    resolve: angular.extend({}, province, city, user)
	}).
	when('/wretailer_trans/:retailer?/:ppage?/:cpage?', {
	    templateUrl: '/private/wretailer/html/wretailer_trans.html',
	    controller: 'wretailerTransCtrl',
	    resolve: angular.extend({}, retailer, employee, user, base)
	}).
	when('/wretailer_trans_rsn/:retailer?/:rsn?/:ppage?/:p2page?', {
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
    
    $scope.pattern = {name_address: diabloPattern.ch_name_address,
		      tel_mobile:   diabloPattern.tel_mobile,
		      decimal_2:    diabloPattern.decimal_2,
		      city:         diabloPattern.chinese};

    $scope.check_city = function(city){
	if (city){
	    var name = typeof(city) === 'object' ? city.name : city;
	    return $scope.pattern.city.test(name);
	} else {
	    return true;
	}
	
    }
    
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
    $scope, $location, $routeParams, diabloPattern, diabloUtilsService,
    diabloPagination, wretailerService, filterProvince, filterCity){
    $scope.provinces = angular.copy(filterProvince);
    $scope.cities    = angular.copy(filterCity);
    
    var dialog = diabloUtilsService;
    var f_add  = diablo_float_add;

    /*
     * pagination
     */
    $scope.colspan = 9;
    $scope.max_page_size = 10;
    $scope.items_perpage = 10;
    $scope.default_page = 1;
    $scope.current_page = $scope.default_page;

    $scope.page_changed = function(page){
	// console.log(page);
	$scope.filter_retailers = diabloPagination.get_page(page);
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
	    $scope.total_balance = f_add($scope.total_balance, f.balance);
	});

	// re pagination
	diabloPagination.set_data(filters);
	$scope.total_items      = diabloPagination.get_length();
	$scope.filter_retailers = diabloPagination.get_page($scope.default_page);
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
	wretailerService.list_retailer().then(function(data){
	    // console.log(data);
	    $scope.retailers = angular.copy(data);
	    $scope.total_balance = 0;
	    angular.forEach($scope.retailers, function(r){
		r.province = diablo_get_object(r.pid, $scope.provinces);
		r.city     = diablo_get_object(r.cid, $scope.cities);
		$scope.total_balance = f_add($scope.total_balance, r.balance);
	    })
	    
	    diablo_order($scope.retailers);

	    diabloPagination.set_data($scope.retailers);
	    diabloPagination.set_items_perpage($scope.items_perpage);
	    $scope.total_items      = diabloPagination.get_length();
	    $scope.filter_retailers = diabloPagination.get_page($scope.current_page);
	    // console.log($scope.filter_retailers);

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
		    if (!in_prompt(r.city.name, $scope.prompts)){
			$scope.prompts.push(
			    {name: r.city.name, py:diablo_pinyin(r.city.name)}); 	
		    } 
		}
	    }

	    if (angular.isDefined($routeParams.page)){
		var page = parseInt($routeParams.page);
		if (page != $scope.current_page){
		    $scope.current_page = page;
		    $scope.page_changed($scope.current_page); 
		}
	    } 
	})
    };

    $scope.do_refresh = function(){
	// console.log("do_refresh");
	// $routeParams.page = $scope.default_page;
	$location.path("/wretailer_detail");
	$scope.current_page = $scope.default_page;
	$scope.refresh($scope.default_page);
    }
    
    $scope.refresh();

    $scope.new_retailer = function(){
	$location.path("/wretailer_new"); 
    };

    $scope.trans_info = function(r){
	// console.log(r.id); 
	diablo_goto_page("#/wretailer_trans/" +r.id.toString()
			+ "/" + $scope.current_page.toString())
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
	    if (angular.isDefined(update_retailer.city) && update_retailer.city
		&& angular.isUndefined(update_retailer.province) && !update_retailer.province){
		update_retailer.province = params.retailer.province;
	    }
	    
	    console.log(update_retailer);

	    wretailerService.update_retailer(update_retailer).then(function(result){
    		console.log(result);
    		if (result.ecode == 0){
		    dialog.response_with_callback(
			true, "零售商编辑",
			"恭喜你，零售商 [" + old_retailer.name + "] 信息修改成功！！",
			$scope, function(){
			    if (typeof(update_retailer.city) !== 'object'
				&& update_retailer.city){
				if (angular.isUndefined(diablo_get_object(result.cid, $scope.cities))){
				    $scope.cities.push({
					id:   result.cid,
					name: update_retailer.city,
					py:   diablo_pinyin(update_retailer.city)})
				} 
			    }
			    console.log($scope.cities);
			    $scope.refresh()
			});
    		} else{
		    dialog.response(
			false, "零售商编辑",
			"零售商编辑失败：" + wretailerService.error[result.ecode]);
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
	
	dialog.edit_with_modal(
	    "update-wretailer.html", undefined, callback, $scope,
	    {retailer:    old_retailer,
	     provinces:   $scope.provinces,
	     cities:      $scope.cities,
	     pattern:     pattern,
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
			"删除零售商失败：" + wretailerService.error[result.ecode]);
    		}
    	    })
	};

	diabloUtilsService.request(
	    "删除零售商", "确定要删除该零售商吗？", callback, undefined, $scope);
    }
});

wretailerApp.controller("wretailerCtrl", function(){});

wretailerApp.controller("loginOutCtrl", function($scope, $resource){
    $scope.home = function () {
	diablo_login_out($resource)
    };
});
