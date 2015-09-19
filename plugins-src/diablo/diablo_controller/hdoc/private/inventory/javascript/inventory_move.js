inventoryApp.controller(
    "inventoryMoveCtrl",
    function($scope, inventoryService,
	     ngTableUtils, diabloUtilsService){

	// console.log(user.shop);

	$scope.seasons = diablo_season;
	$scope.sexs    = diablo_sex;

	// shops to be moved
	inventoryService.list_shop().$promise.then(function(shops){
	    $scope.shops = shops;
	    console.log(shops)
	});

	$scope.valid_shops = function(inv){
	    var valid = [];
	    for (var i=0, l=$scope.shops.length; i<l; i++){
		if ($scope.shops[i].id === inv.shop_id){
		    continue;
		};
		valid.splice(-1, 0, $scope.shops[i]);
	    }

	    // console.log(valid);
	    return valid;
	};

	$scope.inventories = [];
	$scope.filter = {style_number:''}
	inventoryService.list_all().$promise.then(function(invs){
	    console.log(invs);
	    var inc = 1
	    angular.forEach(invs, function(inv){
		if (inv.amount !== 0){
		    inv.range = diablo_range(inv.amount);
		    inv.order_id = inc;
		    $scope.inventories.push(inv);
		    inc++;
		}		
	    });

	    console.log($scope.inventories);
	    $scope.inventoryTable =
		ngTableUtils.tbl_of_filter($scope.inventories, $scope.filter);
	});

	$scope.move_inventory = function(inv){
	    console.log(inv);
	    inventoryService.pre_move_inventory({
		sn: inv.sn,
		style_number: inv.style_number,
		source: inv.shop_id,
		target: inv.target.id,
		amount: inv.move_amount}).$promise.then(function(state){
		    if (state.ecode == 0){
			diabloUtilsService.response(
			    true, "移仓", inv.shop_name + " --> " + inv.target.name
			    + "移仓成功，请等待对方确认！");
			// reset
			inv.amount = inv.amount - inv.move_amount;
			inv.range  = diablo_range(inv.amount);
			inv.move_amount = 0;
			inv.move   = false;
		    } else{
			diabloUtilsService.response(
			    false, "移仓", inv.shop_name + " --> " + inv.target.name
			    + "移仓失败，原因：" + inventoryService.error[state.ecode])
		    }
		});
	};
    });



inventoryApp.controller(
    "inventoryMoveDetailCtrl",
    function($scope, inventoryService,
	     ngTableUtils, diabloUtilsService){

	$scope.seasons    = diablo_season;
	$scope.sexs       = diablo_sex;
	$scope.move_state = diablo_move_state;
	
	// shops
	inventoryService.list_shop().$promise.then(function(shops){
	    $scope.shops = shops;
	    console.log(shops)
	});

	$scope.filter = {style_number:''}
	inventoryService.list_move_inventory().$promise.then(function(invs){
	    console.log(invs);
	    $scope.inventories = invs;
	    var inc = 1
	    angular.forEach($scope.inventories, function(inv){
		inv.year = inv.year.slice(0, 4);
		inv.order_id = inc;
		inc++;
	    });

	    console.log($scope.inventories);
	    $scope.inventoryTable =
		ngTableUtils.tbl_of_filter($scope.inventories, $scope.filter);
	});

	$scope.to_shop_name = function(shopId){
	    for (var i=0, l=$scope.shops.length; i<l; i++){
		if ($scope.shops[i].id === shopId){
		    return $scope.shops[i].name
		};
	    }
	};

	$scope.do_move = function(inv){
	    inventoryService.do_move(inv).$promise.then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    diabloUtilsService.response(
			true, "移仓", $scope.to_shop_name(inv.target) + "接收成功："
			    + "款号" + inv.style_number
			    + "，转移数量：" + inv.amount.toString());
			// disable to ne repeat operation
			inv.state = 1;
			// location.reload();
		} else{
		    diabloUtilsService.response(
			false, "移仓", $scope.to_shop_name(inv.target) + "接收失败，原因："
			    + inventoryService.error[state.ecode])
		}
	    });
	}
	
    });
