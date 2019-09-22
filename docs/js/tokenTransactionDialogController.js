(function () {
    "use strict";

    var app = angular.module("app");

    app.controller("tokenTransactionDialogController",
        ["$scope", "$uibModalInstance", "transaction", "transactionUrl",
            function ($scope, $uibModalInstance, transaction, transactionUrl) {
                $scope.transaction = transaction;
                $scope.transactionUrl = transactionUrl;

                $scope.onCloseClick = function () {
                    $uibModalInstance.close("close");
                };
            }]
    );
}());