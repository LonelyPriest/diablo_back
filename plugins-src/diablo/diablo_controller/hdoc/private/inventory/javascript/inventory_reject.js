inventoryApp.controller("inventoryRejectCtrl", function(
    $scope, inventoryService, ngTableUtils, diabloUtilsService){

    $scope.seasons = diablo_season;
    $scope.sexs    = diablo_sex;
    
    $scope.inventories = [];
    $scope.filter = {style_number:''}
    inventoryService.list_all().$promise.then(function(invs){
	console.log(invs);
	var inc = 1
	angular.forEach(invs, function(inv){
	    if (inv.amount !== 0){
		inv.range = diablo_range(inv.amount);
		inv.move_amount = inv.range[0];
		inv.order_id = inc;
		$scope.inventories.push(inv);
		inc++;
	    }		
	});

	console.log($scope.inventories);
	$scope.inventoryTable =
	    ngTableUtils.tbl_of_filter($scope.inventories, $scope.filter);
    });


    $scope.reject_inventory = function(inv){
	console.log(inv);
	inventoryService.reject_inventory({
	    sn: inv.sn,
	    style_number: inv.style_number,
	    shop: inv.shop_id,
	    amount: inv.move_amount}).$promise.then(function(state){
		if (state.ecode == 0){
		    diabloUtilsService.response_with_callback(
			true,
			"退货",
			"退货成功，款号：" + inv.style_number
			    + "，数量：" + inv.move_amount,
			$scope,
			function(){
			// reset
			inv.amount = inv.amount - inv.move_amount;
			inv.move = false;
			inv.range = diablo_range(inv.amount);
		    });
		    
		} else{
		    diabloUtilsService.response(
			false, "退货失败",
			"退货失败，原因：" + inventoryService.error[state.ecode],
			$scope)
		    // reset
		    // inv.move = false;
		}
	    });
    };
    
});


inventoryApp.controller("inventoryRejectDetailCtrl", function(
    $scope, inventoryService, ngTableUtils){

    $scope.seasons = diablo_season;
    $scope.sexs    = diablo_sex;
    
    $scope.filter = {style_number:''}
    inventoryService.list_reject_inventory().$promise.then(function(invs){
	console.log(invs);
	$scope.inventories = invs;
	var inc = 1
	angular.forEach($scope.inventories, function(inv){
	    if (inv.amount !== 0){
		inv.year = inv.year.slice(0,4);
		inv.order_id = inc;
		inc++;
	    }		
	});

	console.log($scope.inventories);
	$scope.inventoryTable =
	    ngTableUtils.tbl_of_filter($scope.inventories, $scope.filter);
    });
});
