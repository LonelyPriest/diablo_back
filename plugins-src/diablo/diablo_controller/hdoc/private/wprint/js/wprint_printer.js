wprintApp.controller("printerNewCtrl", function(
    $scope, diabloPattern, wprintService, diabloUtilsService){
    $scope.pattern = {brand: diabloPattern.chinese,
		      model: diabloPattern.char_number_slash_bar};
    
    // $scope.paper_columns = wprintService.paper_columns;
    $scope.brands = wprintService.printer_brands;

    var dialog = diabloUtilsService;
    $scope.new_printer = function(){
	console.log($scope.printer);

	wprintService.new_wprinter($scope.printer).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		dialog.response_with_callback(
	    	    true, "新增打印机",
		    "打印机 " + $scope.printer.brand.chinese + " 成功增加！！",
	    	    $scope,
		    function(){diablo_goto_page("#/printer/detail")});
	    } else{
		dialog.response(
	    	    false, "新增打印机",
	    	    "新增打印机失败：" + wprintService.error[state.ecode]);
	    };
	})
    }

    $scope.cancel = function(){
	diablo_goto_page("#/printer/detail")
    };
    
});

wprintApp.controller("printerDetailCtrl", function(
    $scope, diabloPattern, wprintService, diabloUtilsService){
    
    $scope.refresh = function(){
	wprintService.list_wprinter().then(function(printers){
	    console.log(printers);
	    $scope.printers = printers;
	    angular.forEach($scope.printers, function(p){
		p.brand_chinese = wprintService.get_chinese_brand(p.brand)
	    });
	    diablo_order($scope.printers);
	})
    };
    
    $scope.refresh(); 

    $scope.goto_page = diablo_goto_page;

    var dialog = diabloUtilsService;
    $scope.update_printer = function(){
	dialog.response(false, "打印机编辑", "暂不支持此操作！！")
    };

    $scope.delete_printer = function(){
	dialog.response(false, "打印机编辑", "暂不支持此操作！！")
    };
});

wprintApp.controller("wprintCtrl", function($scope){
    
});
