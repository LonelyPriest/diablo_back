
var saleApp = angular.module(
    "saleApp", ['ngRoute', 'ngResource',
		'ngTable', 'subbmitNotify',
		'ngTableUtils', 'inventoryApp',
		'employApp', 'memberApp',
		'userApp', 'ui.bootstrap',
		'checklist-model', 'diabloUtils']);

saleApp.config(['$routeProvider', function($routeProvider){
    $routeProvider.
	when('/cashier/:pay', {
	    templateUrl: '/private/sale/html/cashier.html',
            controller: 'cashierCtrl',
	    resolve: {
	    	"user": function(userService){
	    	    return userService();
	    	}
	    }
	}).
	when('/sale_detail/:shopId', {
	    templateUrl: '/private/sale/html/sale_detail.html',
            controller: 'detailCtrl',
	    resolve: {
	    	"user": function(userService){
	    	    return userService();
	    	}
	    }
	}).
	when('/reject_exchange', {
	    templateUrl: '/private/sale/html/reject_exchange.html',
            controller: 'rejectExchangeCtrl',
	    resolve: {
	    	"user": function(userService){
	    	    return userService();
	    	}
	    }
	}).
	when('/reject_detail/:shopId', {
	    templateUrl: '/private/sale/html/reject_detail.html',
            controller: 'rejectDetailCtrl',
	    resolve: {
	    	"user": function(userService){
	    	    return userService();
	    	}
	    }
	}).
	otherwise({
	    templateUrl: '/private/sale/html/cashier.html',
            controller: 'cashierCtrl',
	    resolve: {
	    	"user": function(userService){
	    	    return userService();
	    	}
	    }
        })
}]);

saleApp.service("saleService", function($resource, dateFilter){
    var _memberStyle   = [{id : 0, name:"电话号码"},
			  {id : 1, name:"姓名"},
			  {id : 2, name:"会员号"}];

    var _paymentStyle  = [{id : 0, name: "现金"}];

    // var _buyAmount     = [1, 2, 3, 4, 5];
    // var _size   = ["S", "M", "L", "XL", "XXL", "XXXL"];
    
    var _sale = $resource("/sale/:operation/:id",
			  {operation: '@operation', id: '@id'},
			  {
			      'sale_info': {method:'POST', isArray: true},
			      'sale_reject': {method:'POST', isArray: false}
			  });

    var _errinfo = "";

    // error info
    this.error = {1799:"错误！没有要结算的记录或库存为零",
		  1780:"错误！数量不足，款号：" + this._errinfo,
		  1781:"错误！金额不足！！",
		  1805:"库存不足",
		  1803:"结算成功，记录销售单失败，请额外记录此次销售",
		  1804:"结算成功，增加用户记分失败，请额外增加用户积分"};
    
    this.member_style = function(){
	return _memberStyle;
    };

    this.payment_style = function(){
	return _paymentStyle;
    };

    // this.buy_amount = function(){
    // 	return _buyAmount;
    // }

    // this.size = function(){
    // 	return _size;
    // }

    this.set_errinfo = function(info){
	_errinfo = info;
    }

    // this.get_inventory = function(style_number){
    // 	return _sale.get_inventory({operation:"get_inventory", id: style_number})
    // }

    this.payment = function(one){
	//console.log(JSON.stringify(one.inventories));
	var payload = {};
	payload.inventories = one.inventories;
	payload.employ      = one.direction.number;
	payload.total_price = one.total_price;
	payload.shop        = one.shop;
	if (one.hasOwnProperty('member')) {
	    payload.member = one.member.number;
	}
	return _sale.save({operation:"payment"}, payload).$promise
    };

    this.sale_detail = function(shopIds, currentPage, itemsPerpage){
	return _sale.save(
	    {operation: "list_sale_info"},
	    {shop: shopIds,
	     page:  currentPage,
	     count: itemsPerpage})
    };

    this.filter_sale = function(pattern, fields, currentPage, countPerPage){
	return _sale.save(
	    {operation: "filter_sale_info"},
	    {pattern: pattern.op,
	     fields:  fields,
	     page:    currentPage,
	     count:   countPerPage})
    };

    this.sale_detail_with_running = function(payload){
	return _sale.sale_info(
	    {operation: "list_sale_info_with_running"},
	    {running_no: payload.runningNo,
	     shops:      payload.shops}
	)
    };

    this.reject_and_exchange = function(inv){
	var payload = {running_no  :inv.running_no,
		       sn          :inv.sn,
		       style_number:inv.style_number,
		       employ      :inv.director.number,
		       shop        :inv.shop,
		       amount      :inv.reject_amount};

	if (inv.member !== "null"){
	    Payload.member = inv.member;
	};
	
	return _sale.sale_reject(
	    {operation   :"reject_and_exchange"}, payload)
    };

    this.reject_detail = function(ShopIds){
	return _sale.sale_info(
	    {operation: "list_reject_info"},
	    {shops: ShopIds})
    };

});


saleApp.controller("saleResponseCtrl", function($scope, $modalInstance, message){
    // console.log($scope);
    // console.log(message);
    
    $scope.success = message.success;
    $scope.title = message.title;
    $scope.body  = message.body;
    
    $scope.cancel = function(){
	$modalInstance.dismiss('cancel');
	// console.log($modalInstance);
	$scope.$parent.reset_sale();
    };

    $scope.print = function() {
	$scope.$parent.print();
	$modalInstance.dismiss('ok_print');
    };
});

saleApp.controller(
    "cashierCtrl",
    function($scope, $routeParams, $modal, saleService, inventoryService,
	     employService, memberService, user){

	console.log(user);

	// shop to allowed to sale
	$scope.allowedShops = rightAction.get_allowed_sale_shops(user.shop);
	// console.log($scope.allowedShops);	

	// for print
	$scope.current_time = function(){
	    return $.now();
	};
	
	$scope.print = function(){
	    // console.log("print");
	    // $scope.current_time = $.now();
	    javascript:window.print();

	    $scope.reset_sale();
	};
	//console.log($scope.current_time);
	
	$scope.form = {};
	
	$scope.inventories = [];
	$scope.buy_inventories = {invs:[]};
	
	// size
	// $scope.sizes = saleService.size();

	// inventories of calculate
	$scope.no_inventories = false;

	// to record a sale
	$scope.payment = {};
	$scope.payment.balance =
	    angular.isDefined($routeParams.pay) ? $routeParams.pay : 0;
	$scope.payment.total_price = 0;
	$scope.payment.left_balance = 0;
	$scope.payment.inventories = [];

	console.log($scope.payment);
	
	// member select style, mobile/name/number
	$scope.memberStyle = saleService.member_style();
	$scope.payment.memberSelectedType = $scope.memberStyle[0];
	
	// payment style, cash/card
	$scope.paymentStyle = saleService.payment_style();
	$scope.payment.payment_type = $scope.paymentStyle[0];

	// buy info
	$scope.show_buy_info = false;

	// get all style number of default selected shop first
	if ($scope.allowedShops.length !== 0){
	    $scope.selectedShop = $scope.allowedShops[0];
	    inventoryService.get_style_numbers_of_shop($scope.selectedShop.shop_id)
		.then(function(numbers){
		    // console.log(numbers);
		    $scope.style_numbers = numbers;
		});
	};
	
	// when shop selected changed, style number changed too
	$scope.$watch("selectedShop", function(newShop, oldShop){
	    // reset style number
	    $scope.clearSelected();
	    if (angular.isDefined(newShop) && angular.isDefined(oldShop)){
		if (newShop.shop_id === oldShop.shop_id){
		    return;
		}
		inventoryService.get_style_numbers_of_shop(newShop.shop_id)
		    .then(function(numbers){
			console.log(numbers);
			$scope.style_numbers = numbers;
		    });
	    }
	});

	// employs
	employService.list().$promise.then(function(employees){
	    // console.log(employees);
            $scope.employees = employees;
	    $scope.payment.direction = $scope.employees[0];
	});

	// member
	memberService.list().$promise.then(function(members){
	    // console.log(members);
	    $scope.members = members;
	});

	// inventoyies by selected style number
	$scope.onSelect = function(item, model, label){
	    $scope.show_buy_info = false;
	    //saleService.get_inventory($scope.selectedStyleNumber)
	    inventoryService.list_by_style_number_and_shop(
		$scope.selectedStyleNumber, $scope.selectedShop.shop_id)
		.then(function(invs){
		    // console.log(invs);
		    // add attr buy_amount and select_range,
		    // to convenient to show
		    angular.forEach(invs, function(item){
			item.buy_amount = 1;
			if (item.amount > 0){
			    item.select_range = diablo_range(item.amount);
			} else{
			    item.select_range = [];
			}
		    })

		    // use deep copy
		    // $scope.inventories = $scope.inventories.concat(angular.copy(invs))
		    $scope.inventories = angular.copy(invs);
		    console.log($scope.inventories);
		});
	}

	// clear the style number convenient to next input
	$scope.clearSelected = function(){
	    //console.log($scope.selectedStyleNumber)
	    $scope.selectedStyleNumber = "";
	}	

	// callback for data checkboxes, when check box changed,
	// this function was called
	$scope.change_selected =  function(){
	    var total_price = 0;
	    angular.forEach($scope.buy_inventories.invs, function(inv){
		total_price
		    += inv.plan_price * inv.discount * inv.buy_amount / 100;
	    });

	    $scope.payment.total_price = Math.round(total_price);

	    // consider transfer inventory
	    $scope.payment.balance =
		angular.isDefined($routeParams.pay) ? $routeParams.pay : 0;
	    // if (angular.isDefined($scope.payment.balance)){
	    // 	$scope.payment.left_balance =
	    // 	    $scope.payment.balance - $scope.payment.total_price;
	    // }
	};

	// left balance changed real time
	$scope.$watch("payment.balance", function(){
	    $scope.payment.left_balance =
		$scope.payment.balance - $scope.payment.total_price;
	});

	$scope.disable_calculate = function(){
	    if ($scope.payment.left_balance < 0
		|| $scope.buy_inventories.invs.length < 1){
		return true;
	    }

	    return false;
	}

	$scope.show_dialog = function(result, title, body){
	    $modal.open({
		templateUrl: 'saleResponse.html',
		controller: 'saleResponseCtrl',
		backdrop: 'static',
		backdropClass: 'hidden-print',
		windowClass: 'hidden-print',
		keyboard: false,
		scope: $scope,
		resolve:{
		    message: function(){
			return {
			    success: result,
			    title: title,
			    body: body
			}
		    }
		}
	    })
	};

	$scope.reset_sale = function(){
	    $scope.inventories = [];
	    $scope.buy_inventories.invs = [];
	    // salve last record
	    // $scope.payment.balance = 0;
	    // $scope.payment.total_price = 0;
	    // $scope.payment.left_balance = 0;
	    $scope.payment.inventories = [];
	}
	
	$scope.calculate = function(balance){
	    console.log($scope.buy_inventories);
	    // no selected inventory
	    if ($scope.buy_inventories.invs.length < 1){
		$scope.no_inventories = true;
		$scope.paymentResponse = function(){
		    $scope.response_error_info = saleService.error[1799];
		    return false;
		}
		
	    	return;
	    }

	    // add shop
	    $scope.payment.shop = $scope.selectedShop.shop_id;
	    
	    // add all saled inventory
	    $scope.payment.inventories = [];
	    angular.forEach($scope.buy_inventories.invs, function(inv){
		$scope.payment.inventories.push(
		    {inventory    :inv.sn,
		     style_number :inv.style_number,
		     buy_amount   :inv.buy_amount});
	    });

	    
	    if ($scope.payment.left_balance < 0){
		$scope.paymentResponse = function(){
		    $scope.response_error_info = saleService.error[1781];
		    return false;
		}
		return
	    }
	    
	    console.log($scope.payment);

	    // $scope.show_dialog(
	    // 	true, "结算成功", "恭喜你，营业员"
	    // 	    + $scope.payment.direction.name + "结算成功");
	    // return;
	    
	    saleService.payment($scope.payment).then(function(state){
	    	console.log(state);
	    	if (state.ecode == 0){
		    $scope.running_no = state.running_no;
		    $scope.show_dialog(
			true, "结算成功", "恭喜你，营业员"
	    		    + $scope.payment.direction.name + "结算成功");
		    // clear last sale inventories, buy information
	    	    // $scope.inventories = [];
		    // $scope.buy_inventories.invs = [];
		    // $scope.payment.balance = 0;
	    	    // $scope.show_buy_info = true;
	    	} else{
		    $scope.show_dialog(false, "结算失败",
				       saleService.error[state.ecode]);
		}
	    })
	};	
    });

saleApp.controller(
    "rejectExchangeCtrl",
    function($scope, $location, saleService, diabloUtilsService, employService, user){
	// console.log(user);
	// shop to allowed to sale

	$scope.season = diablo_season;
	$scope.sex    = diablo_sex;
	$scope.form   = {};
	$scope.reject = {};
	
	// var allowedShops = rightAction.get_allowed_sale_shops(user.shop);
	// get employees
	employService.list().$promise.then(function(employees){
	    // console.log(employees);
            $scope.employees = employees;
	});

	$scope.get_inventory = function(){
	    console.log($scope.inventory);
	    if ($scope.form.runningForm.$invalid){
		return;
	    }

	    var shopIds = [];
	    angular.forEach(user.shop, function(shop){
		if (!in_array(shopIds, shop.shop_id)){
		    shopIds.push(shop.shop_id);
		};
		return shopIds;
	    });
	    
	    saleService.sale_detail_with_running(
		{runningNo: $scope.inventory.runningNo,
		 shops:     shopIds}
	    ).$promise.then(function(data){
		    console.log(data);
		    $scope.inventories = data;
		    var inc = 1;
		    angular.forEach($scope.inventories, function(inv){
			inv.sale_price = Math.round(inv.plan_price * inv.discount / 100);
			inv.reject_amount = 1;
			inv.select_range = diablo_range(inv.amount);
			inv.director = $scope.employees[0];
			inv.year = inv.year.slice(0, 4);
			inv.order_id = inc;
			inc++;
		    })
		})
	};

	$scope.exchange = function(inv){
	    var callback = function(price){
		$location.url("/cashier/" +price.toString())
	    };
	    diabloUtilsService.request(
		"换货", "换货前请确保该商品已退货！！！",
	    callback, inv.sale_price, $scope);
	};

	$scope.rejectEx = function(inv){
	    diabloUtilsService.request("退货", "确定要退货吗？", $scope.callback_ok, inv, $scope);
	};

	$scope.callback_ok = function(inv){
	    console.log(inv);
	    saleService.reject_and_exchange(inv).$promise.then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    diabloUtilsService.response(
			true, "退货", "退贷成功", $scope);
		} else{
		    diabloUtilsService.response(
			false, "退货", "退货失败", saleService.error[state.ecode])
		}
	    });
	}
	
    });


saleApp.controller(
    "rejectDetailCtrl",
    function($scope, $routeParams, ngTableUtils, saleService, user){
	// console.log(user);
	// shop to allowed to sale

	$scope.season = diablo_season;
	$scope.sex    = diablo_sex;
	
	// var ShopIds = [];
	// var allowedShops = rightAction.get_allowed_sale_shops(user.shop);
	// angular.forEach(allowedShops, function(shop){
	//     ShopIds.push(shop.shop_id);
	// });

	// filters segment
	$scope.filters = {sn: '', style_number: ''};
	
	saleService.reject_detail(parseInt($routeParams.shopId)).$promise.then(function(data){
	    //console.log(data);
	    $scope.details = data;
	    var inc = 1;
	    angular.forEach($scope.details, function(reject){
		reject.year = reject.year.slice(0, 4);
		reject.order_id = inc;
		inc++;
	    });
	    
	    $scope.saleTable =
		ngTableUtils.tbl_of_filter_and_sort(
		    $scope.details, $scope.filters, {id: 'asc'});
	})
    });

saleApp.controller("saleCtrl", function($scope){
	
    
});





