require.define 'torbit_app/auth': (exports, require, module) ->
  Auth = module.exports

  class Auth.Controller extends Marionette.Controller
    initialize: ({@channel}) ->
      @_session = null

    start: ->
      if @getAuthInfo()?
        @channel.commands.execute 'app:user:authenticated', {user: @_session.user, token: @_session.token}
      else
        @showLoginPage()
   
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
      @_loginView= new Auth.LoginView()
      @listenTo @_loginView, 'authenticate', @serverAuthenticate
      region.show(@_loginView)
      @_loginView.showErrors(errors) if errors?

    showUserPage: ->
      region= @channel.reqres.request('app:main_region')
      model = new Backbone.Model(@getAuthInfo().user)
      @_userView=  new Auth.UserInfoView({model})
      @listenTo @_userView, 'deAuthenticate', @deAuthenticate
      region.show(@_userView)

    logout: ->
      #shoutout loggedout on the channel --- the main controller destroys everything and 
      #delete the cookie and redirect to login page 

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
          #$.cookie('torbit.com', JSON.stringify(successResp), {expires: expDate, path: '/'})
          @_session = successResp
          sessionStorage.setItem('authInfo', JSON.stringify(@_session))
          #$.cookie('auth', @_session.token)
          #$.cookie('user', JSON.stringify(@_session.user))
          #document.cookie="user="+@_session.token
          @channel.commands.execute 'app:user:authenticated', {user: @_session.user, token: @_session.token}
        ,
        (failureResp) =>
          @_session = null
          console.log failureResp
          alert 'error'
          @showLoginPage(failureResp)

    serverDeAuthenticate: ({username}) ->
      #to be implemented

  class Auth.UserInfoView extends Marionette.ItemView
    template: JST['torbit_app/user_info']
    events:
      'click .logout-submit': 'logout'
    ui:
      notifications: '.notifications'
    onRender: ->
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
