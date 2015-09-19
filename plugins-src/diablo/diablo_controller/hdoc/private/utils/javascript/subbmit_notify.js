
var subbmitNotify = angular.module("subbmitNotify", ['diabloUtils']);


subbmitNotify.directive("subbmitNotifyDialog", function(){
    return{
	restrict: 'AE',
	templateUrl: '/private/utils/html/subbmitNotifyDialog.html', 
	replace: false,
	transclude: true,
	scope:{
	    dialogId: '@',
	    notifyTitle: '@',
	    notifyBody: '@',
	    target: '@',
	    subbmitCallback: '&'
	},
	link: function(scope, element, attrs){
	    scope.cancel = function(){
		console.log("cancel");
		$('#' + scope.dialogId).hide();
	    }
	    // console.log(scope);
	    // console.log(scope.dialogId);
	    // console.log(scope.target);
	}
    }
});

subbmitNotify.directive("responseNotifyDialog", function(){
    return{
	restrict: 'AE',
	templateUrl: '/private/utils/html/responseNotifyDialog.html', 
	replace: false,
	transclude: true,
	
	scope: {
	    responseDialogId: '@',
	    successTitle: '@',
	    errorTitle: '@',
	    successInfo: '@',
	    errorInfo: '@',
	    response: '&',
	    afterClose: '&'
	},
	link: function(scope, element, attrs){
	    scope.close = function(){
		$('#' + scope.responseDialogId).modal('hide');
		$('body').removeClass('modal-open');
		$('.modal-backdrop').remove();
		console.log("afterclose");
		scope.afterClose();
	    }
	}
    }
});




