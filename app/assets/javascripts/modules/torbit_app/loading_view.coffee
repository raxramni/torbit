require.define 'torbit_app/loading_view': (exports, require, module) ->
  module.exports = class LoadingView extends Marionette.ItemView
    className: 'loading-view'
    template: ->


    @mask: (el, options = {}) ->
      $el = $(el)
      _.defaults options, masked: true
      loadingView = new this(options)
      $el.after(loadingView.render().el)
      loadingView.triggerMethod('show')
      loadingView


    initialize: ({@minHeight, scale, @masked} = {}) ->
      scale      ?= 1

      options =
        lines:  6
        radius: 12 * scale
        width:  22 * scale
        length: 15 * scale
        width:  7  * scale
        rotate: 30
        color: '#FDBB30'

      @spinner = new Spinner(options)

    onRender: ->
      @$el.toggleClass('loading-view-masked', !!@masked)
      @spinner.spin(@$el.get(0))

    onShow: ->
      parent = @$el.parent()
      @oldPosition = parent.css('position')
      unless @oldPosition in ['relative', 'absolute']
        parent.css('position', 'relative')

    onBeforeDestroy: ->
      @$el.parent().css('position', @oldPosition)

    onDestroy: ->
      @spinner.stop()
