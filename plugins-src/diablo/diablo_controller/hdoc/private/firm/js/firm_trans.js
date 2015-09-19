firmApp.controller('firmTransCtrl', function(
    $scope, $routeParams, diabloFilter, firmService,
    diabloUtilsService, filterFirm, filterEmployee, user){

    console.log(filterFirm);
    // console.log($routeParams.retailer);
    var firm_id = parseInt($routeParams.firm);
    $scope.firm = diablo_get_object(firm_id, filterFirm);
    console.log($scope.firm);

    $scope.shops   = user.sortBadRepoes.concat(user.sortShops);
    $scope.shopIds = user.shopIds.concat(user.badrepoIds);
    
    $scope.goto_page = diablo_goto_page;
    $scope.f_add = diablo_float_add;
    $scope.f_sub = diablo_float_sub;

    $scope.back = function(){
	$scope.goto_page("#/firm_detail/" + $routeParams.ppage.toString())
    }


    /*
     * hide column
     */
    $scope.hide_column = true;
    $scope.toggle_left = function(){
	$scope.hide_column = !$scope.hide_column;
    }

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
    $scope.time   = diabloFilter.default_time(); 


    /*
     * pagination 
     */
    $scope.colspan = 18;
    $scope.items_perpage = 10;
    $scope.max_page_size = 10;
    $scope.default_page = 1;

    $scope.do_search = function(page){
	console.log(page);
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    if (angular.isUndefined(search.shop)
		|| !search.shop || search.shop.length === 0){
		search.shop = $scope.shopIds.length
		    === 0 ? undefined : $scope.shopIds; 
	    }
	    
	    search.firm = firm_id;

	    firmService.filter_w_inventory_new(
		$scope.match, search, page, $scope.items_perpage).then(function(result){
		    console.log(result);
		    if (page === 1){
			$scope.total_items      = result.total
			$scope.total_amounts    = result.t_amount;
			$scope.total_spay       = result.t_spay;
			$scope.total_hpay       = result.t_hpay;
			$scope.total_cash       = result.t_cash;
			$scope.total_card       = result.t_card;
			$scope.total_wire       = result.t_wire;
			$scope.total_verificate = result.t_verificate;
		    }
		    angular.forEach(result.data, function(d){
			d.firm = diablo_get_object(d.firm_id, filterFirm);
			d.shop = diablo_get_object(d.shop_id, $scope.shops);
			d.employee = diablo_get_object(d.employee_id, filterEmployee);
		    });
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
    	diablo_goto_page("#/firm_trans_rsn/" + firm_id.toString()
			 + "/" + r.rsn
			 + "/" + $routeParams.ppage
			 + "/" + $scope.current_page.toString());
    };

    $scope.check_trans = function(r){
	console.log(r);
	var callback = function(){
	    firmService.check_w_inventory_new(r.rsn).then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    diabloUtilsService.response_with_callback(
			true, "厂商对帐单审核", "厂商对帐单审核成功！！单号：" + state.rsn,
			$scope, function(){r.state = 1})
	    	    return;
		} else{
	    	    diabloUtilsService.response(
	    		false, "厂商对帐单审核",
	    		"厂商对帐单审核失败：" + firmService.error[state.ecode]);
		}
	    })
	};

	diabloUtilsService.request(
	    "厂商对帐单审核", "审核完成后，对帐单将无法修改，确定要审核吗？",
	    callback, undefined, $scope); 
    };

    $scope.print = function(r){
	
    }; 
})


firmApp.controller("firmTransRsnDetailCtrl", function(
    $scope, $routeParams, dateFilter, diabloUtilsService, diabloFilter,
    wgoodService, firmService,
    filterBrand, filterFirm, filterEmployee, filterSizeGroup,
    filterType, user){
    // console.log($routeParams);

    // console.log(filterEmployee);
    var firm_id = parseInt($routeParams.firm);
    $scope.firm = diablo_get_object(firm_id, filterFirm);
    
    // style_number
    $scope.match_style_number = function(viewValue){
	return diabloFilter.match_w_inventory(viewValue, user.shopIds);
    };

    $scope.goto_page = diablo_goto_page;

    // console.log($routeParams);
    $scope.back = function(){
	console.log($routeParams);
	$scope.goto_page("#/firm_trans/" + $routeParams.firm
			 + "/" + $routeParams.ppage.toString()
			 + "/" + $routeParams.p2page.toString());
    }

    // initial
    $scope.filters = [];
    diabloFilter.reset_field();
    
    diabloFilter.add_field("style_number", $scope.match_style_number);
    diabloFilter.add_field("brand",        filterBrand);
    diabloFilter.add_field("type",         filterType);
    diabloFilter.add_field("shop",         user.sortShops);
    // diabloFilter.add_field("employee",     filterEmployee);
    
    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();
    $scope.time   = diabloFilter.default_time();
    
    /*
     * pagination 
     */
    $scope.colspan = 14;
    $scope.items_perpage = 10;
    $scope.max_page_size = 10;
    $scope.default_page = 1; 

    $scope.do_search = function(page){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    search.firm = firm_id;
	    if (angular.isUndefined(search.shop)
	    	|| !search.shop || search.shop.length === 0){
	    	search.shop = user.shopIds.length
		    === 0 ? undefined : user.shopIds;; 
	    };

	    if (angular.isUndefined(search.rsn)){
		search.rsn  =  $routeParams.rsn ? $routeParams.rsn : undefined; 
	    }
	    
	    firmService.filter_w_inventory_new_rsn_group(
		$scope.match, search, page, $scope.items_perpage).then(function(result){
		    console.log(result);
		    if (page === 1){
			$scope.total_items = result.total;
			$scope.total_amounts = result.t_amount;
		    }
		    
		    $scope.inventories = angular.copy(result.data);
		    angular.forEach($scope.inventories, function(inv){
			inv.shop     = diablo_get_object(inv.shop_id, user.sortShops);
			inv.employee = diablo_get_object(inv.employee_id, filterEmployee);
			inv.firm     = diablo_get_object(inv.firm_id, filterFirm);
			inv.brand    = diablo_get_object(inv.brand_id, filterBrand);
			inv.itype    = diablo_get_object(inv.type_id, filterType);
		    });
		    
		    diablo_order_page(page, $scope.items_perpage, $scope.inventories);
		})
	}) 
    }

    // default the first page
    $scope.do_search($scope.default_page);

    $scope.page_changed = function(){
	$scope.do_search($scope.current_page);
    }

    var get_amount = diablo_get_amount;
    
    $scope.rsn_detail = function(inv){
	console.log(inv);
	if (angular.isDefined(inv.amounts)
	    && angular.isDefined(inv.colors)
	    && angular.isDefined(inv.sizes)){
	    
	    diabloUtilsService.edit_with_modal(
		"rsn-detail.html", undefined, undefined, $scope,
		{colors:     inv.colors,
		 sizes:      inv.sizes,
		 amounts:    inv.amounts,
		 total:      inv.total,
		 path:       inv.path,
		 get_amount: get_amount});
	    return;
	}

	firmService.w_inventory_new_rsn_detail(
	    {rsn:inv.rsn, style_number:inv.style_number, brand:inv.brand_id}
	).then(function(result){
	    console.log(result);
	    
	    var order_sizes = wgoodService.format_size_group(inv.s_group, filterSizeGroup);
	    //console.log(order_sizes);
	    var sort = diablo_sort_inventory(result.data, order_sizes);
	    console.log(sort);
	    inv.sizes   = sort.size;
	    inv.colors  = sort.color;
	    inv.amounts = sort.sort;

	    diabloUtilsService.edit_with_modal(
		"rsn-detail.html", undefined, undefined, $scope,
		{colors:     inv.colors,
		 sizes:      inv.sizes,
		 amounts:    inv.amounts,
		 total:      inv.total,
		 path:       inv.path,
		 get_amount: get_amount});
	}); 
    }; 
});
