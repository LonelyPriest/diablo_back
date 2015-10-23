wsaleApp.factory("wsaleGoodService", function(){
    
    var _brands     = [];
    var _firms      = [];
    var _types      = [];
    var _sizeGroups = [];
    var _colors     = [];

    var _shop = -1;

    /*
     * 
     */
    var _employees = [];
    var _retailers = [];
    var _base      = [];
    var _user      = {};
    // var _shops     = [];
    // var _rights    = [];
    
    var service = {};

    service.set_brand = function(brands){
	_brands = brands;
    }; 
    service.get_brand = function(){
	return _brands;
    };


    service.set_firm = function(firms) {
	_firms = firms;
    };
    service.get_firm = function(firms){
	return _firms;
    };


    service.set_type = function(types){
	_types = types;
    };
    service.get_type = function(){
	return _types;
    };


    service.set_size_group = function(gs){
	_sizeGroups = gs;
    };
    service.get_size_group = function(){
	return _sizeGroups;
    };

    service.set_color = function(colors){
	_colors = colors;
    };
    service.get_color = function(){
	return _colors;
    };

    service.set_shop = function(shop){
	_shop = shop;
    };
    service.get_shop = function(){
	return _shop;
    };

    /*
     *
     */ 
    service.set_employee = function(employees){
	_employees = employees;
    };
    service.get_employee = function(){
	return _employees;
    };

    service.set_retailer = function(retailers){
	_retailers = retailers;
    };
    service.get_retailer = function(){
	return _retailers;
    };

    service.set_base = function(base){
	_base = base;
    };
    service.get_base = function(){
	return _base;
    }; 

    service.set_user = function(right, shops){
	_user.right = right;
	
	// shops exclude the shop that bind to the repository,
	// or repository itself
	_user.availableShopIds = function(){
	    var ids   = []; 
	    angular.forEach(shops, function(s){
		if ( ((s.type === 0 && s.repo_id === -1) || s.type === 1)
		     && !in_array(ids, s.shop_id)){
		    ids.push(s.shop_id);
		}
	    })
	    return ids;
	}(),

	// shops, include the shop that bind to the repository but not repository
	_user.shopIds = function(){
	    var ids   = []; 
	    angular.forEach(shops, function(s){
		if (s.type === 0 && !in_array(ids, s.shop_id)){
		    ids.push(s.shop_id);
		}
	    })
	    return ids;
	}(),

	// repository only
	_user.repoIds = function(){
	    var ids   = []; 
	    angular.forEach(shops, function(s){
		if (s.type === 1 && !in_array(ids, s.shop_id)){
		    ids.push(s.shop_id);
		}
	    })
	    return ids;
	}(),

	// shops only, include the shop bind to repository
	_user.sortShops = function(){
	    var sort = []; 
	    angular.forEach(shops, function(s){
		var shop = {id:  s.shop_id,
			    name:s.name,
			    repo:s.repo_id,
			    py:diablo_pinyin(s.name)};
		if (s.type === 0 && !in_array(sort, shop)){
		    sort.push(shop); 
		}
	    })
	    return sort;
	}(),

	// repository only
	_user.sortRepoes = function(){
	    var sort = []; 
	    angular.forEach(shops, function(s){
		var repo = {id:  s.shop_id,
			    name:s.name,
			    repo:s.repo_id,
			    py:diablo_pinyin(s.name)};
		if (s.type === 1 && !in_array(sort, repo)){
		    sort.push(repo); 
		}
	    })
	    return sort;
	}(),

	// shops exclude the shop that bind to the repository,
	// or repository itself
	_user.sortAvailabeShops = function(){
	    var sort = []; 
	    angular.forEach(shops, function(s){
		var repo = {id:  s.shop_id,
			    name:s.name,
			    repo:s.repo_id,
			    py:diablo_pinyin(s.name)};

		if ( ((s.type === 0 && s.repo_id === -1) || s.type === 1)
		     && !in_array(sort, repo)){
		    sort.push(repo); 
		} 
	    })
	    return sort;
	}() 
    };
    
    service.get_user = function(){
	return _user;
    };

    return service;
});

wsaleApp.controller("wsaleGoodNewCtrl", function(
    $scope, $timeout, diabloPattern, diabloUtilsService, diabloFilter,
    wgoodService, wsaleGoodService){

    var dialog        = diabloUtilsService;
    var set_float     = diablo_set_float;
    
    $scope.brands     = wsaleGoodService.get_brand();
    $scope.types      = wsaleGoodService.get_type();
    $scope.firms      = wsaleGoodService.get_firm();
    $scope.groups     = wsaleGoodService.get_size_group();
    // $scope.colors     = wsaleGoodService.get_colors();
    
    $scope.full_years = diablo_full_year;
    $scope.sexs       = diablo_sex2object;
    $scope.seasons    = diablo_season2objects;

    $scope.refresh_brand = function(){
	$scope.brands = wgoodService.list_purchaser_brand().then(function(brands){
	    console.log(brands);
	    return brands.map(function(b){
		return {id: b.id, name:b.name, py:diablo_pinyin(b.name)};
	    })
	});

	wsaleGoodService.set_brand($scope.brands);
    };

    $scope.refresh_type = function(){
	$scope.types = wgoodService.list_purchaser_type().then(function(types){
	    return types.map(function(t){
		return {id: t.id, name:t.name, py:diablo_pinyin(t.name)};
	    })
	});

	wsaleGoodService.set_type($scope.types);
    };

    /*
     * new good
     */
    $scope.good = {
	org_price : 0,
	tag_price : 0,
	pkg_price : 0,
	p3        : 0,
	p4        : 0,
	p5        : 0,
	discount  : 100,
	alarm_day : 7,
	year      : diablo_now_year(),
	season    : $scope.seasons[0]
    };

    var get_brand = function(brand_name){
	for (var i=0, l=$scope.brands.length; i<l; i++){
	    if (brand_name === $scope.brands[i].name){
		return $scope.brands[i];
	    }
	}

	return undefined;
    };


    $scope.is_same_good = false;
    var check_same_good = function(style_number, brand_name){
	// console.log(brand_name);
	var brand = get_brand(brand_name);
	if (angular.isUndefined(brand)
	    || angular.isUndefined(style_number) || !style_number){
	    $scope.is_same_good = false;
	    return false;
	}
	
	wgoodService.get_purchaser_good({
	    style_number:style_number, brand:brand.id
	}).then(function(result){
	    console.log(result);
	    if (angular.isDefined(result.style_number)){
		$scope.is_same_good = true;
		return true;
	    }
	    $scope.is_same_good = false;
	    return false; 
	})
    }

    var timeout_sytle_number = undefined;
    $scope.$watch("good.style_number", function(newValue, oldValue){
	if(angular.isUndefined(newValue)
	   || angular.equals(newValue, oldValue)){
	    return;
	};

	$timeout.cancel(timeout_sytle_number);
	timeout_sytle_number = $timeout(function(){
	    console.log(newValue, oldValue);
	    check_same_good(newValue, $scope.good.brand);
	}, diablo_delay)
    });


    var timeout_brand = undefined;
    $scope.$watch("good.brand", function(newValue, oldValue){
	if(angular.isUndefined(newValue)
	   || angular.equals(newValue, oldValue)){
	    return;
	}

	$timeout.cancel(timeout_brand);
	timeout_brand = $timeout(function(){
	    // console.log(newValue, oldValue); 
	    check_same_good($scope.good.style_number, newValue);
	}, diablo_delay) 
    });


    $scope.new_firm = function(){
	var callback = function(params){
	    console.log(params);

	    // params.firm.balance = set_float(params.firm.balance);
	    wgoodService.new_firm(params.firm).then(function(state){
		console.log(state);

		var append_firm = function(newFirmId){
		    var newFirm = {
			id:      newFirmId,
			name:    params.firm.name,
			py:      diablo_pinyin(params.firm.name),
			balance: 0};
		    
		    $scope.firms.push(newFirm);
		    wsaleGoodService.set_firm($scope.firms);
		    $scope.good.firm = newFirm; 
		};
		
		if (state.ecode == 0){
		    dialog.response_with_callback(
			true, "新增厂家",
			"恭喜你，厂家 " + params.firm.name + " 成功创建！！",
			$scope, function(){append_firm(state.id)});
		} else{
		    dialog.response(
	    		false, "新增厂家",
	    		"新增厂家失败：" + wgoodService.error[state.ecode]);
		};
	    })
	    
	};

	dialog.edit_with_modal(
	    "new-firm.html", undefined, callback, $scope, {firm:{}});
    };

    /*
     * color
     */
    // get all color
    var in_sys_color = function(syscolors, color){
	for(var i=0, l=syscolors.length; i<l; i++){
	    if(syscolors[i].tid === color.tid){
		syscolors[i].colors.push(
		    {name: color.name, id:color.id});
		return true;
	    }
	}

	return false;
    };

    // color
    $scope.colors = [];
    angular.forEach(wsaleGoodService.get_color(), function(color){
	if (!in_sys_color($scope.colors, color)){
	    $scope.colors.push(
		{type:color.type, tid:color.tid,
		 colors:[{name:color.name, id:color.id}]})
	}
    }); 
    console.log($scope.colors);
    
    // $scope.colors = [];
    // wgoodService.list_purchaser_color().then(function(colors){
    // 	console.log(colors); 
    // 	angular.forEach(colors, function(color){
    // 	    if (!in_sys_color($scope.colors, color)){
    // 		$scope.colors.push(
    // 		    {type:color.type, tid:color.tid,
    // 		     colors:[{name:color.name, id:color.id}]})
    // 	    }
    // 	}); 
    // 	console.log($scope.colors);
    // });

    

    wgoodService.list_color_type().then(function(data){
	// console.log(data);
	$scope.colorTypes = data;
    });

    $scope.select_color = function(){
	var callback = function(params){
	    console.log(params.colors);
	    
	    $scope.selectColors = []; 
	    $scope.good.colors="";
	    angular.forEach(params.colors, function(colorInfo){
		angular.forEach(colorInfo.colors, function(color){
		    if(angular.isDefined(color.select) && color.select){
			$scope.good.colors += color.name + "；";
			$scope.selectColors.push(angular.copy(color));
		    }
		})
	    }); 
	    console.log($scope.selectColors);

	    // save select info
	    $scope.colors = angular.copy(params.colors);

	    
	}; 
	
	diabloUtilsService.edit_with_modal(
	    "select-color.html", undefined,
	    callback, $scope, {colors:$scope.colors});
    };


    $scope.select_size = function(){
	var callback = function(params){
	    console.log(params.groups);
	    
	    $scope.selectGroups = [];
	    $scope.good.sizes = "";
	    angular.forEach(params.groups, function(g){
		if (angular.isDefined(g.select) && g.select){
		    $scope.good.sizes += g.name + "；";
		    $scope.selectGroups.push(angular.copy(g));
		}
	    }); 
	    console.log($scope.selectGroups);

	    $scope.groups = params.groups;
	};

	var select_group = function(groups, g){
	    for(var i=0, l=groups.length; i<l; i++){
		if (groups[i].id !== g.id){
		    groups[i].select = false;
		}
	    }
	}

	diabloUtilsService.edit_with_modal(
	    "select-size.html", undefined,
	    callback, $scope, {groups: $scope.groups,
			       select_group: select_group});
    };


    $scope.new_good = function(){
	console.log($scope.good);
	// console.log($scope.image);
	var good = angular.copy($scope.good);
	good.firm           = good.firm.id;
	good.season         = good.season.id;
	good.sex            = good.sex.id;
	good.shop           = wsaleGoodService.get_shop();
	good.zero_inventory = diablo_yes;
	
	good.brand    = typeof(good.brand) === "object" ? good.brand.name: good.brand;
	// good.brand_py = diablo_pinyin(good.brand);
	
	good.type     = typeof(good.type) === "object" ? good.type.name: good.type;
	// good.type_py = diablo_pinyin(good.type);
	
	good.colors   = function(){
	    if (angular.isDefined($scope.selectColors)
		&& $scope.selectColors.length > 0){
		var colors = [];
		angular.forEach($scope.selectColors, function(color){
		    colors.push(color.id)
		});
		return colors;
	    } else{
		return undefined;
	    }
	}();
	
	good.sizes = function(){
	    if (angular.isDefined($scope.selectGroups)
		&& $scope.selectGroups.length > 0){
		var groups = [];
		angular.forEach($scope.selectGroups, function(group){
		    groups.push({id:group.id, group:function(){
			var validSize = [];
			for(var i=0, l=diablo_sizegroup.length; i<l; i++){
	    		    var k = diablo_sizegroup[i];
	    		    if(group[k]){
				validSize.push(group[k]);
			    }
	    		}
			return validSize;
		    }()})
		});
		return groups;
	    } else{
		return undefined;
	    }
	}();
	
	console.log(good);
	// var image  = angular.isDefined($scope.image) && $scope.image
	//     ? $scope.image.dataUrl.replace(/^data:image\/(png|jpg);base64,/, "")
	//     : undefined;
	
	// console.log(image);

	wgoodService.add_purchaser_good(good, undefined).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		dialog.response_with_callback(
		    true, "新增货品", "新增货品资料成功！！", $scope,
		    function(){
			// console.log("callback");
			// reset size 
			$scope.selectGroups = [];
			$scope.good.sizes = "";
			angular.forEach($scope.groups, function(g){
			    if (angular.isDefined(g.select)){
				g.select = false;
			    }
			});

			// reset color
			$scope.selectColors = [];
			$scope.good.colors="";
			console.log($scope.colors);
			angular.forEach($scope.colors, function(colorInfo){
			    angular.forEach(colorInfo, function(color){
				// console.log(color);
				angular.forEach(color, function(c){
				    if (angular.isDefined(c.select)){
					c.select = false;
				    }
				}) 
			    })
			});

			console.log($scope.colors);
			
			$scope.good.style_number = undefined;
			$scope.good.type = undefined;
			$scope.goodForm.type.$pristine = true;
			$scope.goodForm.style_number.$pristine = true;

			/*
			 * add prompt
			 */
			var in_prompts = function(prompts, item){
			    for(var i=0, l=prompts.length; i<l; i++){
				if (prompts[i].name === item){
				    return true;
				}
			    };
			    return false;
			};
			
			// brand
			if (!in_prompts($scope.brands, good.brand)){
		    	    $scope.brands.push({
				// id   :$scope.brands.length + 1,
				id   :state.brand,
				name :good.brand,
				py   :diablo_pinyin(good.brand)});
			    
			    wsaleGoodService.set_brand($scope.brands);
			}; 
			// console.log($scope.brands);

			// type
			if (!in_prompts($scope.types, good.type)){
		    	    $scope.types.push({
				// id   :$scope.types.length + 1,
				id   :state.type,
				name :good.type,
				py   :diablo_pinyin(good.type)});

			    wsaleGoodService.set_type($scope.types);
			};
			// console.log($scope.types);
		    });
	    } else{
		diabloUtilsService.response(
		    false, "新增货品",
		    "新增货品 ["
			+ good.style_number + "-" + good.brand + "-" +  good.type
			+ "] 失败：" + wgoodService.error[state.ecode]);
	    }
	});
    };

    $scope.reset = function(){
	$scope.selectGroups = [];
	$scope.selectColors = [];
	$scope.good = {
	    sex:       $scope.good.sex,
	    year:      $scope.good.year,
	    season:    $scope.good.season,
	    org_price: $scope.good.org_price,
	    tag_price: $scope.good.tag_price,
	    pkg_price: $scope.good.pkg_price,
	    // p3:        $scope.good.p3,
	    // p4:        $scope.good.p4,
	    // p5:        $scope.good.p5,
	    discount:  $scope.good.discount,
	    // alarm_day: $scope.good.alarm_day
	};
	
	$scope.goodForm.style_number.$pristine = true;
	$scope.goodForm.brand.$pristine = true;
	$scope.goodForm.type.$pristine = true;
	$scope.goodForm.firm.$pristine = true;
	// $scope.goodForm.org_price.$pristine = true;
	$scope.goodForm.tag_price.$pristine = true;
	$scope.goodForm.pkg_price.$pristine = true;
	// $scope.goodForm.p3.$pristine = true;
	// $scope.goodForm.p4.$pristine = true;
	// $scope.goodForm.p5.$pristine = true;
	$scope.goodForm.discount.$pristine = true;
	// $scope.goodForm.alarm.$pristine = true;
	// $scope.image = undefined;
    };
})
