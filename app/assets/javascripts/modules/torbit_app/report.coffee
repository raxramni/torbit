require.define 'torbit_app/report': (exports, require, module) ->
  Report = module.exports

  LoadingView       = require 'torbit_app/loading_view'

  class Report.Layout extends Marionette.LayoutView
    template: JST['torbit_app/report/layout']
    className: 'torbit-report'
    regions:
      graphRegion: '.graph-region'
    ui:
      graphRegion: '.graph-region'
      notifications: '.notifications'
    onShow: ->
      @ui.notifications.hide()
    showErrors: (errors) ->
      @ui.notifications.text(errors).show()

  class Report.Controller extends Marionette.Controller
    initialize: ({@mountRegion, @channel}) ->
      @layout = new Report.Layout()
      @listenTo @layout, 'destroy', @destroy
      @listenTo @layout, 'show',    @_onShow
    
    start: ->
      @mountRegion.show(@layout)

    onDestroy: ->
      @layout?.destroy()

    _onShow: ->
      @_fetchReportData()

    _fetchReportData: ->
      @loadingView = new LoadingView()
      @layout.graphRegion.show(@loadingView)
      url = 'http://166.78.104.55/report'
      ajax = $.ajax
        type: 'get'
        url: url
        xhrFields:
          withCredentials: true
      Q(ajax).fin =>
        @loadingView.destroy()
      .done \
        (successResp) =>
          @chartView = new Report.ChartView(data: successResp?.data)
          @layout.graphRegion?.show(@chartView)
        ,
        (failureResp) =>
          if failureResp.status == 401
            @channel.commands.execute 'app:user:authFailed', 'Authorization Failed. Please Login!'
          else
            @layout.showErrors(failureResp.responseText)

  class Report.ChartView extends Marionette.ItemView
    className: 'chart'
    template: ->
    initialize: ({@data}) ->
      for arr in @data
        arr[0]= arr[0]/1000000 if arr[0]?
    onShow: ->
      @_initCharts()
    onDestroy: ->
      @chart?.destroy()
    _initCharts: ->
      highchartsOptions = @_prepareHighchartsOptions()
      @chart = new Highcharts.Chart(highchartsOptions)
    _prepareHighchartsOptions: ->
      chart:
        zoomType: 'x'
        renderTo: @$el.get(0)
      xAxis:
        title:
          enabled: true
          text: 'Time'
        type: 'datetime'
        dateTimeLabelFormats:
          hour: '%I %p'
          minute: '%I:%M %p'
      series:[
        data: @data
      ]

