// out: ..
<template lang="jade">
div.zoombox(:style="style",@click="toggle")
  img(v-bind:src="src" v-if="src && !loaded" v-el:imgsrc @load="processSrc" style="position:absolute;visibility:hidden")
  img.zoombox-image(v-el:img,:style="imgStyle",v-if="src && loaded",:src="src")
  div.zoombox-content(v-el:content,:style="contentStyle",v-if="loaded")
    slot
  div.zoombox-caption(v-el:caption,:style="captionStyle",v-if="opened")
    slot(name="caption")
</template>

<script lang="coffee">
module.exports =

  mixins:[
    require("vue-mixins/getViewportSize")
    require("vue-mixins/isOpened")
    require("vue-mixins/onWindowResize")
    require("vue-mixins/getVue")
    require("vue-mixins/setCss")
    require("vue-mixins/onWindowScroll")
  ]

  created: ->
    @overlay = require("vue-overlay")(@getVue())

  props:
    "src":
      type: String
    "transitionIn":
      type: Function
      default: ({el,style,cb}) ->
        for key,val of style
          @setCss(el,key,val)
        cb()
    "transitionOut":
      type: Function
      default: ({el,style,cb}) ->
        for key,val of style
          @setCss(el,key,val)
        cb()
    "captionTransition":
      type: Function
      default: ({el,style,cb}) ->
        @captionStyle.opacity = 1
        cb()
    "maxScale":
      type: Number
      default: Number.MAX_VALUE
    "allowScroll":
      type: Boolean
      default: false
    "disableScroll":
      type: Boolean
      default: false
    "opacity":
      type: Number
      default: 0.5


  data: ->
    loaded: false
    imgScale: 0
    style:
      position: "relative"
      cursor: "zoom-in"
    captionStyle:
      opacity: 0
      position: "fixed"
      top: 0
      left: 0
      zIndex: null
    imgStyle:
      display: "inline-block"
      position: "absolute"
      lineHeight: 0
      top: 0
      left: 0
      transform: null
      transformOrigin: "top left"
      zIndex: null
    contentStyle:
      display: "inline-block"
      position: "relative"
      top: 0
      left: 0
      transform: null
      transformOrigin: "top left"
      zIndex: null
  events:
    close: ->
      @close()
      true
  watch:
    "src":"process"

  methods:
    process: ->
      @loaded = !@src?
    processSrc: ->
      @$emit "image-loaded"
      if @$el.clientHeight > 0
        scaleH = @$el.clientHeight / @$els.imgsrc.clientHeight
      else
        scaleH = Number.MAX_VALUE
      if @$el.clientWidth > 0
        scaleW = @$el.clientWidth / @$els.imgsrc.clientWidth
      else
        scaleW = Number.MAX_VALUE
      @imgScale = Math.min(scaleH,scaleW)
      if @imgScale < Number.MAX_VALUE
        if @$el.clientHeight == 0
          @$set "style.height", @$els.imgsrc.clientHeight*@imgScale+'px'
        if @$el.clientWidth == 0
          @$set "style.width", @$els.imgsrc.clientWidth*@imgScale+'px'
        @imgStyle.transform = "scale(#{@imgScale})"
        @loaded = true

    getScale: (pos,windowSize) ->
      pos ?= @$el.getBoundingClientRect()
      windowSize ?= @getViewportSize()
      if @hasCaption
        captionHeight = @$els.caption.offsetHeight
        zoom = 1-2*Math.max(0.05*windowSize.height,captionHeight*2)/windowSize.height
      else
        zoom = 0.9
      scale = Math.min(zoom*windowSize.width / pos.width, zoom*windowSize.height / pos.height)
      scale = @maxScale if scale > @maxScale
      return scale

    getAbsPos: (scale,pos,windowSize) ->
      windowSize ?= @getViewportSize()
      pos ?= @$el.getBoundingClientRect()
      scale ?= @getScale(pos,windowSize)
      absLeft = (windowSize.width - pos.width*scale) / 2
      absTop = (windowSize.height - pos.height*scale) / 2
      return left: absLeft, top: absTop

    getRelPos: (pos,absPos,scale,windowSize) ->
      pos ?= @$el.getBoundingClientRect()
      unless absPos?
        windowSize ?= @getViewportSize()
        scale ?= @getScale(pos,windowSize)
        absPos = @getAbsPos(scale,pos,windowSize)
      return left: absPos.left - pos.left, top: absPos.top - pos.top

    show: (alreadyOpen=false) ->
      return unless @opened
      isOpened = false
      setOpened = =>
        unless isOpened
          isOpened = true
          @$emit "opened"
      @hasCaption = @$els.caption.offsetHeight > 0 unless @hasCaption?
      @hasContent = @$els.content.offsetHeight > 0 unless @hasContent?
      @style.cursor = "zoom-out"
      pos = @$el.getBoundingClientRect()
      windowSize = @getViewportSize()
      scale = @getScale(pos,windowSize)
      absPos = @getAbsPos(scale,pos,windowSize)
      relPos = @getRelPos(pos,absPos,scale,windowSize)

      @$emit "beforeOpen"
      setAbsPos = (style,absPos) ->
        style.left = absPos.left+'px'
        style.top = absPos.top+'px'
      if @src
        if alreadyOpen
          setAbsPos(@imgStyle,absPos)
          @imgStyle.transform = "scale(#{@imgScale*scale})"
        else
          @transitionIn el:@$els.img,oldScale:@imgScale,style:{transform:"scale(#{@imgScale*scale})",top:relPos.top+'px',left:relPos.left+'px'},cb: =>
            setAbsPos(@imgStyle,absPos)
            @imgStyle.position = "fixed"
            setOpened()
      if @hasCaption
        @captionStyle.top = (windowSize.height + pos.height*scale) / 2 + 6+'px'
        @captionStyle.left = (windowSize.width - @$els.caption.offsetWidth) / 2+'px'
        unless alreadyOpen
          @captionTransition el:@$els.caption,style:{opacity:1},cb: setOpened
      if @hasContent
        if alreadyOpen
          setAbsPos(@contentStyle,absPos)
          @contentStyle.transform = "scale(#{scale})"
        else
          @transitionIn el:@$els.content,style:{transform:"scale(#{scale})",top:relPos.top+'px',left:relPos.left+'px'},cb: =>
            setAbsPos(@contentStyle,absPos)
            @contentStyle.position = "fixed"
            setOpened()

    hide: ->
      return unless @opened
      isClosed = false
      setClosed = =>
        unless isClosed
          isClosed = true
          @setClosed()
          @$emit "closed"
      @style.cursor = "zoom-in"
      @$emit "beforeClose"
      relPos = @getRelPos()
      if @src
        @imgStyle.left = relPos.left+'px'
        @imgStyle.top = relPos.top+'px'
        @imgStyle.position = "absolute"
        @$nextTick =>
          @transitionOut el:@$els.img,style:{transform:"scale(#{@imgScale})",top:0,left:0},cb: setClosed
      if @hasCaption
        @captionTransition el:@$els.caption,style:{opacity:0},cb: setClosed
      if @hasContent
        @contentStyle.left = relPos.left+'px'
        @contentStyle.top = relPos.top+'px'
        @contentStyle.position = "relative"
        @$nextTick =>
          @transitionOut el:@$els.content,style:{transform:"scale(1)",top:0,left:0},cb: setClosed

    open: ->
      return if @opened
      {zIndex,close} = @overlay.open allowScroll:!@disableScroll, opacity:@opacity, onBeforeClose: => @close()
      @contentStyle.zIndex = zIndex + 1
      @imgStyle.zIndex = zIndex
      @captionStyle.zIndex = zIndex
      @closeOverlay = close
      @removeScrollListener = @onWindowScroll @close unless @allowScroll
      @setOpened()
      @$nextTick @show

    close: ->
      return unless @opened
      @hide()
      @closeOverlay?()
      @removeScrollListener?()
      @contentStyle.zIndex = null
      @imgStyle.zIndex = null
      @closeOverlay = null

    toggle: ->
      if @opened
        @close()
      else
        @open()

  attached: ->
    @process()
    @onWindowResize => @show(true)


</script>
