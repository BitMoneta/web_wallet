angular.module("app").controller "ManageAssetsController", ($scope, $location, $stateParams, Growl, BlockchainAPI, RpcService, Blockchain, Utils) ->

    $scope.name = $stateParams.name
   
    $scope.is_registered = false
    $scope.assets = []
    $scope.my_assets = []
    $scope.my_symbols = []
    
    BlockchainAPI.get_account_record($scope.name).then (result) =>
        if result
            $scope.is_registered = true

    refresh_my_assets = ->
        $scope.assets = []
        $scope.my_assets = []
        $scope.my_symbols = []
        BlockchainAPI.list_registered_assets("", -1).then (result) =>
            $scope.assets = result
            asset_ids = []
            for asset in $scope.assets
                asset_ids.push [asset.issuer_account_id]

            Blockchain.refresh_asset_records().then ()->
                RpcService.request("batch", ["blockchain_get_account_record_by_id", asset_ids]).then (response) ->
                    accounts = response.result
                    for i in [0...accounts.length]
                        if accounts[i]
                            $scope.assets[i].account_name = accounts[i].name
                        else
                            $scope.assets[i].account_name = "None"

                        if accounts[i] and accounts[i].name == $scope.name
                            asset = $scope.assets[i]
                            asset_type = Blockchain.asset_records[asset.id]

                            asset.current_supply = Utils.newAsset(asset.current_share_supply, asset_type.symbol, asset_type.precision)
                            asset.maximum_supply = Utils.newAsset(asset.maximum_share_supply, asset_type.symbol, asset_type.precision)
                            asset.c_fees = Utils.newAsset(asset.collected_fees, asset_type.symbol, asset_type.precision)
                            $scope.my_assets.push $scope.assets[i]
                            $scope.my_symbols.push $scope.assets[i].symbol

    refresh_my_assets()
