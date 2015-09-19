wsaleApp.controller("wsaleRsnDetailCtrl", function(
    $scope, $routeParams, dateFilter, diabloUtilsService, diabloFilter,
    purchaserService, wgoodService, wsaleService,
    user, filterBrand, filterRetailer, filterEmployee,
    filterFirm, filterSizeGroup, filterType, filterColor, base){
    // console.log($routeParams);

    // console.log(filterEmployee);
    $scope.shops   = user.sortShops.concat(user.sortBadRepoes);
    $scope.shopIds = user.shopIds.concat(user.badrepoIds);
    
    $scope.flot_mul = diablo_float_mul;

    var dialog = diabloUtilsService;

    // $scope.wsale_rsn_title = wsaleService.rsn_title[$routeParams.type];
    // if (angular.isUndefined($scope.wsale_rsn_title)){
    // 	$scope.wsale_rsn_title = wsaleService.rsn_title[wsaleService.rsn_title.length-1];
    // }

    // style_number
    $scope.match_style_number = function(viewValue){
	return diabloFilter.match_w_inventory(viewValue, $scope.shopIds);
    };

    $scope.goto_page = diablo_goto_page;

    $scope.back = function(){
	if(angular.isDefined($routeParams.back_page)){
	    $scope.goto_page("#/new_wsale_detail/" + $routeParams.back_page.toString()) 
	} else{
	    $scope.goto_page("#/new_wsale_detail") 
	}
    }


    var sell_type =  [{name:"销售开单", id:0, py:diablo_pinyin("销售开单")},
    		      {name:"销售退货", id:1, py:diablo_pinyin("销售退货")}];
    
    // initial
    $scope.filters = [];
    diabloFilter.reset_field();
    
    diabloFilter.add_field("sell_type", sell_type);
    diabloFilter.add_field("rsn", []);
    diabloFilter.add_field("style_number", $scope.match_style_number);
    diabloFilter.add_field("brand",    filterBrand);
    diabloFilter.add_field("type",     filterType);
    diabloFilter.add_field("year",     diablo_full_year); 
    diabloFilter.add_field("shop",     $scope.shops);
    diabloFilter.add_field("retailer", filterRetailer);
    diabloFilter.add_field("employee", filterEmployee);
    diabloFilter.add_field("firm",     filterFirm);

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    var now = $.now();
    $scope.qtime_start = function(shopId){
	return diablo_base_setting(
	    "qtime_start", shopId, base, diablo_set_date, diabloFilter.default_start_time(now));
    }();
    // console.log($scope.qtime_start); 
    $scope.time   = diabloFilter.default_time($scope.qtime_start);
    
    /*
     * pagination 
     */
    $scope.colspan = 17;
    $scope.items_perpage = 10;
    $scope.max_page_size = 10;
    $scope.default_page = 1;
    $scope.current_page = $scope.default_page;

    $scope.do_search = function(page){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    if (angular.isUndefined(search.rsn)){
		search.rsn  =  $routeParams.rsn ? $routeParams.rsn : undefined; 
	    };
	    
	    if (angular.isUndefined(search.shop)
	    	|| !search.shop || search.shop.length === 0){
		search.shop = $scope.shopIds.length === 0 ? undefined : $scope.shopIds; 
	    };
	    
	    console.log(search);

	    wsaleService.filter_w_sale_rsn_group(
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
		    d.brand    = diablo_get_object(d.brand_id, filterBrand);
		    d.firm     = diablo_get_object(d.firm_id, filterFirm);
		    d.shop     = diablo_get_object(d.shop_id, $scope.shops);
		    d.retailer = diablo_get_object(d.retailer_id, filterRetailer);
		    d.employee = diablo_get_object(d.employee_id, filterEmployee);
		    d.type     = diablo_get_object(d.type_id, filterType);

		    // d.cur_balance = function(){
		    // 	if (d.type === 0){
		    // 	    float_add(float_add(r.balance, r.should_pay + r.e_pay), -r.has_pay)
		    // 	}
		    // }()
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
	    
	    dialog.edit_with_modal(
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
	
	wsaleService.w_sale_rsn_detail({
	    rsn:inv.rsn, style_number:inv.style_number, brand:inv.brand_id
	}).then(function(result){
	    console.log(result);
	    
	    var order_sizes = wgoodService.format_size_group(inv.s_group, filterSizeGroup);
	    var sort = purchaserService.sort_inventory(result.data, order_sizes, filterColor);
	    // inv.total    = sort.total;
	    inv.colors      = sort.color;
	    inv.sizes       = sort.size;
	    inv.amounts     = sort.sort; 
	    // console.log(inv.amounts);
	    color_sorts     = sort_amounts_by_color(inv.colors, inv.amounts),
	    console.log(color_sorts);
	    dialog.edit_with_modal(
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

    $scope.export_to = function(){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    if (angular.isUndefined(search.rsn)){
		search.rsn  =  $routeParams.rsn ? $routeParams.rsn : undefined; 
	    };
	    
	    if (angular.isUndefined(search.shop)
		|| !search.shop || search.shop.length === 0){
		search.shop = $scope.shopIds.length === 0 ? undefined : $scope.shopIds; 
	    }
	    console.log(search);
	    
	    wsaleService.csv_export(
		wsaleService.export_type.trans_note, search
	    ).then(function(result){
	    	console.log(result);
		if (result.ecode === 0){
		    dialog.response_with_callback(
			true, "文件导出成功", "创建文件成功，请点击确认下载！！", undefined,
			function(){window.location.href = result.url;}) 
		} else {
		    dialog.response(
			false, "文件导出失败", "创建文件失败：" + wsaleService.error[result.ecode]);
		}
	    });
	}) 
    };
});
