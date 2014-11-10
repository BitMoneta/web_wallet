angular.module("app").controller "RootController", ($scope, $location, $modal, $q, $http, $rootScope, $state, $stateParams, Wallet, Client, $idle, Shared, Info) ->
    $scope.unlockwallet = false
    $scope.bodyclass = "cover"
    $scope.currentPath = $location.path()

    $scope.current_path_includes = (str)->
        $state.current.name.indexOf(str) >= 0

    Wallet.check_wallet_status().then ->
        Info.watch_for_updates()

    $scope.started = false

    closeModals = ->
        if $scope.warning
            $scope.warning.close()
            $scope.warning = null
        if $scope.timedout
            $scope.timedout.close()
            $scope.timedout = null
        return
    $scope.started = false
    $scope.$on "$idleStart", ->
        closeModals()
        $scope.warning = $modal.open(
            templateUrl: "warning-dialog.html"
            windowClass: "modal-danger"
        )
        return

    $scope.$on "$idleEnd", ->
        closeModals()
        return

    $scope.$on "$idleTimeout", ->
        closeModals()
        Wallet.wallet_lock().then ->
            console.log('Wallet was locked due to inactivity')
            navigate_to('unlockwallet')

    $scope.startIdleWatch = ->
        closeModals()
        $idle.watch()
        $scope.started = true
        return

    $scope.stopIdleWatch = ->
        closeModals()
        $idle.unwatch()
        $scope.started = false
        return

    open_wallet = (mode) ->
        $rootScope.cur_deferred = $q.defer()
        $modal.open
            templateUrl: "openwallet.html"
            controller: "OpenWalletController"
            resolve:
                return: ->
                    mode
        $rootScope.cur_deferred.promise

    $scope.wallet_action = (mode) ->
        open_wallet(mode)

#    $scope.$watch ->
#        $location.path()
#    , ->
#        $scope.currentPath = $location.path()
#        if $location.path() == "/unlockwallet" || $location.path() == "/createwallet"
#            stopIdleWatch()
#            $scope.bodyclass = "splash"
#            $scope.unlockwallet = true
#        else
#            # TODO update bodyclass by watching unlockwallet
#            startIdleWatch()
#            $scope.bodyclass = "splash"
#            $scope.unlockwallet = false
#            Wallet.check_wallet_status()

    $scope.$watch ->
        Info.info.wallet_unlocked
    , (unlocked)->
        navigate_to('unlockwallet') if Info.info.wallet_open and !unlocked
    , true

    $scope.clear_form_errors = (form) ->
        form.$error.message = null if form.$error.message
        for key of form
            continue if /^(\$|_)/.test key
            control = form[key]
            control.$setPristine true
            control.clear_errors() if control && control.clear_errors

    $scope.close_context_help = ->
        $scope.context_help.open = false
