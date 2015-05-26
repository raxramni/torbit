require.define 'torbit_app/site_configs/main': (exports, require, module) ->
  SiteConfigs = module.exports
  LoadingView       = require 'torbit_app/loading_view'

  class SiteConfigs.Layout extends Marionette.LayoutView
    template: JST['torbit_app/site_configs/layout']
    className: 'torbit-report'
    regions:
      mainRegion: '.main-region'
    ui:
      mainRegion: '.main-region'
      notifications: '.notifications'
    onShow: ->
      @ui.notifications.hide()
    showErrors: (errors) ->
      console.log @ui.notifications
      @ui.notifications.text(errors).show()

  class SiteConfigs.Collection extends Backbone.Deferred.Collection
    model: SiteConfigs.Model
    url: 'http://166.78.104.55/configs'

  class SiteConfigs.Model extends Backbone.Deferred.Model
    urlRoot: 'http://166.78.104.55/configs'

  class SiteConfigs.Controller extends Marionette.Controller
    initialize: ({@channel}) ->
      @layout = new SiteConfigs.Layout()
      @listenTo @layout, 'show', @_onShow
    start: ->
      @collection = new SiteConfigs.Collection()
      @region= @channel.reqres.request('app:main_region')
      @region.show(@layout)
    _onShow: ->
      @_fetchSiteConfigData()
    _fetchSiteConfigData: ->
      @loadingView = new LoadingView()
      @layout.mainRegion.show(@loadingView)
      @collection.fetch()
        .fin =>
          @loadingView.destroy()
        .done \
          =>
            @siteConfigsView = new SiteConfigs.IndexView({@collection})
            @layout.mainRegion.show(@siteConfigsView)
          ,
          (message) =>
            @layout.showErrors(message)
    onDestroy: ->
      @siteConfigsView?.destroy()

  class SiteConfigs.IndexView extends Marionette.CollectionView
    tagName: 'ul'
    className: 'list-group'
    childView: SiteConfigs.IndexViewRecord

  class SiteConfigs.IndexViewRecord extends Marionette.ItemView
    tagName: 'li'
    className: 'list-group-item'
    template: JST['torbit_app/site_configs/site_config']
