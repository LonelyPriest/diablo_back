wsaleApp.controller('wsalePrintPreviewCtrl', function(
    $scope, $routeParams, filterSizeGroup, wsaleService){

    $scope.p = {};
    $scope.pbase  = {};

    var rsn = $routeParams.rsn;

    var print_field = function() {
	for(var i=0,l=$scope.p_format.length; i<l; i++){
	    var is = $scope.p_format[i].print;
	    var name = $scope.p_format[i].name;
	    $scope.p[name] = is === 1 ? true:false;
	}
    };

    var print_base = function(){
	var pstyle;
	var pphones = [];
	var pcommnets = [];
	for(var i=0,l=$scope.p_setting.length; i<l; i++){
	    var k = $scope.p_setting[i].ename;
	    var v = $scope.p_setting[i].value;
	    
	    if (k === "pformat"){
		pstyle = parseInt(v);
	    } else if(k === "phone1" && v) {
		pphones.push(v);
	    } else if(k === "phone2" && v) {
		pphones.push(v);
	    }  else if(k === "comment1" && v) {
		pcommnets.push(v);
	    } else if(k === "comment2" && v) {
		pcommnets.push(v);
	    } else if(k === "comment3" && v) {
		pcommnets.push(v);
	    }  
	};

	$scope.pbase.pstyle    = pstyle;
	$scope.pbase.pphones   = pphones;
	$scope.pbase.pcommnets = pcommnets;
    };

    wsaleService.get_w_print_content(rsn).then(function(e){
        console.log(e);
        if (e.ecode === 0){
    	    // print info
    	    $scope.p_banks         = e.banks; 
    	    $scope.p_merchant      = e.merchant;
    	    $scope.p_format        = e.pformat;
    	    $scope.p_setting       = e.psetting;
    	    $scope.p_shop          = e.shop.length !== 0 ? e.shop[0]:undefined;
	    $scope.p_sale          = e.sale;
	    $scope.p_detail        = e.detail;

	    // $scope.p.p_style_number = is_print("style_number");
	    // $scope.p.p_brand        = is_print("brand");
	    // $scope.p.p_type         = is_print("type");
	    // $scope.p.p_color        = is_print("color");
	    // $scope.p.p_sgroup_name  = is_print("size_name");
	    // $scope.p.p_size         = is_print("size");
	    // $scope.p.p_price        = is_print("price");
	    print_field();
	    print_base();
	    
	    console.log($scope.p);
	    console.log($scope.pbase);

    	    // javascript:window.print();
        }
    })
});
