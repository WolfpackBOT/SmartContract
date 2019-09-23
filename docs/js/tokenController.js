(function () {
    "use strict";

    var app = angular.module("app");

    app.controller("tokenController",
        ["$scope", "$q", "$http", "$window", "$uibModal", "$location", "websiteSettings",
            function ($scope, $q, $http, $window, $uibModal, $location, websiteSettings) {
                $scope.web3 = new Web3(Web3.givenProvider);
                document.getElementById("mainPageBody").style.visibility = "visible";

                $scope.baseUrl = websiteSettings.baseUrl;
                $scope.contractAddress = websiteSettings.smartContractAddress;

                var refParam = $location.search().ref;
                if(refParam) {
                    $scope.referrerAddress = refParam;
                }

                $scope.loading = true;
                $scope.loadingMetamask = true;
                $scope.defaultAccount = null;
                $scope.gasPrice = 2000000;
                $scope.error = null;
                $scope.message = "";
                $scope.loading = true;
                $scope.hasWeb3 = false;
                $scope.showInstallMetaMask = false;
                $scope.contract = null;
                $scope.tokenBalance = 0;
                $scope.dividendBalance = "0";
                $scope.dividendBalanceNumber = 0;
                $scope.currentPrice = 53000000000000;
                $scope.currentPriceEth = "0.000053";
                $scope.tokenName = "";
                $scope.tokenSymbol = "";
                $scope.buyPriceTokensPerEth = "";
                $scope.sellPriceEthPerToken = "";
                $scope.sellAllowed = false;
                $scope.sellTokenCount = 1;
                $scope.sellTokensEth = 0;
                $scope.transferTokenCount = null;
                $scope.transferTokenAddress = null;
                $scope.buyEthAmount = 1;
                $scope.buyTransaction = null;
                $scope.buyTransactionUrl = null;
                $scope.validBuyAmount = true;
                $scope.validSellAmount = true;
                $scope.poolTotal = 0;
                $scope.poolFloor = 0;
                $scope.poolCeiling = 0;
                $scope.pctToCeiling = 0;
                $scope.totalDividends = 0;
                $scope.contractEthValue = null;
                $scope.buyReferrerPercent = null;
                $scope.buyHolderPercent = null;
                $scope.sellHolderPercent = null;
                $scope.paused = false;
                $scope.balanced = true;
                $scope.eventsSubscribed = false;
                $scope.addressData = [];
                $scope.recentActivity = [];
                $scope.ethScanBaseUrl = websiteSettings.environment === "production" ? "https://etherscan.io" : "https://ropsten.etherscan.io";
                $scope.expectedNetwork = websiteSettings.environment === "production" ? "1" : "3";
                $scope.expectedNetworkName = websiteSettings.environment === "production" ? "Main Ethereum Network" : "Ropsten Test Network";
                $scope.currentNetwork = null;

                $scope.isBoardMember = false;
                $scope.totalBoardMembers = 0;
                $scope.boardMemberApproved = false;
                $scope.setMinBoardMemberApprovalsForAction_val = null;
                $scope.addBoardMember_val = null;
                $scope.removeBoardMember_val = null;
                $scope.freezeAddress_val = null;
                $scope.unfreezeAddress_val = null;
                $scope.mint_val = null;
                $scope.burn_val = null;
                $scope.paused = null;
                $scope.setName_val = null;
                $scope.setSymbol_val = null;
                $scope.setIncrement_val = null;
                $scope.setLowerCap_val = null;
                $scope.setMinimumEthSellAmount_val = null;
                $scope.setPoolFloor_val = null;
                $scope.setPoolCeiling_val = null;
                $scope.setPoolBuyReferrerPercent_val = null;
                $scope.setPoolBuyHolderPercent_val = null;
                $scope.setPoolSellHolderPercent_val = null;
                $scope.setPoolBuyMintOwnerPercent_val = null;
                $scope.setPoolSellHoldOwnerPercent_val = null;
                $scope.fundOverdrawPool_val = null;
                $scope.totalDividends = 0;
                $scope.totalDividendsClaimed = 0;
                $scope.dividendsUnclaimed = 0;
                
                $scope.leaderboardExlusions = ["0xD1D9Dad7FC00A933678eEf64b3CaC3a3AF0a5AB4", "0xE242CeF45608826216f7cA2d548c48562b50CdD0", "0x7B5973D4F41Af6bA50e2feD457d7c91D5A33349C", "0x54168F68D51a86DEdA3D5EA14A3E45bE74EFfbd4", "0x6102dB8E1d47D359CafF9ADa4f0b0a8378d35109", "0xaBE5EE06B246e23d69ffb44F6d5996686b69ce3b"];

                $scope.copyReferral = function () {
                    var referralUrl = document.getElementById("referralUrl");
                    referralUrl.focus();
                    referralUrl.select();
                    var data = document.execCommand("copy");
                    if (data) {
                        alert("Copied!");
                    } else {
                        alert("Error during copy!");
                    }
                };

                $scope.executeContractCommand0 = function (command) {
                    $scope.contract[command]({
                        gas: $scope.gasPrice
                    }, function (err, result) {
                        if (!err && result) {
                            $scope.resetInputs();
                            $scope.showTransaction(result, $scope.ethScanBaseUrl + "/tx/" + result);
                        }
                    });
                };

                $scope.executeContractCommand1 = function (command, param) {
                    if (!param) {
                        return false;
                    }
                    $scope.contract[command](param, {
                        gas: $scope.gasPrice
                    }, function (err, result) {
                        if (!err && result) {
                            $scope.resetInputs();
                            $scope.showTransaction(result, $scope.ethScanBaseUrl + "/tx/" + result);
                        }
                    });
                };

                $scope.executeContractCommand2 = function (command, param1, param2) {
                    if (!param) {
                        return false;
                    }
                    $scope.contract[command](param1, param2, {
                        gas: $scope.gasPrice
                    }, function (err, result) {
                        if (!err && result) {
                            $scope.resetInputs();
                            $scope.showTransaction(result, $scope.ethScanBaseUrl + "/tx/" + result);
                        }
                    });
                };

                $scope.recalculateBuyEstimate = function () {
                    var wei = web3.toDecimal(web3.toWei($scope.buyEthAmount));
                    if (wei > $scope.currentPrice) {
                        $scope.contract.estimateBuy(wei, $scope.referrerAddress !== "0x0", (error, result) => {
                            $scope.$apply(function () {
                                $scope.validBuyAmount = true;
                                $scope.buyPriceTokensPerEth = '' + web3.toDecimal(result[0]);
                            });
                        });
                    } else {
                        $scope.$apply(function () {
                            $scope.validBuyAmount = false;
                            $scope.buyPriceTokensPerEth = "0";
                        });
                    }
                };

                $scope.recalculateSellEstimate = function () {
                    var tokenCount = 0;
                    try {
                        tokenCount = parseInt($scope.sellTokenCount, 10);
                    } catch (err) {
                        console.log("Invalid sell amount");
                    }

                    if (tokenCount > 0 && tokenCount <= $scope.tokenBalance) {
                        $scope.validSellAmount = true;
                    } else {
                        $scope.validSellAmount = false;
                    }

                    $scope.contract.estimateSell(tokenCount, (error, result) => {
                        var eth = web3.fromWei(result[0], "ether").toString(10);
                        $scope.$apply(function () {
                            $scope.sellTokensEth = eth;
                        });
                    });
                };

                $scope.resetInputs = function () {
                    $scope.buyEthAmount = 1;
                    $scope.sellTokenCount = null;
                    $scope.transferTokenAddress = null;
                    $scope.transferTokenCount = null;
                    $scope.contractBoardStatusApproved = false;
                    $scope.contractBoardStatusApprovedCount = 0;
                    $scope.setMinBoardMemberApprovalsForAction_val = null;
                    $scope.addBoardMember_val = null;
                    $scope.removeBoardMember_val = null;
                    $scope.freezeAddress_val = null;
                    $scope.unfreezeAddress_val = null;
                    $scope.mint_val = null;
                    $scope.burn_val = null;
                    $scope.paused = null;
                    $scope.setName_val = null;
                    $scope.setSymbol_val = null;
                    $scope.setIncrement_val = null;
                    $scope.setLowerCap_val = null;
                    $scope.setMinimumEthSellAmount_val = null;
                    $scope.setPoolFloor_val = null;
                    $scope.setPoolCeiling_val = null;
                    $scope.setPoolBuyReferrerPercent_val = null;
                    $scope.setPoolBuyHolderPercent_val = null;
                    $scope.setPoolSellHolderPercent_val = null;
                    $scope.setPoolBuyMintOwnerPercent_val = null;
                    $scope.setPoolSellHoldOwnerPercent_val = null;
                    $scope.fundOverdrawPool_val = null;
                };

                $scope.buyTokens = function () {
                    $scope.contract.buy($scope.referrerAddress, {
                        value: web3.toWei($scope.buyEthAmount, "ether"),
                        gas: $scope.gasPrice
                    }, function (err, result) {
                        if (!err && result) {
                            $scope.resetInputs();
                            $scope.showTransaction(result, $scope.ethScanBaseUrl + "/tx/" + result);
                        }
                    });
                };

                $scope.sellTokens = function () {
                    $scope.contract.sell(parseInt($scope.sellTokenCount, 10), {
                        gas: $scope.gasPrice
                    }, function (err, result) {
                        if (!err && result) {
                            $scope.resetInputs();
                            $scope.showTransaction(result, $scope.ethScanBaseUrl + "/tx/" + result);
                        }
                    });
                };

                $scope.claimDividends = function () {
                    $scope.contract.claimDividend({
                        gas: $scope.gasPrice
                    }, function (err, result) {
                        if (!err && result) {
                            $scope.resetInputs();
                            $scope.showTransaction(result, $scope.ethScanBaseUrl + "/tx/" + result);
                        }
                    });
                };

                $scope.reinvestDividends = function () {
                    $scope.contract.reinvest($scope.referrerAddress, {
                        gas: $scope.gasPrice
                    }, function (err, result) {
                        if (!err && result) {
                            $scope.resetInputs();
                            $scope.showTransaction(result, $scope.ethScanBaseUrl + "/tx/" + result);
                        }
                    });
                };

                $scope.transfer = function () {
                    $scope.contract.transfer($scope.transferTokenAddress, parseInt($scope.transferTokenCount, 10), {
                        gas: $scope.gasPrice
                    }, function (err, result) {
                        if (!err && result) {
                            $scope.resetInputs();
                            $scope.showTransaction(result, $scope.ethScanBaseUrl + "/tx/" + result);
                        }
                    });
                };

                $scope.fundOverdrawPool = function () {
                    $scope.contract.fundOverdrawPool({
                        value: web3.toWei($scope.fundOverdrawPool_val, "ether"),
                        gas: $scope.gasPrice
                    }, function (err, result) {
                        if (!err && result) {
                            $scope.resetInputs();
                            $scope.showTransaction(result, $scope.ethScanBaseUrl + "/tx/" + result);
                        }
                    });
                };

                $scope.wireUpEvents = function () {
                    $window.ethereum.on('accountsChanged', function (accounts) {
                        if (!$scope.loading) {
                            $scope.resetInputs();
                            $scope.load();
                        }
                    });

                    $window.ethereum.on('networkChanged', function (networkId) {
                        if (!$scope.loading) {
                            web3.version.getNetwork((err, netId) => {
                                $scope.currentNetwork = netId;
                            });
                            $scope.load();
                        }
                    });

                    $scope.contract.allEvents({ fromBlock: "latest", toBlock: "latest" }).watch((error, result) => {
                        if (!error) {
                            $scope.refreshStats();
                        }
                    });

                    $scope.eventsSubscribed = true;
                };

                $scope.processEvents = function (events) {
                    var deferred = $q.defer();

                    var i = 0;
                    var rtnEvents = [];
                    angular.forEach(events, function (value, key) {
                        i++;
                        if (value.event === "onTokenPurchase") {
                            value.eventType = "buy";
                            value.from = $scope.contractAddress;
                            value.to = value.args.customerAddress;
                            value.amount = parseInt(value.args.tokensMinted, 10);
                        } else if (value.event === "onTokenSell") {
                            value.eventType = "sell";
                            value.to = $scope.contractAddress;
                            value.from = value.args.customerAddress;
                            value.amount = parseInt(value.args.tokensBurned, 10);
                        } else if (value.event === "Transfer") {
                            value.eventType = "transfer";
                            value.to = value.args.to;
                            value.from = value.args.from;
                            value.amount = parseInt(value.args.value, 10);
                        }

                        if (!$scope.isInExclusionList(value.from) && !$scope.isInExclusionList(value.to)) {
                            rtnEvents.push(value);
                        }

                        web3.eth.getBlock(value.blockNumber, (err, block) => {
                            value.timestamp = block.timestamp;
                            value.date = moment.unix(block.timestamp).format();

                            if (i === events.length) {
                                deferred.resolve(rtnEvents);
                            }
                        });
                    });

                    return deferred.promise;
                };

                $scope.processAccounts = function (accounts) {
                    var deferred = $q.defer();

                    var i = 0;
                    angular.forEach(accounts, function (a, k) {
                        i++;
                        $scope.contract.balanceOf(a.address, (error, result) => {
                            a.tokenBalance = web3.toDecimal(result);

                            $scope.contract.dividendBalanceOf(a.address, (error, wei) => {
                                a.dividendBalance = web3.fromWei(wei, "ether").toString(10);

                                if (i === accounts.length) {
                                    deferred.resolve(accounts);
                                }
                            });
                        });
                    });

                    return deferred.promise;
                };

                $scope.isInExclusionList = function (a) {
                    return _.findIndex($scope.leaderboardExlusions, function (o) { return o.toLowerCase() === a.toLowerCase(); }) > -1;
                };

                $scope.shouldAddAddress = function (a, arr) {
                    if (!a || a.toLowerCase() === $scope.contractAddress.toLowerCase()) {
                        return false;
                    }

                    if ($scope.isInExclusionList(a)) {
                        return false;
                    }

                    return _.findIndex(arr, function (o) { return o.address === a; }) < 0;
                };

                $scope.refreshBoardData = function () {
                    $scope.contract.getBoardStatus.call((error, resp) => {
                        $scope.contractBoardStatusApproved = resp[0];
                        $scope.contractBoardStatusApprovedCount = parseInt(resp[1], 10);
                        $scope.totalBoardMembers = parseInt(resp[2], 10);
                        $scope.setMinBoardMemberApprovalsForAction_val = parseInt(resp[3], 10);
                    });
                    $scope.contract.name.call((error, resp) => {
                        $scope.setName_val = resp;
                    });
                    $scope.contract.symbol.call((error, resp) => {
                        $scope.setSymbol_val = resp;
                    });
                    $scope.contract.increment.call((error, resp) => {
                        $scope.setIncrement_val = resp;
                    });
                    $scope.contract.lowerCap.call((error, resp) => {
                        $scope.setLowerCap_val = resp;
                    });
                    $scope.contract.minimumEthSellAmount.call((error, resp) => {
                        $scope.setMinimumEthSellAmount_val = resp;
                    });
                    $scope.contract.getPoolInfo.call((error, resp) => {
                        $scope.setPoolFloor_val = resp[1];
                        $scope.setPoolCeiling_val = resp[2];
                        $scope.totalDividends = web3.fromWei(resp[3], "ether").toString(10);

                        $scope.setPoolBuyReferrerPercent_val = resp[6];
                        $scope.setPoolBuyHolderPercent_val = resp[7];
                        $scope.setPoolSellHolderPercent_val = resp[8];
                        $scope.setPoolBuyMintOwnerPercent_val = resp[9];
                        $scope.setPoolSellHoldOwnerPercent_val = resp[10];
                        $scope.totalDividendsClaimed = web3.fromWei(resp[11], "ether").toString(10);
                        $scope.dividendsUnclaimed = web3.fromWei(resp[12], "ether").toString(10);
                        $scope.balanced = resp[13];
                    });

                    $scope.contract.getPoolBalanceInfo.call((error, resp) => {
                        $scope.overdrawPool = web3.fromWei(resp[5], "ether").toString(10);
                        $scope.totalOverdrawn = web3.fromWei(resp[6], "ether").toString(10);
                    });
                };

                $scope.refreshStats = function () {
                    $scope.contract.name.call((error, resp) => {
                        $scope.tokenName = resp;
                    });
                    $scope.contract.symbol.call((error, resp) => {
                        $scope.tokenSymbol = resp;
                    });

                    $scope.contract.isSenderBoardMember.call((error, result) => {
                        $scope.isBoardMember = result;

                        if ($scope.isBoardMember) {
                            $scope.refreshBoardData();

                            $scope.contract.isSenderBoardMemberApproved.call((error, result2) => {
                                $scope.boardMemberApproved = result2;

                                $("#boardMemberApproval").btnSwitch({
                                    OnValue: true,
                                    OnCallback: function (val, instance) {
                                        $scope.contract.addBoardMemberApproval(val, {
                                            gas: $scope.gasPrice
                                        }, function (err, addBoardMemberApprovalResult) {
                                            if (!err && addBoardMemberApprovalResult) {
                                                $scope.showTransaction(addBoardMemberApprovalResult, $scope.ethScanBaseUrl + "/tx/" + addBoardMemberApprovalResult);
                                            }
                                        });
                                    },
                                    OffValue: false,
                                    OffCallback: function (val, instance) {
                                        $scope.contract.addBoardMemberApproval(val, {
                                            gas: $scope.gasPrice
                                        }, function (err, addBoardMemberApproval2Result) {
                                            if (!err && addBoardMemberApproval2Result) {
                                                $scope.showTransaction(addBoardMemberApproval2Result, $scope.ethScanBaseUrl + "/tx/" + addBoardMemberApproval2Result);
                                            }
                                        });
                                    },
                                    Theme: "Light",
                                    ToggleState: $scope.boardMemberApproved,
                                    ConfirmChanges: false
                                });

                                $scope.contract.paused.call((error, resultPaused) => {
                                    $scope.paused = resultPaused;

                                    if ($scope.contractBoardStatusApproved) {
                                        $("#pause").btnSwitch({
                                            OnValue: true,
                                            OnCallback: function (val, instance) {
                                                $scope.contract.pause({
                                                    gas: $scope.gasPrice
                                                }, function (err, pauseResult) {
                                                    if (!err && pauseResult) {
                                                        $scope.showTransaction(pauseResult, $scope.ethScanBaseUrl + "/tx/" + pauseResult);
                                                    }
                                                });
                                            },
                                            OffValue: false,
                                            OffCallback: function (val, instance) {
                                                $scope.contract.unpause({
                                                    gas: $scope.gasPrice
                                                }, function (err, unpauseResult) {
                                                    if (!err && unpauseResult) {
                                                        $scope.showTransaction(unpauseResult, $scope.ethScanBaseUrl + "/tx/" + unpauseResult);
                                                    }
                                                });
                                            },
                                            Theme: "Light",
                                            ToggleState: $scope.paused,
                                            ConfirmChanges: false
                                        });
                                    }
                                });
                            });
                        } else {
                            $scope.contract.paused.call((error, resultPaused) => {
                                $scope.paused = resultPaused;
                            });
                        }
                    });

                    $scope.leaderboardData = [];
                    $scope.recentActivity = [];

                    var refParam = $location.search().ref;
                    if($scope.referrerAddress) {
                        if($scope.referrerAddress !== "0x0") {
                            if($scope.referrerAddress.toUpperCase() === $scope.defaultAccount.toUpperCase()) {
                                $scope.referrerAddress = "0x0";
                            }
                        }
                    } else if(refParam) {
                        $scope.referrerAddress = refParam;
                    } else {
                        $scope.referrerAddress = "0x0";
                    }

                    $scope.contract.allEvents({ fromBlock: 0, toBlock: "latest" }).get((error, results) => {
                        if (!error) {
                            var relaventEvents = _.filter(results, function (e) { return e.event === "onTokenPurchase" || e.event === "onTokenSell" || e.event === "Transfer"; });

                            $scope.processEvents(relaventEvents).then(function (processedEvents) {
                                var addressDataArr = [];
                                angular.forEach(processedEvents, function (e, k) {
                                    if ($scope.shouldAddAddress(e.from, addressDataArr)) {
                                        addressDataArr.push({
                                            address: e.from,
                                            tokenBalance: null,
                                            dividendBalance: null
                                        });
                                    }
                                    if ($scope.shouldAddAddress(e.to, addressDataArr)) {
                                        addressDataArr.push({
                                            address: e.to,
                                            tokenBalance: null,
                                            dividendBalance: null
                                        });
                                    }
                                });

                                $scope.recentActivity = _.orderBy(processedEvents, [(o) => +o.timestamp], ["desc"]);
                                $scope.processAccounts(addressDataArr).then(function (accounts) {
                                    $scope.leaderboardData = _.orderBy(accounts, [(o) => +o.tokenBalance], ["desc"]);
                                    var rank = 0;
                                    angular.forEach($scope.leaderboardData, function (a, k) {
                                        rank++;
                                        a.rank = rank;
                                    });
                                });
                            });
                        }
                    });

                    // Current price
                    $scope.contract.currentPrice.call((error, wei) => {
                        $scope.$apply(function () {
                            $scope.currentPrice = web3.toDecimal(wei);
                            $scope.currentPriceEth = web3.toDecimal(web3.fromWei(wei, "ether"));
                        });

                        // Balance
                        $scope.contract.balanceOf($scope.defaultAccount, (error, result) => {
                            var tokens = web3.toDecimal(result);
                            $scope.$apply(function () {
                                $scope.tokenBalance = tokens;

                                if (tokens > 0) {
                                    $scope.sellTokenCount = tokens;
                                    $scope.transferTokenCount = tokens;
                                } else {
                                    $scope.sellTokenCount = null;
                                    $scope.transferTokenCount = null;
                                }
                            });

                            // Pool info
                            $scope.contract.getPoolInfo.call((error, result) => {
                                $scope.$apply(function () {
                                    $scope.poolTotal = web3.toDecimal(web3.fromWei(result[0], "ether"));
                                    $scope.poolFloor = web3.toDecimal(web3.fromWei(result[1], "ether"));
                                    $scope.poolCeiling = web3.toDecimal(web3.fromWei(result[2], "ether"));
                                    $scope.totalDividends = web3.toDecimal(web3.fromWei(result[3], "ether"));
                                    $scope.sellAllowed = result[4];
                                    $scope.contractEthValue = web3.toDecimal(web3.fromWei(result[5], "ether"));
                                    $scope.buyReferrerPercent = web3.toDecimal(result[6]);
                                    $scope.buyHolderPercent = web3.toDecimal(result[7]);
                                    $scope.sellHolderPercent = web3.toDecimal(result[8]);
                                    $scope.pctToCeiling = ($scope.poolTotal / $scope.poolCeiling * 100).toFixed(2);

                                    if (!$scope.sellAllowed) {
                                        $scope.sellTokenCount = null;
                                    }
                                });

                                if ($scope.sellAllowed && $scope.tokenBalance > 0) {
                                    $scope.recalculateSellEstimate();
                                }

                                $scope.recalculateBuyEstimate();

                                // Dividends
                                $scope.contract.dividendBalanceOf($scope.defaultAccount, (error, wei) => {
                                    $scope.$apply(function () {
                                        $scope.dividendBalanceNumber = web3.toDecimal(web3.fromWei(wei, "ether"));
                                        $scope.dividendBalance = $scope.dividendBalanceNumber.toString(10);
                                    });

                                    // Paused
                                    $scope.contract.paused.call((error, result) => {
                                        $scope.$apply(function () {
                                            $scope.paused = result;
                                        });

                                        // Finished
                                        if (!$scope.eventsSubscribed) {
                                            $scope.wireUpEvents();
                                        }

                                        $scope.loading = false;
                                    });
                                });
                            });
                        });
                    });
                };

                $scope.load = function () {
                    $scope.loading = true;
                    if (typeof $window.ethereum !== "undefined" || typeof $window.web3 !== "undefined") {
                        web3.version.getNetwork((err, netId) => {
                            $scope.currentNetwork = netId;
                        });

                        $scope.loadingMetamask = true;
                        $window.ethereum.enable().then(function (accounts) {
                            $scope.hasWeb3 = true;
                            $window.ethereum.autoRefreshOnNetworkChange = false;
                            $scope.defaultAccount = accounts[0];
                            $scope.loadingMetamask = false;

                            $http.get("abi.json")
                                .then(function (res) {
                                    $scope.contract = web3.eth.contract(res.data).at($scope.contractAddress);
                                    $scope.refreshStats();
                                });
                        }).catch(function (reason) {
                            console.info(reason);
                            $scope.loadingMetamask = false;
                            console.log(reason === "User rejected provider access");
                        });
                    } else {
                        $scope.loadingMetamask = false;
                        $scope.error = "You need a web3 browser or install MetaMask to use this page.";
                        $scope.showInstallMetaMask = true;
                    }
                };
                $scope.load();

                $scope.showTransaction = function (tx, txUrl) {
                    $uibModal.open({
                        templateUrl: "tokenTransactionDialog.html",
                        controller: "tokenTransactionDialogController",
                        size: "md",
                        backdrop: "static",
                        keyboard: false,
                        resolve: {
                            transaction: function () {
                                return tx;
                            },
                            transactionUrl: function () {
                                return txUrl;
                            }
                        }
                    });
                };
            }]
    );
}());