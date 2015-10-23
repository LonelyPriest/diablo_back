wreportApp.controller("wreportDailyCtrl", function(
    $scope, diabloFilter, wreportService, filterEmployee, filterRetailer, user){
    $scope.employees = filterEmployee;
    $scope.retailers = filterRetailer;
    $scope.sortShops = user.sortShops;

    // pagination
    $scope.max_page_size       = wreportService.max_page_size;
    // $scope.items_perpage     = wreportService.items_perpage;
    $scope.items_perpage       = wreportService.items_perpage;

    // shop
    $scope.report_shop_colspan = 5;
    $scope.current_shop_page   = wreportService.default_page;
    // employee
    $scope.report_employee_colspan=5;
    $scope.current_employee_page = wreportService.default_page;
    // retailer
    $scope.report_retailer_colspan=5;
    $scope.current_retailer_page = wreportService.default_page;


    var now = $.now();
    var day = {start_time:now - diablo_day_millisecond * 2, end_time:now}; 
    var one_shop_report =
	{t_amount:0, t_hpay:0, t_spay:0,
	 t_cash:0, t_card:0, t_wire:0, t_verificate:0};
    var last_shop_page = 0;
    var unused_shops = angular.copy(user.sortShops);
    
    $scope.do_search_by_shop = function(page){
	console.log(page);

	if (page === last_shop_page){
	    return;
	}

	
	diabloFilter.do_filter([], day, function(search){
	    search.shop =
		user.shopIds.length === 0 ? undefined : user.shopIds;
	    
	    wreportService.daily_report(
		"by_shop", search, page
	    ).then(function(result){
		console.log(result);

		var report_data = angular.copy(result.data);
		
		unused_shops = 
		    unused_shops.filter(function(s){
			for (var i=0, l=report_data.length; i<l; i++){
			    if (s.id === report_data[i].shop_id){
				return false;
			    }
			} 
			return true;
		    })
		console.log(unused_shops);

		$scope.shop_reports = result.data.map(function(d){
		    return {t_amount: d.t_amount,
			    t_spay:   d.t_spay,
			    t_hpay:   d.t_hpay,
			    t_cash:   d.t_cash,
			    t_card:   d.t_card,
			    t_wire:   d.t_wire,
			    t_verificate: d.t_verificate,
			    shop: diablo_get_object(d.shop_id, $scope.sortShops)}
		});

		angular.forEach(unused_shops, function(s){
		    $scope.shop_reports.push(
			angular.extend({shop:s}, one_shop_report))
		});
		
		
		if (page === 1){
		    $scope.total_items =
			result.total === user.sortShops.length
			? result.total : user.sortShops.length;
		    $scope.total_amounts
			= result.t_amount ? result.t_amount : 0;
		    $scope.total_spay
			= result.t_spay ? result.t_spay : 0; 
		    $scope.total_hpay
			= result.t_hpay ? result.t_hpay : 0;
		    $scope.total_cash
			=  result.t_cash ? result.t_cash : 0;
		    $scope.total_card
			=  result.t_card ? result.t_card : 0;
		    $scope.total_wire
			=  result.t_wire ? result.t_wire : 0;
		    $scope.total_verificate
			=  result.t_verificate ? result.t_verificate : 0;
		}

		console.log($scope.shop_reports);
		diablo_order_page(
		    page, $scope.items_perpage, $scope.shop_reports); 
		last_shop_page = page;
	    })
	}) 
    }; 
});
