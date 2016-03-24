wretailerApp.controller("wretailerBillCheckCtrl", function(
    $scope, diabloPattern, diabloUtilsService,
    wretailerService){
    // $scope.retailer = {};
    $scope.pattern = {
	decimal_2:    diabloPattern.decimal_2
    };

    $scope.full_years = diablo_full_year; 
    $scope.check_year = diablo_now_year();
    
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
	    retailer: $scope.retailer.id,
	    bill:$scope.bill,
	    check_year:$scope.check_year
	}).then(function(status){
	    console.log(status);
	})
    };

    // $scope.select_retailer = function(){
    // 	console.log($scope.retailer);
    // };
    
});
