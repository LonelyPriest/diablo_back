var tree_utils = {
    build_unselect_tree: function (tree, roleCatlogs){
	var rootNode = tree.getRoot();
	// create catlogs
	var remainCatlogs = [];
	var parentNode = null;
	angular.forEach(roleCatlogs, function(catlog){
	    if (catlog.parent == 0){
		rootNode.addChild({
	    	    title: catlog.name,
	    	    key  : catlog.id,
		    expand: true,
		    // select: true,
	    	    isFolder: false
		})
	    }
	    else {
		//console.log(tree.toDict(false));
		parentNode = tree.getNodeByKey(catlog.parent.toString());
		//console.log(parentNode);
		if (parentNode != null ){
	    	    // console.log(parentNode);
	    	    parentNode.data.isFolder = true;
	    	    parentNode.addChild({
	    		title: catlog.name,
	    		key  : catlog.id,
			select: true,
			expand: true,
			unselectable: true,
	    		isFolder: false
	    	    })}
		else{
	    	    remainCatlogs.push(angular.copy(catlog))
		}
	    }
	});
    },


    build_edit_tree: function (tree, roleCatlogs){
	var rootNode = tree.getRoot();
	// create catlogs
	var remainCatlogs = [];
	var parentNode = null;
	angular.forEach(roleCatlogs, function(catlog){
	    if (catlog.parent == 0){
		rootNode.addChild({
	    	    title: catlog.name,
	    	    key  : catlog.id,
		    expand: true,
		    // select: true,
	    	    isFolder: false
		})
	    }
	    else {
		//console.log(tree.toDict(false));
		parentNode = tree.getNodeByKey(catlog.parent.toString());
		//console.log(parentNode);
		if (parentNode != null ){
	    	    // console.log(parentNode);
	    	    parentNode.data.isFolder = true;		    
	    	    parentNode.addChild({
	    		title: catlog.name,
	    		key  : catlog.id,
			select: true,
			expand: true,
			unselectable: false,
	    		isFolder: false
	    	    })}
		else{
	    	    remainCatlogs.push(angular.copy(catlog))
		}
	    }
	});
    },


    build_select_tree: function (tree, roleCatlogs){
	var rootNode = tree.getRoot();
	// create catlogs
	var remainCatlogs = [];
	var parentNode = null;
	angular.forEach(roleCatlogs, function(catlog){
	    if (catlog.parent == 0){
		rootNode.addChild({
	    	    title: catlog.name,
	    	    key  : catlog.id,
	    	    isFolder: false
		})
	    }
	    else {
		//console.log(tree.toDict(false));
		parentNode = tree.getNodeByKey(catlog.parent.toString());
		//console.log(parentNode);
		if (parentNode != null ){
	    	    // console.log(parentNode);
	    	    parentNode.data.isFolder = true;
	    	    parentNode.addChild({
	    		title: catlog.name,
	    		key  : catlog.id,
	    		isFolder: false
	    	    })}
		else{
	    	    remainCatlogs.push(angular.copy(catlog))
		}
	    }
	});
    },

    add_nodes: function(tree, nodes){
	var root = tree.getRoot();
	angular.forEach(nodes, function(n){
	    var current = tree.getNodeByKey(n.id.toString());
	    // node is not in tree
	    if ( current === null ){
		// parent node
		if (n.parent === 0){
		    root.addChild({
	    		title: n.name,
	    		key  : n.id,
	    		isFolder: false
		    });
		} else{
		    var parent = tree.getNodeByKey(n.parent.toString());
		    parent.data.isFolder = true;
		    parent.addChild({
	    		title: n.name,
	    		key  : n.id,
	    		isFolder: false
		    });
		}
	    }

	})
    },

    add_select_node: function(tree, node, parentId){
	var parent = tree.getNodeByKey(parentId.toString());
	//console.log(parentNode);
	if (parent != null ){
	    // console.log(parentNode);
	    parent.data.isFolder = true;
	    parent.addChild({
	    	title: node.name,
	    	key  : node.id,
		select: true,
		expand: true,
	    	isFolder: false
	    });
	    // tree.selectKey(node.id.toString());
	} else {
	    console.log("parent " + parentId.toString() + " does not found");
	}
    },

    add_child: function(tree, child, parentId){
	var parentNode = tree.getNodeByKey(parentId.toString());
	//console.log(parentNode);
	if (parentNode != null ){
	    // console.log(parentNode);
	    parentNode.data.isFolder = true;
	    parentNode.addChild({
	    	title: child.name,
	    	key  : child.id,
		select: true,
		expand: true,
		unselectable: true,
	    	isFolder: false
	    })
	} else {
	    console.log("parent" + parentId.toString() + "does not found");
	}
    },
    
    add_children: function(tree, children, parentId){
	var parentNode = tree.getNodeByKey(parentId.toString());
	//console.log(parentNode);
	if (parentNode != null ){
	    // console.log(parentNode);
	    parentNode.data.isFolder = true;
	    angular.forEach(children, function(child){
		// child not found in tree, add
		//if (tree.getNodeByKey(child.id.toString()) === null){
		parentNode.addChild({
	    	    title: child.name,
	    	    key  : child.id,
	    	    isFolder: false
		})
		//}
	    })
	} else{
	    console.log(children);
	    console.log("parent " + parentId.toString() + " does not found");
	} 
    }
    
}


