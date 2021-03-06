// wgoodApp.controller("wgoodNewCtrl", function(
//     $scope, $timeout, diabloPattern, diabloUtilsService, diabloFilter,
//     wgoodService, user, filterBrand, filterFirm, filterType,
//     filterSizeGroup, filterColorType, base){
define(["wgoodApp"], function(app){
    app.controller("wgoodNewCtrl", wgoodNewProvide);
    app.controller("wgoodDetailCtrl", wgoodDetailProvide);
});

var wgoodNewProvide = function(
    $scope, $timeout, diabloPattern, diabloUtilsService, diabloFilter,
    wgoodService, user, filterBrand, filterFirm, filterType,
    filterSizeGroup, filterColorType, base){
    
    
    $scope.seasons = diablo_season2objects;
    $scope.sexs    = diablo_sex2object;
    $scope.pattern = {style_number: diabloPattern.style_number,
		      brand: diabloPattern.ch_en_num,
		      type:  diabloPattern.head_ch_en_num};
    $scope.colorTypes = filterColorType;

    $scope.base_setting = {};

    $scope.base_setting.hidden_p3_5 = function(){
	return diablo_base_setting(
	    "h_price3_5", -1, base, parseInt, diablo_no); 
    }();

    $scope.base_setting.show_discount = function(){
	return diablo_base_setting(
	    "show_discount", -1, base, parseInt, diablo_yes);
    }();

    $scope.base_setting.multi_sgroup = function(){
	return diablo_base_setting(
	    "m_sgroup", -1, base, parseInt, diablo_no);
    }();

    // console.log($scope.base_setting);
    
    $scope.full_years = diablo_full_year;

    var dialog = diabloUtilsService;
    var set_float  = diablo_set_float;

    // $scope.colors = [{type:"红色", tid:1
    // 		  colors:[{name:"深红", id:1},
    // 			  {name:"粉红", id:2}]},
    // 		 {type:"蓝色", tid:2
    // 		  colors:[{name:"深蓝", id:3},
    // 			  {name:"浅蓝", id:4}]}, 
    
    // 		];

    // brands
    $scope.brands = angular.copy(filterBrand);
    // wgoodService.list_purchaser_brand().then(function(brands){
    // 	console.log(brands);
    // 	$scope.brands = [];
    // 	angular.forEach(brands, function(b){
    // 	    $scope.brands.push(
    // 	    	{id:b.id, name:b.name, py:diablo_pinyin(b.name)});
    // 	});
    
    // });
    
    var get_brand = function(brand_name){
	for (var i=0, l=$scope.brands.length; i<l; i++){
	    if (brand_name === $scope.brands[i].name){
		return $scope.brands[i];
	    }
	}

	return undefined;
    };

    $scope.refresh_brand = function(){
	$scope.brands = wgoodService.list_purchaser_brand().then(function(brands){
	    // console.log(brands);
	    return brands.map(function(b){
		return {id: b.id, name:b.name, py:diablo_pinyin(b.name)};
	    }) 
	});
    };

    $scope.price_type = function(){
	return diablo_base_setting(
	    "price_type",
		-1,
	    base,
	    parseInt,
	    diablo_sell_style[0].id);
    }();

    // console.log($scope.price_type);

    // $scope.new_brand = function(){
    // 	var callback = function(params){
    // 	    console.log(params);

    // 	    // params.firm.balance = set_float(params.firm.balance);
    // 	    wgoodService.new_brand(params.brand).then(function(state){
    // 		console.log(state);

    // 		var append_brand = function(bId){
    // 		    var newBrand = {
    // 			id:      bId,
    // 			name:    params.brand.name,
    // 			py:      diablo_pinyin(params.firm.name)};
    
    // 		    $scope.brands.push(newFirm);
    // 		    $scope.good.brand = newBrand; 
    // 		};
    
    // 		if (state.ecode == 0){
    // 		    dialog.response_with_callback(
    // 			true, "新增品牌",
    // 			"恭喜你，品牌 " + params.brand.name + " 成功创建！！",
    // 			$scope, function(){append_firm(state.id)});
    // 		} else{
    // 		    dialog.response(
    // 	    		false, "新增品牌",
    // 	    		"新增品牌失败：" + wgoodService.error[state.ecode]);
    // 		};
    // 	    })
    
    // 	};

    // 	dialog.edit_with_modal(
    // 	    "new-brand.html", undefined, callback, $scope, {brand:{}});
    // }

    // firm
    $scope.firms = angular.copy(filterFirm);

    // year
    // $scope.$watch("good.year", function(newValue, oldValue){
    // 	if(angular.isUndefined(newValue)){
    // 	    $scope.good.year=diablo_now_year()
    // 	}; 
    // })
    // $scope.get_firm_by_name = function(name){
    // 	for(var i=0, l=$scope.firms.length; i<l; i++){
    // 	    if (name === $scope.firms[i].name){
    // 		return $scope.firms[i]
    // 	    }
    // 	}
    // };

    // $scope.refresh_firm = function(newFirmName){
    // 	diabloFilter.get_firm().then(function(firms){
    // 	    $scope.firms = firms;
    // 	    $scope.good.firm = $scope.get_firm_by_name(newFirmName);
    // 	})
    // }; 
    
    $scope.new_firm = function(){
	var callback = function(params){
	    console.log(params);

	    params.firm.balance = set_float(params.firm.balance);
	    wgoodService.new_firm(params.firm).then(function(state){
		console.log(state);

		var append_firm = function(newFirmId){
		    var newFirm = {
			id:      newFirmId,
			name:    params.firm.name,
			py:      diablo_pinyin(params.firm.name),
			balance: params.firm.balance};
		    
		    $scope.firms.push(newFirm);
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
    }

    // type
    $scope.types = angular.copy(filterType);

    $scope.refresh_type = function(){
	$scope.types = wgoodService.list_purchaser_type().then(function(types){
	    return types.map(function(t){
		return {id: t.id, name:t.name, py:diablo_pinyin(t.name)};
	    })
	});
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
	    // console.log(newValue, oldValue);
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

    // $scope.$watch("good.type", function(newValue, oldValue){
    //     if(angular.isUndefined(newValue)){
    // 	return;
    //     }
    
    //     // var re = diabloPattern.head_ch_en_num;
    //     // if (!re.test(typeof(newValue) === "object" ? newValue.name : newValue)){
    //     // 	$scope.goodForm.type.$invalid = true;
    //     // }else{
    //     // 	$scope.goodForm.type.$invalid = false;
    //     // }
    
    // }); 

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
    wgoodService.list_purchaser_color().then(function(colors){
	// console.log(colors); 
	angular.forEach(colors, function(color){
	    if (!in_sys_color($scope.colors, color)){
		$scope.colors.push(
		    {type:color.type, tid:color.tid,
		     colors:[{name:color.name, id:color.id}]})
	    }
	}); 
	// console.log($scope.colors);
    });

    

    // wgoodService.list_color_type().then(function(data){
    // 	// console.log(data);
    // 	$scope.colorTypes = data;
    // });
    
    $scope.new_color = function(){
	var callback = function(params){
	    // console.log(params.color);
	    var color = {name:   params.color.name,
			 type:   params.color.type.id,
			 remark: params.color.remark};
	    wgoodService.add_purchaser_color(color).then(function(state){
		// console.log(state);

		var append_color = function(newColorId){
		    var newColor = {
			id:      newColorId,
			name:    params.color.name,
			tid:     params.color.type.id,
			type:    params.color.type.name, 
			remark:  params.color.remark};
		    
		    if (!in_sys_color($scope.colors, newColor)){
			$scope.colors.push(
			    {type: newColor.type,
			     tid:  newColor.tid,
			     colors:[{name:newColor.name, id:newColor.id}]})
		    } 
		    // console.log($scope.colors); 
		}; 
		
		if (state.ecode == 0){
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
	    // console.log(params.colors);
	    
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
	    // console.log($scope.selectColors);

	    // save select info
	    $scope.colors = angular.copy(params.colors);

	    
	}; 
	
	diabloUtilsService.edit_with_modal(
	    "select-color.html", 'lg',
	    callback, $scope, {colors:$scope.colors}, true);
    }; 

    /*
     * size group
     */
    $scope.groups = angular.copy(filterSizeGroup);

    $scope.new_size = function(){
	var valid_group = function(size){
	    var all_size = [];
	    for (var s in size){
		if (s === 'name') continue;

		if (angular.isDefined(size[s]) && size[s]){
		    // same size in group
		    if (in_array(all_size, size[s])){
			return false;
		    } else{
			all_size.push(size[s]);
		    }
		}
	    }

	    // at lest one size was input 
	    return all_size.length === 0 ? false : true;
	};

	var check_same = function(size, key, value){
	    // console.log(size, key, value);
	    for (var s in size){
		if (s === 'name' || s === key) continue;

		if (angular.isDefined(size[s])
		    && size[s] && size[s] === value){
		    return false;
		}
	    }

	    return true;
	};
	
	var callback = function(params){
	    // console.log(params);
	    var size = {};
	    for (var k in params.size){
		if (angular.isDefined(params.size[k]) && params.size[k]){
		    size[k] = params.size[k]
		}
	    }

	    // console.log(size);

	    wgoodService.add_purchaser_size(size).then(function(state){
	        // console.log(state);
	        if (state.ecode == 0){
		    var append_size_group = function(gid){
			$scope.groups.push(angular.extend({id:gid}, size));
		    }
		    
		    dialog.response_with_callback(
			true, "新增尺码组", "新增尺码组成功！！", $scope,
			function(){append_size_group(state.id)});
    	    	    
	        } else{
	    	    dialog.response(
	    		false, "尺码组", "新增尺码组失败，原因："
	    		    + wgoodService.error[state.ecode]);
	        }
	    })
	};
	
	dialog.edit_with_modal(
	    'new-size.html', undefined, callback, $scope,
	    {size: {}, valid_group: valid_group, check_same: check_same}) 
    };
    
    
    $scope.select_size = function(){
	var callback = function(params){
	    // console.log(params.groups);
	    
	    $scope.selectGroups = [];
	    $scope.good.sizes = "";
	    angular.forEach(params.groups, function(g){
		if (angular.isDefined(g.select) && g.select){
		    $scope.good.sizes += g.name + "；";
		    $scope.selectGroups.push(angular.copy(g));
		}
	    }); 
	    // console.log($scope.selectGroups);

	    $scope.groups = params.groups;
	};

	var select_group = function(groups, g){
	    if (!$scope.base_setting.multi_sgroup){
		for(var i=0, l=groups.length; i<l; i++){

		    if (groups[i].id !== g.id){
			groups[i].select = false;
		    }
		}
	    } 
	};

	diabloUtilsService.edit_with_modal(
	    "select-size.html", undefined,
	    callback, $scope, {groups: $scope.groups,
			       select_group: select_group}, true);
    };

    $scope.delete_image = function(){
	$scope.image = undefined;
    };
    
    
    /*
     * new good
     */
    var current_month = new Date().getMonth(); 
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
	season    : $scope.seasons[diablo_valid_season(current_month)]
    };

    if (user.loginFirm !== -1) {
	$scope.good.firm = diablo_get_object(user.loginFirm, $scope.firms); 
    };

    $scope.new_good = function(){
	// console.log($scope.good);
	// console.log($scope.image);
	var good = angular.copy($scope.good);
	good.firm     = good.firm.id;
	good.season   = good.season.id;
	good.sex      = good.sex.id; 
	
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
	
	// console.log(good);
	var image  = angular.isDefined($scope.image) && $scope.image
	    ? $scope.image.dataUrl.replace(/^data:image\/(png|jpg);base64,/, "")
	    : undefined;
	
	// console.log(image);
	
	wgoodService.add_purchaser_good(good, image).then(function(state){
	    // console.log(state);
	    if (state.ecode == 0){
		dialog.response_with_callback(
		    true, "新增货品", "新增货品资料成功！！", $scope,
		    function(){
			diabloFilter.reset_firm();
                        // diabloFilter.reset_brand();
                        // diabloFilter.reset_type();

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
			// console.log($scope.colors);
			
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

			// console.log($scope.colors);
			
			$scope.good.style_number = undefined;
			// $scope.good.type = undefined;
			// $scope.goodForm.type.$pristine = true;
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
			    diabloFilter.reset_brand($scope.brands);
			}; 
			// console.log($scope.brands);

			// type
			if (!in_prompts($scope.types, good.type)){
		    	    $scope.types.push({
				// id   :$scope.types.length + 1,
				id   :state.type,
				name :good.type,
				py   :diablo_pinyin(good.type)});
			    
			    diabloFilter.reset_type($scope.types);
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
	    // type:      $scope.good.type,
	    sex:       $scope.good.sex,
	    year:      $scope.good.year,
	    season:    $scope.seasons[diablo_valid_season(current_month)],
	    org_price: $scope.good.org_price,
	    tag_price: $scope.good.tag_price,
	    pkg_price: $scope.good.pkg_price,
	    p3:        $scope.good.p3,
	    p4:        $scope.good.p4,
	    p5:        $scope.good.p5,
	    discount:  $scope.good.discount,
	    alarm_day: $scope.good.alarm_day
	};

	if (user.loginFirm !== -1) {
	    $scope.good.firm = diablo_get_object(user.loginFirm, $scope.firms); 
	};
	
	$scope.goodForm.style_number.$pristine = true;
	$scope.goodForm.brand.$pristine = true;
	$scope.goodForm.type.$pristine = true;
	$scope.goodForm.firm.$pristine = true;
	$scope.goodForm.org_price.$pristine = true;
	$scope.goodForm.tag_price.$pristine = true;
	$scope.goodForm.pkg_price.$pristine = true;
	$scope.goodForm.p3.$pristine = true;
	$scope.goodForm.p4.$pristine = true;
	$scope.goodForm.p5.$pristine = true;
	$scope.goodForm.discount.$pristine = true;
	$scope.goodForm.alarm.$pristine = true;
	$scope.image = undefined;
    };
};


// wgoodApp.controller("wgoodDetailCtrl", function(
//     $scope, $location, dateFilter, diabloUtilsService,
//     diabloPagination, wgoodService, user, diabloFilter,
//     filterBrand, filterFirm, filterType, filterColor, base){
var wgoodDetailProvide = function(
    $scope, $location, dateFilter, diabloUtilsService,
    diabloPagination, wgoodService, user, diabloFilter,
    filterBrand, filterFirm, filterType, filterColor, base){
    // console.log(filterNumber);
    // console.log(firms);
    // console.log(filterBrand);
    // console.log(filterType);

    // $scope.show_orgprice = rightAuthen.show_orgprice(user.type);
    $scope.hidden = {
	org_price:rightAuthen.show_orgprice(user.type),
	p3_5:true
    };

    $scope.toggle_price = function(){
	$scope.hidden.p3_5 = !$scope.hidden.p3_5;
    };

    // console.log($scope.hidden);
    
    /*
     * filter
     */ 
    // initial
    $scope.filters = [];
    diabloFilter.reset_field();
    diabloFilter.add_field("style_number", diabloFilter.match_style_number); 
    diabloFilter.add_field("firm", filterFirm);
    diabloFilter.add_field("brand", filterBrand);
    diabloFilter.add_field("type", filterType);

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    var now = $.now();
    $scope.qtime_start = diablo_base_setting(
	"qtime_start", -1, base, diablo_set_date,
	diabloFilter.default_start_time(now));
    
    $scope.time   = diabloFilter.default_time($scope.qtime_start);
    
    // pagination
    $scope.colspan = 15;
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = 10;
    $scope.default_page = 1;

    $scope.do_search = function(page){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    wgoodService.filter_purchaser_good(
		$scope.match, search, page, $scope.items_perpage).then(function(result){
		    console.log(result);
		    if (page === 1){
			$scope.total_items      = result.total;
		    }
		    angular.forEach(result.data, function(d){
			d.firm  = diablo_get_object(d.firm_id, filterFirm);
			d.brand = diablo_get_object(d.brand_id, filterBrand);
			d.type  = diablo_get_object(d.type_id, filterType);
		    })
		    $scope.goods = result.data;
		    diablo_order_page(page, $scope.items_perpage, $scope.goods);
		})
	});
    };
    
    
    // $scope.do_search = function(page){
    // 	console.log($scope.match);
    // 	console.log($scope.filters);

    // 	var search =  diablo_filters($scope.filters);
    
    // 	// console.log($scope.time);
    // 	search.start_time = diablo_filter_time($scope.time.start_time, 0, dateFilter); 
    // 	search.end_time   = diablo_filter_time($scope.time.end_time, 1, dateFilter);
    // 	console.log(search);

    // 	wgoodService.filter_purchaser_good(
    // 	    $scope.match, search, page, $scope.items_perpage).then(function(result){
    // 		console.log(result);
    // 		if (page === 1){
    // 		    $scope.total_items      = result.total;
    // 		}
    // 		$scope.goods = result.data;
    // 		diablo_order_page(page, $scope.items_perpage, $scope.goods);
    // 	    })
    // }; 

    $scope.page_changed = function(){
    	// console.log(page);
    	$scope.do_search($scope.current_page);
    }
    
    $scope.default_page = 1;
    // $scope.do_search($scope.default_page); 
    
    // var match_filed = {
    // 	firm:  "firm_id",
    // 	style_number: "style_number", 
    // 	brand: "brand_id",
    // 	type:  "type_id"
    // };
    

    // filter
    // $scope.do_search = function(page){
    // 	// console.log(page);
    // 	// console.log($scope.match);
    // 	// console.log($scope.filters);

    // 	var search =  diablo_filters($scope.filters);

    // 	var time = {};
    // 	time.end_time = diablo_filter_time($scope.time.end_time, 1, dateFilter); 
    
    // 	if (angular.isDefined($scope.time.start_time) && $scope.time.start_time){
    // 	    time.start_time = dateFilter($scope.time.start_time, "yyyy-MM-dd");
    // 	} else{
    // 	    // default 30 days
    // 	    time.start_time = diablo_filter_time($scope.time.end_time, -30, dateFilter); 
    // 	} 
    
    
    // 	console.log(search);
    // 	// console.log(time);

    // 	var index = [];
    // 	for (var i=0, l=$scope.goods.length; i<l; i++){
    // 	    var good = $scope.goods[i];
    // 	    var find = true;
    
    // 	    for (var f in search){
    // 		if (search[f] !== good[match_filed[f]]){
    // 		    find = false;
    // 		    break;
    // 		}
    // 	    }

    // 	    if (find &&
    // 		(good.entry_date >= time.start_time && good.entry_date <= time.end_time)){
    // 		index.push(i);
    // 	    } 
    // 	}

    // 	$scope.filter_data = index.map(function(i){return $scope.goods[i]});
    // 	// console.log(filter_data);
    // 	diablo_order($scope.filter_data);
    // 	diabloPagination.set_data($scope.filter_data);
    // 	// console.log(diabloPagination.get_data());
    // 	$scope.total_items = diabloPagination.get_length();
    // 	$scope.page_changed($scope.default_page);
    // };
    
    // $scope.refresh();

    $scope.goto_page = diablo_goto_page; 

    var dialog = diabloUtilsService;
    $scope.lookup_detail = function(good){
	// console.log(good);
	if (good.color === "0"){
	    dialog.edit_with_modal(
		"good-detail.html", undefined, undefined, $scope,
		{sizes:  good.size.split(","),
		 colors: [{id:0}],
		 path:   good.path});
	} else{
	    if (angular.isDefined(good.colors) && good.colors.length !== 0){
		dialog.edit_with_modal(
		    "good-detail.html", undefined, undefined, $scope,
		    {sizes:  good.size.split(","),
		     colors: good.colors,
		     path:   good.path});
	    } else{
		// wgoodService.get_colors(good.color.split(",")).then(function(colors){
		//     console.log(colors);
		// good.colors = colors.map(function(c){return {id: c.id, name:c.name}});
		good.colors = good.color.split(",").map(function(cid){
		    return diablo_find_color(parseInt(cid), filterColor); 
		});
		dialog.edit_with_modal(
		    "good-detail.html", undefined, undefined, $scope,
		    {sizes:  good.size.split(","),
		     colors: good.colors,
		     path:   good.path});
		// })
	    }
	}
    };

    $scope.update_good = function(g){
	$location.path("/wgood_update/" + g.id.toString());
    };

    $scope.delete_good = function(g){
    	if (angular.isDefined(g.deleted) && !g.deleted){
    	    dialog.response(false, "删除货品", wgoodService.error[2098]);
    	} else {
    	    wgoodService.get_used_purchaser_good({
    		style_number:g.style_number, brand:g.brand_id
    	    }).then(function(result){
    		// console.log(result);
    		if (angular.isDefined(result.id)){
    		    g.deleted = false;
    		    dialog.response(
    			false,
    			"删除货品",
    			"删除货品失败：" + wgoodService.error[2098], $scope);
    		} else {
    		    var callback = function(){
    			wgoodService.delete_purchaser_good(
    			    g
    			).then(function(result){
    			    if (result.ecode === 0){
    				dialog.response_with_callback(
    				    true, "删除货品",
    				    "货品资料 ["
    					+ g.style_number
    					+ "-" + g.brand.name
    					+ "-" + g.type.name
    					+ " ]删除成功！！",
    				    $scope,
    				    function(){
    					$scope.do_search($scope.current_page)})
    			    } else {
    				dialog.response(
    				    false,
    				    "删除货品",
    				    "删除货品失败："
    					+ wgoodService.error[result.ecode],
    				    $scope);
    			    }
    			})
    		    } 
    		    dialog.request(
    			"删除货品",
    			"确定要删除该货品资料吗？",
    			callback, undefined, $scope);
    		}
    	    })    
    	}
	
    };


    // $scope.delete_good = function(g){
    // 	console.log(g);

    // 	var sure_delete = function(){
    // 	    var callback = function(params){
    // 		console.log(params);
    // 	    };
    
    // 	    dialog.edit_with_modal(
    // 		"good-delete.html",
    // 		undefined,
    // 		callback,
    // 		undefined,
    // 		{delete_stock:false, delete_sell: false})
    // 	};

    // 	dialog.request(
    // 	    "货品删除",
    // 	    "确定要删除该货品资料吗？",
    // 	    sure_delete, undefined, undefined); 
    // };
    
};
