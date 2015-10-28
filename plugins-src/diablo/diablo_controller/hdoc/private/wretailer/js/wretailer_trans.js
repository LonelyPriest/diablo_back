wretailerApp.controller('wretailerTransCtrl', function(
    $scope, $routeParams, $location, diabloFilter, wretailerService,
    localStorageService, diabloUtilsService,
    filterRetailer, filterEmployee, user, base){

    // console.log(filterRetailer);
    // console.log($routeParams.retailer);
    var retailer_id = parseInt($routeParams.retailer);
    $scope.retailer = diablo_get_object(retailer_id, filterRetailer);
    // console.log($scope.retailer);

    $scope.shops     = user.sortBadRepoes.concat(user.sortShops);
    $scope.shopIds   = user.shopIds.concat(user.badrepoIds);
    $scope.goto_page = diablo_goto_page;
    $scope.float_add = diablo_float_add;
    $scope.float_sub = diablo_float_sub;
    $scope.round     = diablo_round;

    $scope.show = {base:false, balance:false, comment:false};
    
    $scope.toggle_balance = function(){
	$scope.show.balance = !$scope.show.balance;
    };

    $scope.toggle_base = function(){
	$scope.show.base = !$scope.show.base;
    };

    $scope.toggle_comment = function(){
	$scope.show.comment = !$scope.show.comment;
    }; 
    
    var now          = $.now();

    $scope.go_back = function(){
	localStorageService.remove(diablo_key_retailer_trans);
	$scope.goto_page("#/wretailer_detail")
    };

    /*
     * local sate
     */ 
    $scope.save_to_local = function(filter, time){
	var s = localStorageService.get(diablo_key_retailer_trans);

	if (angular.isDefined(s) && s !== null){
	    localStorageService.set(
		diablo_key_retailer_trans, {
		    filter:angular.isDefined(filter) ? filter:s.filter,
		    start_time:angular.isDefined(time)
			? diablo_get_time(time) :s.time, 
		    page:$scope.current_page,
		    t:now}
	    )
	} else {
	    localStorageService.set(
		diablo_key_retailer_trans, {
		    filter:   filter,
		    start_time: angular.isDefined(time)
			? diablo_get_time(time) : undefined,
		    page:     $scope.current_page,
		    t:        now})
	}
    };
    
    /* 
     * filter operation
     */ 
    // initial
    // $scope.filters = [];
    diabloFilter.reset_field(); 
    // diabloFilter.add_field("rsn", []);
    diabloFilter.add_field("shop",     $scope.shops);
    // diabloFilter.add_field("retailer", filterRetailer);
    diabloFilter.add_field("employee", filterEmployee);

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    var storage = localStorageService.get(diablo_key_retailer_trans);
    // console.log(storage);
    if (angular.isDefined(storage) && storage !== null){
	$scope.filters      = storage.filter;
	$scope.qtime_start  = storage.start_time; 
    } else {
	$scope.filters = [];
	$scope.qtime_start = function(){
	    // -1 use the default setting
	    var shop = -1
	    if ($scope.shopIds.length === 1){
		shop = $scope.shopIds[0];
	    };
	    return diablo_base_setting(
		"qtime_start", shop, base, diablo_set_date,
		diabloFilter.default_start_time(now));
	}(); 
    }

    $scope.time         = diabloFilter.default_time($scope.qtime_start); 

    /*
     * pagination 
     */
    $scope.colspan = 17;
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = 10;
    $scope.default_page = 1;

    var back_page = diablo_set_integer($routeParams.page);
    if (angular.isDefined(back_page)){
	$scope.current_page = back_page;
    } else{
	$scope.current_page = $scope.default_page; 
    };

    $scope.refresh = function(){
	$scope.do_search($scope.default_page);
    };

    $scope.do_search = function(page){
	console.log(page);
	$scope.current_page = page;

	// save
	$scope.save_to_local($scope.filters, $scope.time.start_time);
	// recover
	if (angular.isDefined(back_page)){
	    var stastic = localStorageService.get("retailer-trans-stastic");
	    console.log(stastic);
	    $scope.total_items      = stastic.total_items
	    $scope.total_amounts    = stastic.total_amounts;
	    $scope.total_spay       = stastic.total_spay;
	    $scope.total_hpay       = stastic.total_hpay;
	    $scope.total_cash       = stastic.total_cash;
	    $scope.total_card       = stastic.total_card;
	    $scope.total_wire       = stastic.total_wire;
	    $scope.total_verificate = stastic.total_verificate;
	    
	    $location.path("/retailer_trans/" + retailer_id.toString(), false);
	    $routeParams.page = undefined;
	    back_page         = undefined;
	    localStorageService.remove("retailer-trans-stastic");
	};
	
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    if (angular.isUndefined(search.shop)
		|| !search.shop || search.shop.length === 0){
		search.shop = $scope.shopIds.length === 0 ? undefined : $scope.shopIds; 
	    }
	    
	    search.retailer = retailer_id;
	    
	    wretailerService.filter_w_sale_new(
		$scope.match, search, page, $scope.items_perpage
	    ).then(function(result){
		console.log(result);
		if (page === 1 && angular.isUndefined(back_page)){
		    $scope.total_items      = result.total;
		    $scope.total_amounts    = result.t_amount;
		    $scope.total_spay       = $scope.round(result.t_spay);
		    $scope.total_hpay       = $scope.round(result.t_hpay);
		    $scope.total_cash       = result.t_cash;
		    $scope.total_card       = result.t_card;
		    $scope.total_wire       = result.t_wire;
		    $scope.total_verificate = result.t_verificate;
		}
		angular.forEach(result.data, function(d){
		    d.shop = diablo_get_object(d.shop_id, $scope.shops);
		    d.employee = diablo_get_object(d.employee_id, filterEmployee);
		    // d.retailer = diablo_get_object(d.retailer_id, filterRetailer);
		})
		$scope.records = result.data; 
		diablo_order_page(page, $scope.items_perpage, $scope.records);
	    })
	})
    };
    
    $scope.page_changed = function(){
	$scope.do_search($scope.current_page);
    }
    
    // default the first page
    $scope.do_search($scope.current_page);

    $scope.trans_rsn_detail = function(r){
    	console.log(r);
    	// $location.url("#/wsale_detail/" + r.rsn);
	localStorageService.set(
	    "retailer-trans-stastic"  ,
	    {total_items       :$scope.total_items,
	     total_amounts     :$scope.total_amounts,
	     total_spay        :$scope.total_spay,
	     total_hpay        :$scope.total_hpay,
	     total_cash        :$scope.total_cash,
	     total_card        :$scope.total_card,
	     total_wire        :$scope.total_wire,
	     total_verificate  :$scope.total_verificate,
	     t:                 now});
	
    	diablo_goto_page("#/wretailer_trans_rsn/" + retailer_id.toString()
			 + "/" + r.rsn
			 + "/" + $scope.current_page.toString());
    };

    $scope.check_trans = function(r){
	console.log(r);
	var callback = function(){
	    wretailerService.check_w_sale_new(r.rsn).then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    diabloUtilsService.response_with_callback(
			true, "对帐单审核", "对帐单审核成功！！单号：" + state.rsn,
			$scope, function(){r.state = 1})
	    	    return;
		} else{
	    	    diabloUtilsService.response(
	    		false, "对帐单审核",
	    		"对帐单审核失败：" + wretailerService.error[state.ecode]);
		}
	    })
	};

	diabloUtilsService.request(
	    "销售单审核", "审核完成后，销售单将无法修改，确定要审核吗？",
	    callback, undefined, $scope); 
    };

    $scope.print = function(r){
	
    }; 
})


wretailerApp.controller("wretailerTransRsnDetailCtrl", function(
    $scope, $routeParams, dateFilter, diabloUtilsService, diabloFilter,
    wgoodService, wretailerService,
    filterBrand, filterFirm, filterRetailer, filterEmployee, filterSizeGroup,
    filterType, user, base){
    // console.log($routeParams);

    // console.log(filterEmployee);
    var retailer_id = parseInt($routeParams.retailer);
    $scope.retailer = diablo_get_object(retailer_id, filterRetailer);
    $scope.flot_mul = diablo_float_mul; 
    $scope.shopIds  = user.shopIds;
    $scope.round    = diablo_round;

    /*
     * hidden
     */
    $scope.hidden      = {base:true}; 
    $scope.toggle_base = function(){$scope.hidden.base = !$scope.hidden.base};
    
    var now            = $.now();

    // style_number
    $scope.match_style_number = function(viewValue){
	return diabloFilter.match_w_inventory(viewValue, user.shopIds);
    };

    $scope.goto_page = diablo_goto_page;

    // console.log($routeParams);
    $scope.back = function(){
	$scope.goto_page("#/wretailer_trans/" + $routeParams.retailer
			 + "/" + $routeParams.ppage.toString());
    }

    // initial
    $scope.filters = [];
    diabloFilter.reset_field();
    
    diabloFilter.add_field("style_number", $scope.match_style_number);
    diabloFilter.add_field("brand",        filterBrand);
    diabloFilter.add_field("type",         filterType);
    diabloFilter.add_field("firm",         filterFirm);
    diabloFilter.add_field("shop",         user.sortShops);
    diabloFilter.add_field("employee",     filterEmployee);
    
    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    $scope.qtime_start = function(){
	var shop = -1
	if ($scope.shopIds.length === 1){
	    shop = $scope.shopIds[0];
	};
	return diablo_base_setting(
	    "qtime_start", shop, base, diablo_set_date,
	    diabloFilter.default_start_time(now));
    }();

    $scope.time = diabloFilter.default_time($scope.qtime_start);
    
    /*
     * pagination 
     */
    $scope.colspan = 17;
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = 10;
    $scope.default_page = 1; 

    $scope.do_search = function(page){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    if (angular.isUndefined(search.rsn)){
		search.rsn  =  $routeParams.rsn ? $routeParams.rsn : undefined; 
	    }
	    
	    if (angular.isUndefined(search.shop)
	    	|| !search.shop || search.shop.length === 0){
	    	search.shop = user.shopIds; 
	    };
	    
	    // console.log(search);

	    wretailerService.filter_w_sale_rsn_group(
		$scope.match, search, page, $scope.items_perpage
	    ).then(function(result){
		console.log(result);
		if (page === 1){
		    $scope.total_items = result.total;
		    $scope.total_amounts = result.total === 0 ? 0 : result.t_amount;
		    $scope.total_balance =
			result.total === 0 ? 0 : $scope.round(result.t_balance * 0.01); 
		}
		angular.forEach(result.data, function(d){
		    d.brand = diablo_get_object(d.brand_id, filterBrand);
		    d.firm = diablo_get_object(d.firm_id, filterFirm);
		    d.shop = diablo_get_object(d.shop_id, user.sortShops);
		    // d.retailer = diablo_get_object(d.retailer_id, filterRetailer);
		    d.employee = diablo_get_object(d.employee_id, filterEmployee);
		    d.type = diablo_get_object(d.type_id, filterType);
		})
		$scope.inventories = result.data;
		diablo_order_page(page, $scope.items_perpage, $scope.inventories);
	    })
	})
    }; 

    // default the first page
    $scope.do_search($scope.default_page);

    $scope.page_changed = function(){
	$scope.do_search($scope.current_page);
    } 

    var get_amount = function(cid, size, amounts){
	for(var i=0, l=amounts.length; i<l; i++){
	    if (amounts[i].cid === cid && amounts[i].size === size){
		return amounts[i].count;
	    }
	}
	return undefined;
    };

    
    var in_amount = function(amounts, inv){
	for(var i=0, l=amounts.length; i<l; i++){
	    if(amounts[i].cid === inv.color_id && amounts[i].size === inv.size){
		amounts[i].count += parseInt(inv.amount);
		return true;
	    }
	}
	return false;
    };

    var sort_amounts_by_color = function(colors, amounts){
	console.log(amounts);
	return colors.map(function(c){
	    var row = {total:0, cid:c.cid, cname:c.cname};
	    for(var i=0, l=amounts.length; i<l; i++){
		var a = amounts[i];
		if (a.cid === c.cid){
		    row.total += a.count;
		}
	    };
	    return row;
	})
    }
    
    $scope.rsn_detail = function(inv){
	console.log(inv);
	if (angular.isDefined(inv.amounts)
	    && angular.isDefined(inv.colors)
	    && angular.isDefined(inv.order_sizes)){

	    color_sorts     = sort_amounts_by_color(inv.colors, inv.amounts),
	    
	    diabloUtilsService.edit_with_modal(
		"rsn-detail.html", undefined, undefined, $scope,
		{colors:        inv.colors,
		 sizes:         inv.order_sizes,
		 amounts:       inv.amounts,
		 total:         inv.total, 
		 path:          inv.path,
		 colspan:       inv.sizes.length + 1,
		 get_amount:    get_amount,
		 row_total:     function(cid){
		     return color_sorts.filter(function(s){
			 return cid === s.cid
		     })}
		});
	    return;
	}
	
	wretailerService.w_sale_rsn_detail({
	    rsn:inv.rsn, style_number:inv.style_number, brand:inv.brand_id
	}).then(function(result){
	    console.log(result);
	    
	    var order_sizes = wgoodService.format_size_group(inv.s_group, filterSizeGroup);
	    var sort = wretailerService.sort_inventory(result.data, order_sizes);
	    inv.total       = sort.total; 
	    inv.colors      = sort.color;
	    inv.sizes       = sort.size;
	    inv.amounts     = sort.sort; 
	    // console.log(inv.amounts);
	    color_sorts     = sort_amounts_by_color(inv.colors, inv.amounts),
	    console.log(color_sorts);
	    diabloUtilsService.edit_with_modal(
		"rsn-detail.html", undefined, undefined, $scope,
		{colors:     inv.colors,
		 sizes:      inv.sizes,
		 amounts:    inv.amounts,
		 total:      inv.total,
		 path:       inv.path,
		 colspan:    inv.sizes.length + 1,
		 get_amount: get_amount,
		 row_total:  function(cid){
		     return color_sorts.filter(function(s){
			 return cid === s.cid
		     })}
		});
	});
    }; 
});
