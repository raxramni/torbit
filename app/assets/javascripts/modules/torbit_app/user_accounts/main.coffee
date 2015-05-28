require.define 'torbit_app/user_accounts/main': (exports, require, module) ->
  UserAccounts = module.exports
  LoadingView       = require 'torbit_app/loading_view'

  class UserAccounts.Layout extends Marionette.LayoutView
    template: JST['torbit_app/user_accounts/layout']
    className: 'torbit-report'
    regions:
      usersRegion: '.user-accounts-region'
      newUserRegion: '.new-user-region'
    ui:
      newUserRegion: '.new-user-region'
      usersRegion: '.user-accounts-region'
      notifications: '.notifications'
    onRender: ->
      @ui.notifications.hide()
    showErrors: (errors) ->
      @ui.notifications.text(errors).show()

  class UserAccounts.Model extends Backbone.Deferred.Model
    urlRoot: 'http://166.78.104.55/user'

  class UserAccounts.Collection extends Backbone.Deferred.Collection
    idAttribute: 'email'
    model: UserAccounts.Model
    url: 'http://166.78.104.55/users'


  class UserAccounts.NewView extends Marionette.ItemView
    className: 'list-group-item'
    template: JST['torbit_app/user_accounts/new_user_account']
    ui:
      notifications: '.notifications'
      form: 'form'
    events:
      'submit form': 'saveUser'
    onShow: ->
      @ui.notifications.hide()
    saveUser: (e)=>
      e.preventDefault()
      return unless confirm('Are you sure?')
      data = Backbone.Syphon.serialize(this)
      @trigger 'userAccount:save', {data}
    resetFields: ->
      @ui.form[0].reset()
    showErrors: (errors) ->
      @ui.notifications.text(errors).show()


  class UserAccounts.IndexViewRecord extends Marionette.ItemView
    tagName: 'li'
    className: 'list-group-item'
    template: JST['torbit_app/user_accounts/user_account']
    ui:
      notifications: '.notifications'
    events:
      'click .save-user': 'saveUser'
      'click .delete-user': 'deleteUser'
    modelEvents:
      "destroy": "onModelDestroy"
    bindings:
      'input.email': 'email'
      'input.name': 'name'
      'input.admin': 'admin'
    onRender: ->
      @stickit()
    onShow: ->
      @ui.notifications.hide()
    onModelDestroy: ->
      @destroy()
    saveUser: (e)->
      e.preventDefault()
      return unless confirm('Are you sure?')
      @model.save()
        .done \
          =>
          ,
          (failureResp) =>
            if failureResp.status == 401
              @channel.commands.execute 'app:user:authFailed', 'Authorization Failed. Please Login!'
            else
              @showErrors(failureResp.responseText)
    deleteUser: (e)->
      e.preventDefault()
      return unless confirm('Are you sure?')
      destroyURL = @model.url()+'?'+$.param({email: @model.get('email')})
      @model.idAttribute= 'email'
      @model.destroy({url: destroyURL, wait: true, dataType: 'text'})
        .done(
          (successResp) =>
          ,
          (failureResp) =>
            @model.idAttribute=null
            if failureResp.status == 401
              @channel.commands.execute 'app:user:authFailed', 'Authorization Failed. Please Login!'
            else
              @showErrors(failureResp.responseText)

        )
    showErrors: (errors) ->
      @ui.notifications.text(errors).show()



  class UserAccounts.IndexView extends Marionette.CollectionView
    tagName: 'ul'
    className: 'list-group'
    childView: UserAccounts.IndexViewRecord


  class UserAccounts.Controller extends Marionette.Controller
    initialize: ({@mountRegion, @channel}) ->
      @layout = new UserAccounts.Layout()
      @listenTo @layout, 'destroy', @destroy
      @listenTo @layout, 'destroy', @destroy
      @listenTo @layout, 'show', @_onShow
    start: ->
      @userData = new UserAccounts.Collection()
      @mountRegion.show(@layout)

    onDestroy: ->
      @userAccountsView?.destroy()
      @newUserView?.destroy()
      @layout?.destroy()

    _onShow: ->
      @newUserView = new UserAccounts.NewView()
      @layout.newUserRegion.show(@newUserView)
      @listenTo @newUserView, 'userAccount:save', (args...) -> @createNewUser(args...)
      @_fetchUserAccountData()

    createNewUser: ({data}) ->
      tempModel = new UserAccounts.Model(data)

      tempModel.save({type: 'post', wait: true})
        .done \
          =>
            @userData.add(tempModel)
            @newUserView.resetFields()
        ,
        (failureResp) =>
          if failureResp.status == 401
            @channel.commands.execute 'app:user:authFailed', 'Authorization Failed. Please Login!'
          else
            @newUserView.showErrors(failureResp.responseText)

    _fetchUserAccountData: ->
      @loadingView = new LoadingView()
      @layout.usersRegion.show(@loadingView)
      @userData.fetch()
        .fin =>
          @loadingView.destroy()
        .done \
          =>
            @userAccountsView = new UserAccounts.IndexView({collection: @userData})
            @layout.usersRegion.show(@userAccountsView)
          ,
          (failureResp) =>
            if failureResp.status == 401
              @channel.commands.execute 'app:user:authFailed', 'Authorization Failed. Please Login!'
            else
              @layout.showErrors(failureResp.responseText)
