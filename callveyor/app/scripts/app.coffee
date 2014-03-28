'use strict'

callveyor = angular.module('callveyor', [
  'ui.bootstrap',
  'ui.router',
  'doowb.angular-pusher',
  'idTwilio',
  'angularSpinner',
  'callveyor.dialer'
])
# callveyor.config([])
callveyor.controller('AppCtrl', [
  '$rootScope', '$scope', '$state', 'usSpinnerService', 'idTwilioService'
  ($rootScope,   $scope,   $state,   usSpinnerService,   idTwilioService) ->
    console.log 'MainCtrl', $scope, $state
    console.log 'all states', $state.get()
    console.log 'dialer state', $state.get('dialer')

    transitionInProgress = -> usSpinnerService.spin('global-spinner')
    transitionComplete = -> usSpinnerService.stop('global-spinner')
    $rootScope.$on('$stateChangeStart', transitionInProgress)
    $rootScope.$on('$stateChangeSuccess', transitionComplete)
    $rootScope.$on('$stateChangeError', transitionComplete)

    $state.go('dialer.ready')
])