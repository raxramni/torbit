require.define 'torbit_app/router': (exports, require, module) ->

  module.exports = class TorbitAppRouter extends Marionette.AppRouter
    appRoutes:
      '': 'home'
      'home': 'home'
      'login': 'login'
      'userinfo': 'userInfo'
      'useraccounts': 'userAccounts'
      'siteconfigs': 'siteConfigs'
    initialize: ({@channel}) ->
      @channel.commands.setHandler "app:router:navigate", (path) =>
        @navigate path, {trigger: true}
    onDestroy: ->
      @channel.commands.removeHandler "app:router:navigate"
