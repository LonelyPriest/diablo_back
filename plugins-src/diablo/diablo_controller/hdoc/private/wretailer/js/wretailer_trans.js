wretailerApp.controller('wretailerTransCtrl', function(
    $scope, $routeParams, diabloFilter, wretailerService,
    diabloUtilsService, filterRetailer, filterEmployee, user, base){

    // console.log(filterRetailer);
    // console.log($routeParams.retailer);
    var retailer_id = parseInt($routeParams.retailer);
    $scope.retailer = diablo_get_object(retailer_id, filterRetailer);
    console.log($scope.retailer);

    $scope.shops     = user.sortBadRepoes.concat(user.sortShops);
    $scope.shopIds   = user.shopIds.concat(user.badrepoIds);
    $scope.goto_page = diablo_goto_page;
    $scope.float_add = diablo_float_add;
    $scope.float_sub = diablo_float_sub;

    $scope.back = function(){
	$scope.goto_page("#/wretailer_detail/" + $routeParams.ppage.toString())
    }

    
    $scope.hide_column = true;
    $scope.toggle_left = function(){
	$scope.hide_column = !$scope.hide_column;
    };

    var now = $.now();

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
    
    /* 
     * filter operation
     */ 
    // initial
    $scope.filters = [];
    diabloFilter.reset_field();

    // diabloFilter.add_field("rsn", []);
    diabloFilter.add_field("shop",     $scope.shops);
    // diabloFilter.add_field("retailer", filterRetailer);
    diabloFilter.add_field("employee", filterEmployee);

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();
    $scope.time   = diabloFilter.default_time($scope.qtime_start);
    // $scope.time   = diabloFilter.default_time(); 


    /*
     * pagination 
     */
    $scope.colspan = 17;
    $scope.items_perpage = 10;
    $scope.max_page_size = 10;
    $scope.default_page = 1;

    $scope.do_search = function(page){
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
		if (page === 1){
		    $scope.total_items      = result.total;
		    $scope.total_amounts    = result.t_amount;
		    $scope.total_spay       = result.t_spay;
		    $scope.total_hpay       = result.t_hpay;
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
    $scope.do_search($scope.default_page);

    $scope.trans_rsn_detail = function(r){
    	console.log(r);
    	// $location.url("#/wsale_detail/" + r.rsn);
    	diablo_goto_page("#/wretailer_trans_rsn/" + retailer_id + "/" + r.rsn
			 + "/" + $routeParams.ppage
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
    filterType, user){
    // console.log($routeParams);

    // console.log(filterEmployee);
    var retailer_id = parseInt($routeParams.retailer);
    $scope.retailer = diablo_get_object(retailer_id, filterRetailer);
    $scope.flot_mul = diablo_float_mul;

    // style_number
    $scope.match_style_number = function(viewValue){
	return diabloFilter.match_w_inventory(viewValue, user.shopIds);
    };

    $scope.goto_page = diablo_goto_page;

    console.log($routeParams);
    $scope.back = function(){
	$scope.goto_page("#/wretailer_trans/" + $routeParams.retailer
			 + "/" + $routeParams.ppage.toString()
			 + "/" + $routeParams.p2page.toString());
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
    $scope.time   = diabloFilter.default_time();
    
    /*
     * pagination 
     */
    $scope.colspan = 17;
    $scope.items_perpage = 10;
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
	    
	    console.log(search);

	    wretailerService.filter_w_sale_rsn_group(
		$scope.match, search, page, $scope.items_perpage
	    ).then(function(result){
		console.log(result);
		if (page === 1){
		    $scope.total_items = result.total;
		    $scope.total_amounts = result.total === 0 ? 0 : result.t_amount;
		    $scope.total_balance =
			result.total === 0 ? 0 : diablo_float_mul(result.t_balance, 0.01); 
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
