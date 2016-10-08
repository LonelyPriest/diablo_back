wgoodApp.controller("wgoodUpdateCtrl", function(
    $scope, $location, $routeParams, $q, $timeout, diabloPattern,
    diabloUtilsService, diabloPromise, diabloFilter, wgoodService,
    filterBrand, filterFirm, filterType, filterColor, filterSizeGroup,
    filterColorType, user, base){
    // console.log(filterSizeGroup);
    // console.log(filterType);
    console.log(filterBrand);
    $scope.seasons    = diablo_season2objects;
    $scope.sexs       = diablo_sex2object;
    $scope.full_years = diablo_full_year;

    $scope.pattern = {style_number: diabloPattern.style_number,
		      brand: diabloPattern.ch_en_num,
		      type:  diabloPattern.head_ch_en_num}; 
    //
    $scope.base_setting = {};
    $scope.base_setting.hidden_p3_5 = function(){
	return diablo_base_setting(
	    "h_price3_5", -1, base, parseInt, diablo_no); 
    }();

    $scope.base_setting.show_discount = function(){
	return diablo_base_setting(
	    "show_discount", -1, base, parseInt, diablo_yes);
    }();

    $scope.shops  = user.sortShops;
    $scope.firms  = filterFirm;
    $scope.types  = filterType;
    $scope.brands = filterBrand;
    $scope.groups = filterSizeGroup;
    console.log($scope.groups);
    $scope.filterColors = angular.copy(filterColor);
    $scope.colorTypes = filterColorType;

    $scope.colors = [];

    // [{type:"红色", tid:1
    // 	    colors:[{name:"深红", id:1},
    // 		    {name:"粉红", id:2}]},
    //  {type:"蓝色", tid:2
    //      colors:[{name:"深蓝", id:3},
    // 	            {name:"浅蓝", id:4}]}, 
    // ]; 
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

    // colors
    angular.forEach($scope.filterColors, function(color){
	if (!in_sys_color($scope.colors, color)){
	    $scope.colors.push(
		{type:color.type, tid:color.tid,
		 colors:[{name:color.name, id:color.id}]})
	}
    });

    
    var dialog = diabloUtilsService;
    var promise = diabloPromise.promise;

    // console.log($scope.types);
    // console.log($scope.firms);
    wgoodService.get_purchaser_good_by_id($routeParams.id).then(function(good){
	console.log(good); 
	// reset
	var get_by_id = diablo_get_object;

	$scope.src_good = angular.copy(good);
	$scope.src_good.brand =
	    get_by_id($scope.src_good.brand_id, $scope.brands).name;
	$scope.src_good.type  = get_by_id(good.type_id, $scope.types).name;
	
	$scope.good = angular.copy(good);
	$scope.good.brand =
	    get_by_id($scope.good.brand_id, $scope.brands).name;
	
	// $scope.o_brand        = $scope.good.brand;
	// $scope.o_style_number = $scope.good.style_number;
	
	$scope.good.type  = get_by_id(good.type_id, $scope.types);
	$scope.good.firm  = get_by_id(good.firm_id, $scope.firms);
	$scope.good.sex   = get_by_id(good.sex, $scope.sexs);
	$scope.good.season= get_by_id(good.season, $scope.seasons);
	$scope.good.shop  = $scope.shops[0];

	// // image
	// $scope.image = {}; 
	// // $scope.org_image.image = new Image();
	// $scope.image.path = $scope.good.path;

	// get selected color
	$scope.selectColors = []; 
	$scope.good.color_desc="";
	
	angular.forEach($scope.colors, function(colorInfo){
	    angular.forEach(colorInfo.colors, function(color){
		var selectColorIds = $scope.good.color.split(",");
		for(var i=0, l=selectColorIds.length; i<l; i++){
		    if (color.id === parseInt(selectColorIds[i])){
			$scope.good.color_desc += color.name + "；";
			color.select = true;
			color.disabled = true;
			$scope.selectColors.push(angular.copy(color));
		    } 
		}
	    })
	});

	if ($scope.selectColors.length === 0){
	    $scope.good.color_desc = "均色";
	}

	var select_groups = $scope.good.s_group.split(",").map(function(s){
	    return parseInt(s);
	})
	
	// console.log(select_groups);
	$scope.selectGroups = angular.copy($scope.groups);
	angular.forEach($scope.selectGroups, function(g){
	    if (in_array(select_groups, g.id)){
		g.select = true;
		g.disabled = true;
	    }
	});
	// $scope.selectGroups = $scope.good.s_group.split(",");
	// console.log($scope.selectColors);
	// console.log($scope.good);

	$scope.disable_select_size = function(){
	    // console.log(good);
	    // var select_groups = good.s_group.split(",");
	    return $scope.good.free === 0 || select_groups.length >= 2;
	}
    });
    

    $scope.is_same_good = false;
    
    var get_brand = function(brand_name){
	for (var i=0, l=$scope.brands.length; i<l; i++){
	    if (brand_name === $scope.brands[i].name){
		return $scope.brands[i];
	    }
	}

	return undefined;
    };
    
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
	   || angular.equals(newValue, oldValue)
	   || angular.equals(newValue, $scope.src_good.style_number)){
	    return;
	};

	$timeout.cancel(timeout_sytle_number);
	timeout_sytle_number = $timeout(function(){
	    // console.log(newValue, oldValue);
	    check_same_good(newValue, $scope.good.brand);
	}, diablo_delay)
    });


    var timeout_brand = undefined;
    $scope.$watch("good.brand", function(newValue, oldValue){
	if(angular.isUndefined(newValue)
	   || angular.equals(newValue, oldValue)
	   || angular.equals(newValue, $scope.src_good.brand)){
	    return;
	}

	$timeout.cancel(timeout_brand);
	timeout_brand = $timeout(function(){
	    // console.log(newValue, oldValue); 
	    check_same_good($scope.good.style_number, newValue);
	}, diablo_delay) 
    });

    $scope.delete_image = function(){
	$scope.image = undefined;
    };
    
    $scope.new_firm = function(){
	var callback = function(params){
	    console.log(params);

	    wgoodService.new_firm(params.firm).then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    dialog.response_with_callback(
			true, "新增厂家",
			"恭喜你，厂家 " + params.firm.name + " 成功创建！！",
			$scope,
			function(){
			    // $scope.refresh_firm(params.firm.name)
			    var newFirm = {
				id:state.id,
				name:params.firm.name,
				py:diablo_pinyin(params.firm.name),
				balance:params.firm.balance
			    }; 
			    $scope.firms.push(newFirm);
			    $scope.good.firm = newFirm;
			});
		} else{
		    dialog.response(
	    		false, "新增厂家",
	    		"新增厂家失败：" + firmService.error[state.ecode]);
		};
	    })
	    
	};

	dialog.edit_with_modal(
	    "new-firm.html", undefined, callback, $scope, {firm:{}});
    } 

    $scope.$watch("good.brand", function(newValue, oldValue){
	if(angular.isUndefined(newValue)){
	    return;
	}
	
	var re = diabloPattern.ch_en_num;
	if (!re.test(typeof(newValue) === "object" ? newValue.name : newValue)){
	    $scope.goodForm.brand.$invalid = true;
	} else{
	    $scope.goodForm.brand.$invalid = false;
	}
	
    });

    $scope.$watch("good.type", function(newValue, oldValue){
    	if(angular.isUndefined(newValue)){
    	    return;
    	}
	
    	var re = $scope.pattern.type;
    	if (!re.test(typeof(newValue) === "object" ? newValue.name : newValue)){
    	    $scope.goodForm.type.$invalid = true;
    	}else{
    	    $scope.goodForm.type.$invalid = false;
    	}
	
    }); 

    // wgoodService.list_color_type().then(function(data){
    // 	// console.log(data);
    // 	$scope.colorTypes = data;
    // }); 
    
    $scope.new_color = function(){
	var callback = function(params){
	    console.log(params.color);
	    var color = {name:   params.color.name,
			 type:   params.color.type.id,
			 remark: params.color.remark};
	    wgoodService.add_purchaser_color(color).then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    var append_color = function(newColorId){
			var newColor = {
			    id:      newColorId,
			    name:    params.color.name,
			    tid:     params.color.type.id,
			    type:    params.color.type.name};
			
			if (!in_sys_color($scope.colors, newColor)){
			    $scope.colors.push(
				{type: newColor.type,
				 tid:  newColor.tid,
				 colors:[{name:newColor.name, id:newColor.id}]})
			}

			diabloFilter.reset_color($scope.filterColors.push(newColor));
			console.log($scope.colors); 
		    };
		    
		    dialog.response_with_callback(
			true, "新增颜色", "新增颜色成功！！", $scope,
			function(){append_color(state.id)});
		} else{
		    dialog.response(
			false, "新增颜色",
			"新增颜色失败：" + wgoodService.error[state.ecode]);
		}
	    })
	};
	
	dialog.edit_with_modal(
	    'new-color.html', undefined, callback,
	    $scope, {color: {types: $scope.colorTypes}})
    }
    

    // $scope.selectColors = []; 
    $scope.select_color = function(){
	var callback = function(params){
	    console.log(params.colors);
	    
	    // $scope.selectColors = []; 
	    // $scope.good.color_desc="";
	    angular.forEach(params.colors, function(colorInfo){
		angular.forEach(colorInfo.colors, function(color){
		    if(angular.isDefined(color.select)
		       && color.select
		       && !color.disabled){
			$scope.good.color_desc += color.name + "；";
			$scope.selectColors.push(angular.copy(color));
		    }
		})
	    }); 
	    console.log($scope.selectColors);

	    // save select info
	    $scope.colors = params.colors; 
	}; 
	
	diabloUtilsService.edit_with_modal(
	    "select-color.html", undefined,
	    callback, $scope, {colors:$scope.colors}, true);
    };

    
    $scope.select_size = function(){
	var callback = function(params){
	    $scope.good.size = "";
	    angular.forEach(params.groups, function(g){
		if (angular.isDefined(g.select) && g.select){
		    $scope.good.size += g.name + "；";
		    // $scope.selectGroups.push(angular.copy(g));
		}
	    });
	    $scope.selectGroups = params.groups; 
	};
	
	var select_group = function(groups, g){
	    for(var i=0, l=groups.length; i<l; i++){
		if (!groups[i].disabled && groups[i].id !== g.id){
		    groups[i].select = false;
		}
	    }
	};

	diabloUtilsService.edit_with_modal(
	    "select-size.html", undefined,
	    callback, $scope, {groups: $scope.selectGroups,
			       select_group: select_group}, true);
    }; 
    
    /*
     * update good
     */
    $scope.update_good = function(){
	console.log($scope.good);
	// console.log($scope.image);
	var good = $scope.good;
	var update_good = {};

	update_good.id           = good.id;
	update_good.shop         = good.shop.id;
	update_good.style_number = good.style_number;
	// update_good.brand_id     = good.brand_id;
	update_good.brand  = typeof(good.barnd)
	    === "object" ? good.brand.name: good.brand;
	update_good.type  = typeof(good.type)
	    === "object" ? good.type.name: good.type;

	update_good.firm_id   = good.firm.id;
	update_good.sex       = good.sex.id;
	update_good.year      = good.year;
	update_good.season    = good.season.id;
	update_good.org_price = parseFloat(good.org_price);
	update_good.tag_price = parseFloat(good.tag_price);
	update_good.pkg_price = parseFloat(good.pkg_price);
	update_good.price3    = parseFloat(good.price3);
	update_good.price4    = parseFloat(good.price4);
	update_good.price5    = parseFloat(good.price5);
	update_good.discount  = parseInt(good.discount);
	update_good.color     = function(){
	    if (angular.isDefined($scope.selectColors)
		&& $scope.selectColors.length > 0){
		var colors = "";
		for (var i=0, l=$scope.selectColors.length - 1; i<l; i++){
		    colors += $scope.selectColors[i].id.toString() + ",";
		} 
		colors += $scope.selectColors[l].id.toString();
		return colors;
	    } else{
		return wgoodService.free_color.toString();;
	    }
	}();
	
	update_good.s_group  = function(){
	    var s_group = $scope.selectGroups.filter(function(g){
		return g.select;
	    }).map(function(g){
		return g.id;
	    });

	    return s_group.length !== 0 ? s_group.toString() : $scope.src_good.s_group;
	}();

	update_good.size = function(){
	    var s_group = $scope.selectGroups.filter(function(g){
		return g.select;
	    });
	    
	    var groups = [];
	    angular.forEach(s_group, function(g){
		for(var i=0, l=diablo_sizegroup.length; i<l; i++){
	    	    var k = diablo_sizegroup[i];
	    	    if(g[k] && !in_array(groups, g[k])) groups.push(g[k]);
		}
	    })

	    return groups.length !== 0 ? groups.toString() : $scope.src_good.size;
	}();
	
	console.log(update_good);
	console.log($scope.src_good);

	// return;

	// get changed
	var changed_good = {};
	for (var o in update_good){
	    // console.log($scope.update_good[o], $scope.src_good[o]);
	    if (!angular.equals(update_good[o], $scope.src_good[o])){
		changed_good[o] = update_good[o];
	    }
	};

	// style number and brand
	// if (angular.isDefined(changed_good.style_number)
	//    && angular.isUndefined(changed_good.brand)){
	//     changed_good.brand = update_good.brand;
	// };

	// if (angular.isDefined(changed_good.brand)
	//     && angular.isUndefined(changed_good.style_number)){
	//     changed_good.style_number = update_good.style_number; 
	// };

	// if (angular.isDefined(changed_good.brand)){
	//     changed_good.firm_id = update_good.firm_id;
	// };
	

	// if (angular.isDefined(changed_good.firm_id)){
	//     changed_good.brand   = update_good.brand; 
	// }

	var image  = angular.isDefined($scope.image) && $scope.image
	    ? $scope.image.dataUrl.replace(/^data:image\/(png|jpg);base64,/, "")
	    : undefined;
	
	// changed_good.brand_id = update_good.brand_id;
	// changed_good.style_number = update_good.style_number;
	
	// console.log(changed_good);
	if (diablo_is_empty(changed_good) && angular.isUndefined(image)){
	    diabloUtilsService.response(
		false, "修改货品",
		"修改货品资料失败：" + wgoodService.error[2099]);
	} else{
	    changed_good.good_id        = update_good.id;
	    changed_good.shop           = update_good.shop;
	    
	    changed_good.o_style_number = $scope.src_good.style_number;
	    changed_good.o_brand        = $scope.src_good.brand_id;
	    changed_good.o_path         = $scope.src_good.path;
	    changed_good.o_firm         = $scope.src_good.firm_id; 

	    changed_good.image          = $scope.src_good.image;
	    wgoodService.update_purchaser_good(
		changed_good, image
	    ).then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    diabloUtilsService.response_with_callback(
			true, "修改货品", "修改货品资料成功！！", $scope,
			function(){
			    diabloFilter.reset_firm();
                            diabloFilter.reset_brand();
                            diabloFilter.reset_type();
			    diablo_goto_page("#/wgood_detail");
			});
		} else{
		    diabloUtilsService.response(
			false, "修改货品",
			"修改货品资料失败：" + wgoodService.error[state.ecode]);
		}
	    });
	}
    };

    $scope.cancel = function(){
	diablo_goto_page("#/wgood_detail");
    }
});
