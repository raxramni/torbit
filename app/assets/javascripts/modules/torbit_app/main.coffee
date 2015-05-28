require.define 'torbit_app/main': (exports, require, module) ->
  TorbitApp = module.exports

  TorbitAppRouter    = require 'torbit_app/router'
  Auth               = require 'torbit_app/auth'
  TorbitReport       = require 'torbit_app/report'
  SiteConfigs        = require 'torbit_app/site_configs/main'
  UserAccounts        = require 'torbit_app/user_accounts/main'

  class TorbitApp.Layout extends Marionette.LayoutView
    template: JST['torbit_app/layout']
    ui:
      main: '.main-box'
      notifications: '.notifications'
      navTabs: '.nav li'
    regions:
      main: '.main-box'
    onRender: ->
      @ui.notifications.hide()
    navHighlight: (tabClass) ->
      @ui.navTabs.removeClass('active')
      $(".nav li.#{tabClass}").addClass('active')
    showErrors: (errors) ->
      @ui.notifications.text(errors).show()
    clearErrors: ->
      @ui.notifications.empty().hide()

  class TorbitApp.Controller extends Backbone.Marionette.Controller
    initialize: ({@$el}) ->
      @layout = new TorbitApp.Layout(el: @$el)
      @channel = new Backbone.Wreqr.Channel()
      @router  = new TorbitAppRouter({@channel, controller: this})
      @authController = new Auth.Controller({@channel})

      @channel.reqres.setHandler "app:main_region", =>
        @layout.main

      @channel.commands.setHandler "app:user:authenticated", ({@user, @token}) =>
        @layout.clearErrors()
        @router.navigate 'home', {trigger: true}

      @channel.commands.setHandler "app:user:authFailed", (message=null) =>
        @authController.deAuthenticate()
        @layout.showErrors(message) if message?
        @channel.commands.execute 'app:user:deAuthenticated'

      @channel.commands.setHandler "app:user:deAuthenticated", =>
        #delete all the views/controllers except auth controller
        @siteConfigsController?.destroy()
        @userAccountsController?.destroy()
        @reportController?.destroy()
        @router.navigate 'login', {trigger: true}

    start: ->
      @layout.render().trigger('show')
      Backbone.history.start()
      @authController.start()

    onDestroy: ->
      @siteConfigsController?.destroy()
      @userAccountsController?.destroy()
      @reportController?.destroy()
      @channel.reset()
      @router?.destroy()
      @layout?.destroy()

    home: ->
      @layout.navHighlight('home')
      if @authController.getAuthInfo()?
        @reportController?.destroy()
        @reportController= new TorbitReport.Controller({mountRegion: @layout.main, @channel})
        @reportController.start()
      else
        @channel.commands.execute "app:router:navigate", 'login'

    userInfo: ->
      @layout.navHighlight('userinfo')
      if @authController.getAuthInfo()?
        @authController.showUserPage()
      else
        @channel.commands.execute "app:router:navigate", 'login'

    siteConfigs: ->
      @layout.navHighlight('siteconfigs')
      @siteConfigsController?.destroy()
      if @authController.getAuthInfo()?
        @siteConfigsController = new SiteConfigs.Controller({mountRegion: @layout.main, @channel})
        @siteConfigsController.start()
      else
        @channel.commands.execute "app:router:navigate", 'login'

    userAccounts: ->
      @layout.navHighlight('useraccounts')
      @userAccountsController?.destroy()
      if @authController.getAuthInfo()?
        @userAccountsController = new UserAccounts.Controller({mountRegion: @layout.main, @channel})
        @userAccountsController.start()
      else
        @channel.commands.execute "app:router:navigate", 'login'

    login: ->
      @layout.navHighlight('login')
      if @authController.getAuthInfo()?
        @channel.commands.execute "app:router:navigate", 'home'
      else
        @authController.showLoginPage()


  # ------------------------------------------------------------------------------------------------------------------ #
  module.exports.start = ({$el}) ->
    controller = new TorbitApp.Controller({$el})
    controller.start()
