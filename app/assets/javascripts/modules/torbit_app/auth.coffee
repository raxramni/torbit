require.define 'torbit_app/auth': (exports, require, module) ->
  Auth = module.exports

  class Auth.Controller extends Marionette.Controller
    initialize: ({@channel}) ->
      @_session = null

    start: ->
      if @getAuthInfo()?
        @channel.commands.execute 'app:user:authenticated', {user: @_session.user, token: @_session.token}
      else
        @channel.commands.execute 'app:user:deAuthenticated'
        #@showLoginPage()
   
    onDestroy: ->
      @_loginView?.destroy()
      @_userView?.destroy()

    getAuthInfo: ->
      unless @_session?
        authInfo = sessionStorage.getItem('authInfo')
        @_session = JSON.parse(authInfo) if authInfo?
      @_session

    authenticate: ->
      @showLoginPage()

    deAuthenticate: ->
      sessionStorage.clear()
      @_session=null
      @_userView?.destroy()
      @channel.commands.execute 'app:user:deAuthenticated'

    showLoginPage: (errors=null)->
      region= @channel.reqres.request('app:main_region')
      @_loginView = new Auth.LoginView() if !@_loginView? || @_loginView.isDestroyed
      @listenTo @_loginView, 'authenticate', @serverAuthenticate
      region.show(@_loginView)
      @_loginView.showErrors(errors) if errors?

    showUserPage: ->
      auth = @getAuthInfo()
      @channel.commands.execute 'app:user:deAuthenticated' unless auth?
      region= @channel.reqres.request('app:main_region')
      model = new Backbone.Model(auth.user)
      @_userView.destroy() if @_userView?
      @_userView=  new Auth.UserInfoView({model})
      @listenTo @_userView, 'deAuthenticate', @deAuthenticate
      region.show(@_userView)

    serverAuthenticate: ({username, password}) ->
      url = 'http://166.78.104.55/login'
      ajax = $.ajax
        type: 'post'
        url: url
        data:
          email: username
          password: password
      Q(ajax).done \
        (successResp) =>
          expDate = new Date()
          minutes = 30
          expDate.setTime(expDate.getTime() + (minutes * 60 * 1000))
          @_session = successResp
          sessionStorage.setItem('authInfo', JSON.stringify(@_session))
          @channel.commands.execute 'app:user:authenticated', {user: @_session.user, token: @_session.token}
        ,
        (failureResp) =>
          @_session = null
          @channel.commands.execute 'app:user:authFailed', 'Authentication Failed: ' + failureResp?.statusText

    serverDeAuthenticate: ({username}) ->
      #to be implemented

  class Auth.UserInfoView extends Marionette.ItemView
    template: JST['torbit_app/user_info']
    events:
      'click .logout-submit': 'logout'
    ui:
      notifications: '.notifications'
    onShow: ->
      @ui.notifications.hide()
    showErrors: (errors) ->
      @ui.notifications.text(errors).show()
    logout: (e)=>
      e.preventDefault()
      @trigger 'deAuthenticate'

  class Auth.LoginView extends Marionette.ItemView
    template: JST['torbit_app/login_form']
    events:
      'click .login-submit': 'login'
    ui:
      notifications: '.notifications'
      email: 'input.email'
      password: 'input.password'
      loginButton: 'button.login'
 
    login: (e)=>
      e.preventDefault()
      username = @ui.email.val()
      password = @ui.password.val()
      @trigger 'authenticate', {username, password}

    onShow: ->
      @ui.notifications.hide()

    showErrors: (errors) ->
      @ui.notifications.text(errors).show()
