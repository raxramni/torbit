require.define 'torbit_app/main': (exports, require, module) ->
  TorbitApp = module.exports

  TorbitAppRouter    = require 'torbit_app/router'
  Auth               = require 'torbit_app/auth'
  TorbitReport       = require 'torbit_app/report'
  SiteConfigs        = require 'torbit_app/site_configs/main'

  class TorbitApp.Layout extends Marionette.LayoutView
    template: JST['torbit_app/layout']
    ui:
      itemForecasts: '.item-forecasts'
      quantityChart: '.forecast-quantity-chart-box'
      details: '.forecast-details-box'
      eventParams: '.forecast-events-box'
      main: '.main-box'
    regions:
      main: '.main-box'

  class TorbitApp.Controller extends Backbone.Marionette.Controller
    initialize: ({@$el}) ->
      @layout = new TorbitApp.Layout(el: @$el)
      @channel = new Backbone.Wreqr.Channel()
      @router  = new TorbitAppRouter({@channel, controller: this})
      @authController = new Auth.Controller({@channel})

      @channel.reqres.setHandler "app:main_region", =>
        @layout.main

      @channel.commands.setHandler "app:user:authenticated", ({@user, @token}) =>
        @router.navigate 'home', {trigger: true}

      @channel.commands.setHandler "app:user:deAuthenticated", =>
        #delete all the views/controllers except auth controller
        @router.navigate 'login', {trigger: true}

    start: ->
      @layout.render().trigger('show')
      Backbone.history.start()
      @authController.start()

    onDestroy: ->
      @channel.reset()
      @router.destroy()

    home: ->
      if @authController.getAuthInfo()?
        @_showReport()
      else
        @channel.commands.execute "app:router:navigate", 'login'

    userInfo: ->
      if @authController.getAuthInfo()?
        @authController.showUserPage()
      else
        @channel.commands.execute "app:router:navigate", 'login'

    siteConfigs: ->
      @configsController = new SiteConfigs.Controller({@channel})
      @configsController.start()

    login: ->
      if @authController.getAuthInfo()?
        @channel.commands.execute "app:router:navigate", 'home'
      else
        @authController.showLoginPage()

    _showReport: ->
      @reportController?= new TorbitReport.Controller({@channel})
      @reportController.start()

  # ------------------------------------------------------------------------------------------------------------------ #
  module.exports.start = ({$el}) ->
    controller = new TorbitApp.Controller({$el})
    controller.start()
