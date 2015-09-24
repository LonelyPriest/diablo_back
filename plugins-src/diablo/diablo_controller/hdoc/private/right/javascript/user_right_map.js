var rightAuthen = {
    
    account: {
	_master: 1,
	_user: 2
    },
    // _root_right : {
    // 	shop: 40000
    // }, 

    shop_action: function(){
    	return {
    	    new_repo     : this._root_right.shop + 5,
    	    del_repo     : this._root_right.shop + 6,
    	    update_repo  : this._root_right.shop + 7,
    	    list_repo    : this._root_right.shop + 8
    	}
    },
    
    authen: function(authenAction, rights){
    	for (var i = 0, l = rights.length; i < l; i++){
    	    if (rights[i].id === rightAuthen.shop_action[authenAction]){
    		// console.log(rights[i].id, actions[Authenaction]);
    		return true;
    	    };
    	};

    	return false;
    },

    show_orgprice: function(userType) {
	return userType === rightAuthen.account._master ? true:false;
    }
};
