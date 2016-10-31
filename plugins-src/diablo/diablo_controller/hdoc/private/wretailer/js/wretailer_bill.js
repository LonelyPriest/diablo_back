// wretailerApp.controller("wretailerBillCheckCtrl", function(
//     $scope, diabloPattern, diabloUtilsService,
//     wretailerService, filterEmployee, user){

var wretailerBillCheckProvide = function(
	$scope, diabloPattern, diabloUtilsService,
	wretailerService, filterEmployee, user){
    // $scope.retailer = {};
    $scope.pattern = {
	decimal_2:    diabloPattern.decimal_2
    };

    $scope.full_years = diablo_full_year; 
    $scope.check_year = diablo_now_year();
    $scope.employees  = filterEmployee;
    $scope.shops      = user.sortShops;
    
    $scope.bill_modes = [{id:0, name:"现金"},
			 {id:1, name:"刷卡"},
			 {id:2, name:"汇款"}];
    
    $scope.employee   = filterEmployee[0];
    $scope.shop       = $scope.shops[0];
    $scope.bill_mode  = $scope.bill_modes[0];

    var dialog = diabloUtilsService;
    
    wretailerService.list_retailer().then(function(retailers){
	$scope.retailers = retailers.map(function(r){
	    return {id:r.id, name:r.name,
		    balance: r.balance,
		    mobile:  r.mobile,
		    address: r.address,
		    prompt:r.name + diablo_pinyin(r.name)}
	});
	// console.log($scope.retailers);
    });

    $scope.check_bill = function(){
	console.log($scope.retailer, $scope.bill, $scope.check_year);

	wretailerService.bill_w_retailer({
	    shop:       $scope.shop.id, 
	    retailer:   $scope.retailer.id,
	    mode:       $scope.bill_mode.id,
	    bill:       $scope.bill,
	    employee:   $scope.employee.id,
	    check_year: $scope.check_year,
	    comment:    $scope.comment
	}).then(function(status){
	    console.log(status);
	    if (status.ecode === 0){
		var left_balance = $scope.retailer.balance - $scope.bill;
		dialog.response_with_callback(
		    true,
		    "用户结帐",
		    "结账成功！！剩余欠款：" +  left_balance.toString(),
		    undefined,
		    function() {
			$scope.retailer.balance = left_balance;
			$scope.retailer = undefined;
			$scope.rForm.name.$pristine = true;
		    });
	    } else {
		dialog.response(
		    false,
		    "用户结账",
		    "结账失败！！" + wretailerService.error[status.ecode]);
	    }
	})
    }; 
};
