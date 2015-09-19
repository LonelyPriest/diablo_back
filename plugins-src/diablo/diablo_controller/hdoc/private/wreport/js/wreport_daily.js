wreportApp.controller("wreportDailyCtrl", function(
    $scope, diabloFilter, wreportService, filterEmployee, filterRetailer, user){
    $scope.employees = filterEmployee;
    $scope.retailers = filterRetailer;
    $scope.sortShops = user.sortShops;

    // pagination
    $scope.max_page_size     = wreportService.max_page_size;
    // $scope.items_perpage     = wreportService.items_perpage;
    $scope.items_perpage     = wreportService.items_perpage;

    // shop
    $scope.report_shop_colspan = 5;
    $scope.current_shop_page = wreportService.default_page;
    // employee
    $scope.report_employee_colspan=5;
    $scope.current_employee_page = wreportService.default_page;
    // retailer
    $scope.report_retailer_colspan=5;
    $scope.current_retailer_page = wreportService.default_page;


    var now = $.now(); 
    var day = {start_time:now, end_time:now}; 
    var one_shop_report = {t_amount: 0, t_hpay: 0, t_spay: 0};
    var last_shop_page = 0;
    var unused_shops = angular.copy(user.sortShops);
    
    $scope.do_search_by_shop = function(page){
	console.log(page);

	if (page === last_shop_page){
	    return;
	}

	
	diabloFilter.do_filter([], day, function(search){
	    search.shop = user.shopIds.length === 0 ? undefined : user.shopIds;
	    
	    wreportService.daily_report("by_shop", search, page).then(function(result){
		console.log(result);
		if (page === 1){
		    $scope.total_items    = result.total === user.sortShops.length
			? result.total: user.sortShops.length;
		    $scope.total_amounts  = result.t_amount;
		    $scope.total_spay     = result.t_spay;
		    $scope.total_hpay     = result.t_hpay;
		}

		// if ($scope.total_items === user.sortShops.length){
		//     $scope.shop_reports = result.data;
		// } else {
		$scope.shop_reports = result.data.map(function(d){
		    return {t_amount: d.t_amount,
			    t_spay:   d.t_spay,
			    t_hpay:   d.t_hpay,
			    shop:     diablo_get_object(d.shop_id, $scope.sortShops)}
		});
		
		unused_shops = 
		    unused_shops.filter(function(s){
			for (var i=0, l=result.data.length; i<l; i++){
			    if (s.id === result.data[i].shop_id){
				return false;
			    }
			} 
			return true;
		    })
		console.log(unused_shops);
		
		if ($scope.items_perpage === result.data.length){
		    // $scope.shop_reports = result.data;
		    unused_shops = 
			unused_shops.filter(function(s){
			    for (var i=0, l=result.data.length; i<l; i++){
				if (s.id === result.data[i].shop_id){
				    return false;
				}
			    } 
			    return true;
			})
		    console.log(unused_shops);
		} else{
		    for (var i=0, l=unused_shops.length; i<l; i++){
			if($scope.shop_reports.length < $scope.items_perpage){
			    $scope.shop_reports.push(
				angular.extend({shop:unused_shops[i]}, one_shop_report));
			}
		    } 
		}
		// }

		console.log(unused_shops);
		console.log($scope.shop_reports);
		diablo_order_page(page, $scope.items_perpage, $scope.shop_reports);

		last_shop_page = page;
	    })
	}) 
    };

    var last_employee_page = 0;
    $scope.do_search_by_employee = function(page){
	console.log(page);

	if (page === last_employee_page){
	    return;
	}
	
	diabloFilter.do_filter([], day, function(search){
	    search.shop = user.shopIds.length === 0 ? undefined : user.shopIds;
	    
	    wreportService.daily_report("by_employee", search, page).then(function(result){
		console.log(result);
		if (page === 1){
		    $scope.e_total_items    = result.total 
		    $scope.e_total_amounts  = result.t_amount;
		    $scope.e_total_spay     = result.t_spay;
		    $scope.e_total_hpay     = result.t_hpay;
		}

		$scope.employee_reports = result.data.map(function(d){
		    return {t_amount: d.t_amount,
			    t_spay:   d.t_spay,
			    t_hpay:   d.t_hpay,
			    employee: diablo_get_object(d.employee_id, $scope.employees)}
		});

		diablo_order_page(page, $scope.items_perpage, $scope.employee_reports);
		
		last_employee_page = page;
	    }) 
	})
    };

    var last_retailer_page = 0;
    $scope.do_search_by_retailer = function(page){
	console.log(page);

	if (page === last_retailer_page){
	    return;
	}
	
	diabloFilter.do_filter([], day, function(search){
	    search.shop = user.shopIds.length === 0 ? undefined : user.shopIds;
	    
	    wreportService.daily_report("by_retailer", search, page).then(function(result){
		console.log(result);
		if (page === 1){
		    $scope.r_total_items    = result.total 
		    $scope.r_total_amounts  = result.t_amount;
		    $scope.r_total_spay     = result.t_spay;
		    $scope.r_total_hpay     = result.t_hpay;
		}

		// console.log($scope.retailers);
		$scope.retailer_reports = result.data.map(function(d){
		    return {t_amount: d.t_amount,
			    t_spay:   d.t_spay,
			    t_hpay:   d.t_hpay,
			    retailer: diablo_get_object(d.retailer_id, $scope.retailers)}
		});

		diablo_order_page(page, $scope.items_perpage, $scope.retailer_reports); 
		last_retailer_page = page;
	    })
	})
    };
});
