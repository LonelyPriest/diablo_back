wprintApp.controller("printerConnectNewCtrl", function(
    $scope, diabloPattern, wprintService, merchantService, diabloUtilsService){

    $scope.paper_columns = wprintService.paper_columns;
    $scope.paper_heights = wprintService.paper_heights;
    
    $scope.printer = {
	column: $scope.paper_columns[0],
	height: $scope.paper_heights[0]
    }; 

    // printer
    wprintService.list_wprinter().then(function(printers){
	console.log(printers);
	$scope.brands = printers.map(function(p){
	    return {id      :p.id,
		    brand   :p.brand,
		    model   :p.model,
		    column  :p.col_width,
		    remark  :wprintService.get_chinese_brand(p.brand) + "，" + p.model}
	});
	
	if ($scope.brands.length !== 0){
	    $scope.printer.brand = $scope.brands[0];
	}
    });
    
    // server
    wprintService.list_wprint_server().then(function(servers){
	console.log(servers);
	$scope.servers = servers.map(function(s){
	    return {id: s.id, name:s.name}
	});
	
	if ($scope.servers.length !== 0){
	    $scope.printer.server = $scope.servers[0]
	};
    }); 

    // merchant
    $scope.merchants = []; 
    merchantService.list_w_merchant().then(function(merchants){
    	console.log(merchants);
	angular.forEach(merchants, function(m){
	    $scope.merchants.push({id:m.id, name:m.name, py:diablo_pinyin(m.name)});
	})
    });

    $scope.shops = [];
    $scope.on_select_merchant = function(item, model, label){
	console.log(model);
	wprintService.list_shop_by_merchant(model.id).then(function(shops){
	    console.log(shops)
	    angular.forEach(shops, function(s){
		$scope.shops.push({id:s.id, name:s.name, py:diablo_pinyin(s.name)});
	    })
	    
	    if ($scope.shops.length !== 0){
		$scope.printer.shop = $scope.shops[0];
	    }
	});
    };

    $scope.new_printer = function(){
	console.log($scope.printer);
	wprintService.new_wprinter_conn($scope.printer).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		diabloUtilsService.response_with_callback(
	    	    true, "打印机关联",
		    "打印机 " + $scope.printer.sn + " 关联成功！！",
	    	    $scope,
		    function(){diablo_goto_page("#/print/detail");});
	    } else{
		diabloUtilsService.response(
	    	    false, "打印机关联",
	    	    "打印机关联失败：" + wprintService.error[state.ecode]);
	    };
	})
    };

    $scope.cancel = function(){
	diablo_goto_page("#/print/connect_detail");
    }
    
    
});


wprintApp.controller("printerConnectDetailCtrl", function(
    $scope, $q, $location, wprintService, diabloPromise, diabloUtilsService){

    $scope.goto_page = diablo_goto_page;
    var dialog = diabloUtilsService;

    $scope.refresh = function(){
	wprintService.list_wprinter_conn().then(function(printers){
	    console.log(printers); 
	    $scope.printers = printers;
	    angular.forEach($scope.printers, function(p){
		p.brand_chinese = wprintService.get_chinese_brand(p.brand)
	    });
	    diablo_order($scope.printers);
	});
    };
    

    $scope.refresh();

    $scope.test_printer = function(p){
	console.log(p);
	wprintService.test_printer(p).then(function(result){
	    console.log(result);
	    if (result.ecode === 0){
		dialog.response(
		    true, "打印机测试", "打印机测试成功，请等待打印！！", $scope);
	    } else{
		var error = "";
		angular.forEach(result.einfo, function(e){
		    error += "[" + e.device + "] " + wprintService.error[e.ecode]
		});
		
		dialog.response(
		    false, "打印机测试", "打印机测试失败：" + error, $scope);
	    }
	})
    };

    var get_object = function(id, objs){
	for (var i=0, l=objs.length; i<l; i++){
	    if (id === objs[i].id){
		return objs[i];
	    }
	}
    };
    
    $scope.update_printer = function(p){
	var has_update = function(new_printer){
	    if (new_printer.server.id     === p.server_id
		&& new_printer.brand.id   === p.printer_id
		&& new_printer.shop.id    === p.shop_id
		&& new_printer.column     === p.pcolumn
		&& new_printer.height     === p.pheight
		&& new_printer.sn         === p.sn
		&& new_printer.key        === p.code){
		return false;
	    }

	    return true;
	};
	
	var promise = diabloPromise.promise;
	$q.all([
	    promise(wprintService.list_wprint_server)(),
	    promise(wprintService.list_wprinter)(),
	    promise(wprintService.list_shop_by_merchant, p.merchant_id)()
	]).then(function(result){
	    console.log(result);
	    // result[0] are the servers
	    // result[1] are the printers
	    // result[2] are the shops
	    var servers = result[0].map(function(s){
		return {id:s.id, name:s.name, path:s.path};
	    });

	    var brands = result[1].map(function(p){
		return {id      :p.id,
			brand   :p.brand,
			model   :p.model,
			column  :p.col_width,
			remark  :wprintService.get_chinese_brand(p.brand) + "，" + p.model
		       }
	    });
	    
	    var shops = result[2].map(function(s){
		return {id:s.id, name:s.name, py:diablo_pinyin(s.name)};
	    });
	    
	    var printer = {
		// servers: servers,
		// brands : brands,
		// shops:   shops, 
		server:  get_object(p.server_id, servers),
		brand:   get_object(p.printer_id, brands), 
		shop:    get_object(p.shop_id, shops),
		column:  p.pcolumn,
		height:  p.pheight,
		sn:      p.sn,
		key:     p.code, 
	    };

	    var callback = function(params){
	        console.log(params);

		var update = {id: p.id};
		for (var o in params.printer){
		    if (!angular.equals(params.printer[o], printer[o])){
			update[o] = params.printer[o];
		    }
		}

		console.log(update);

		wprintService.update_wprinter_conn(update).then(function(result){
		    console.log(result);
		    if (result.ecode == 0){
			dialog.response_with_callback(
			    true, "打印机编辑", "打印机关联信息修改成功！！",
			    $scope, function(){$scope.refresh()});
    		    } else{
			dialog.response(
			    false, "打印机编辑",
			    "打印机关联信息编辑失败：" + wprintService.error[result.ecode]);
    		    }
		})
	    };
	    
	    dialog.edit_with_modal(
	        "update-printer.html", undefined, callback, $scope,
		{has_update: has_update,
		 paper_columns: wprintService.paper_columns,
		 paper_heights: wprintService.paper_heights,
		 servers: servers,
		 brands:  brands,
		 shops:   shops,
		 printer: printer});
	}) 
	
    };

    $scope.delete_printer = function(printer){
	var callback = function(){
	    wprintService.delete_wprinter_conn(printer.id).then(function(result){
		console.log(result);
		if (result.ecode == 0){
		    dialog.response_with_callback(
			true, "删除关联", "打印机 [" + printer.sn + "] 关联信息成功删除！！",
			$scope, function(){$scope.refresh()})
		} else{
		    dialog.response(
			false, "删除关联",
			"删除打印机关联信息失败：" + wprintService.error[result.ecode], $scope);
		}
	    })
	};
	
	dialog.request(
	    "删除打印机关联信息", "确定要删除该打印机关联信息吗？", callback, undefined, $scope);
    }
});
