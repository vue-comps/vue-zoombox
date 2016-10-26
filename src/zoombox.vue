// out: ..
<template lang="pug">
div.zoombox(
  :style="computedStyle",
  @click="toggle"
  )
  img(
    v-bind:src="cSrc"
    v-if="cSrc && !loaded"
    v-el:imgsrc
    @load="processSrc"
    style="position:absolute;visibility:hidden"
    )
  img.zoombox-image(
    :style="thumbStyle",
    v-el:thumb,
    v-if="!thumbLoaded || (!opened && !opening && !closing)",
    style="transform-origin: top left; max-width: 100%; height: auto",
    @load="processThumb",
    :src="thumbSrc",
    @mouseenter="load"
    )
  img.zoombox-image(
    :style="iStyle",
    style="display:inline-block; transform-origin: top left; line-height: 0",
    v-if="loaded && opened",
    :src="src",
    :transition="cTransition"
    )
  div.zoombox-caption(
    v-el:caption,
    :style="captionStyle",
    style="position: fixed",
    v-if="opened || !loaded",
    :transition="ccTransition"
    )
    slot
  div.zoombox-opened(
    :style="{zIndex:zIndex}"
    style="position: fixed;top:0;left:0;bottom:0;right:0",
    v-if="hasOpened && opened",
    :transition="ccTransition"
    )
    slot(name="opened")
  div.zoombox-loading(
    v-if="!loaded && opened"
    style="position:fixed;left: 50%;top: 50%;transform: translate(-50%, -50%);"
    )
    slot(name="loading") loading ...
</template>

<script lang="coffee">
module.exports =

  mixins:[
    require("vue-mixins/getViewportSize")
    require("vue-mixins/isOpened")
    require("vue-mixins/onWindowResize")
    require("vue-mixins/vue")
    require("vue-mixins/onWindowScroll")
    require("vue-mixins/transition")
    require("vue-mixins/style")
  ]

  props:
    style:
      default: -> []
    src:
      type: String
      required: true
    thumb:
      type: String
    delay:
      type: Number
      default: 3000
      coerce: Number
    transition:
      type: String
      default: "zoombox"
    captionTransition:
      type: String
      default: "zoomboxCaption"
    maxScale:
      type: Number
      default: Number.MAX_VALUE
      coerce: Number
    allowScroll:
      type: Boolean
      default: false
    disableScroll:
      type: Boolean
      default: false
    opacity:
      type: Number
      default: 0.5
      coerce: Number

  computed:
    ccTransition: ->
      name = @captionTransition
      hooks = @Vue.util.resolveAsset(@$parent.$options,'transitions',name)
      hooks ?= @$options.transitions[name]
      hooks ?= {}
      @$options.transitions[name] = hooks
      if @disableTransition
        return null
      return name
    thumbSrc: ->
      return @thumb if @thumb
      return @src
    cSrc: ->
      if not @thumb or @shouldLoad
        return @src
    hasOpened: -> @_slotContents.opened?
    hasCaption: -> @_slotContents.default?
    mergeStyle: ->
      style =
        display: "inline-block"
        lineHeight: if @loaded and (not @opened and not @closing)  then 0 else null
        position: "relative"
        cursor: if @opened then "zoom-out" else "zoom-in"
      if @opened || @closing
        style.height = @thumbSize.height+"px"
        style.width = @thumbSize.width+"px"
      return style
    thumbStyle: ->
      #unless @thumb
        #transform: "scale(#{@imgScale})"
    iStyle: ->
      if @imgScale and @loaded
        if @realOpened
          return {
            zIndex: @zIndex
            transform: "scale(#{@scale*@imgScale})"
            top: @absPos.top+"px"
            left: @absPos.left+"px"
            position: "fixed"
          }
        else if @closing
          return {
            top: @relPos.top+"px"
            left: @relPos.left+"px"
            zIndex: @zIndex
            position: "absolute"
          }
        else
          return zIndex: @zIndex, position: "absolute"
    captionStyle: ->
      unless @loaded
        return visibility:"hidden", position: "absolute"
      if @opened
        style =
          zIndex: @zIndex
          top: (@windowSize.height + @pos.height*@scale) / 2 + 6+'px'
          left: (@windowSize.width - @captionSize.width) / 2+'px'
        if @opening
          style.opacity = 0
        return style
    realOpened: -> @opened and not @opening and not @closing
    zoom: ->
      if @windowSize
        if @hasCaption
          return 1-2*Math.max(0.05*@windowSize.height,@captionSize.height*2)/@windowSize.height
        else
          return 0.9
      return null
    scale: ->
      if @zoom
        scale = Math.min(@zoom*@windowSize.width / @pos.width, @zoom*@windowSize.height / @pos.height)
        scale = @maxScale if scale > @maxScale
        return scale
      return null
    absPos: ->
      if @scale
        absLeft = (@windowSize.width - @pos.width*@scale) / 2
        absTop = (@windowSize.height - @pos.height*@scale) / 2
        return left: absLeft, top: absTop
      return {}
    relPos: ->
      if @scale
        return left: @absPos.left - @pos.left, top: @absPos.top - @pos.top
      return {}

  data: ->
    transitionDefault: "zoombox"
    shouldLoad: false
    thumbLoaded: false
    disableTransition: true
    loaded: false
    opening: false
    closing: false
    pos: null
    captionSize: null
    windowSize: null
    zIndex: null
    imgScale: 0
    imgSize: {}
    thumbSize: {}

  watch:
    "src": ->
      @loaded = false
      @disableTransition = true
      unless @thumb
        @thumbLoaded = false
    "thumb": -> @thumbLoaded = false

  methods:
    load: ->
      @shouldLoad = true
    processThumb: ->
      if @thumb
        @thumbSize =
          height: @$els.thumb.clientHeight
          width: @$els.thumb.clientWidth
        @thumbLoaded = true
        @$emit "thumb-loaded"
    processScale: ->
      if @$el.clientHeight > 0
        scaleH = @$el.clientHeight / @imgSize.height
      else
        scaleH = Number.MAX_VALUE
      if @$el.clientWidth > 0
        scaleW = @$el.clientWidth / @imgSize.width
      else
        scaleW = Number.MAX_VALUE
      @imgScale = Math.min(scaleH,scaleW)
      if not @thumb and @imgScale < Number.MAX_VALUE and @imgScale > 0
        @thumbSize =
          height: @imgSize.height*@imgScale
          width: @imgSize.width*@imgScale
    processSrc: ->
      @imgSize = {height:@$els.imgsrc.clientHeight,width:@$els.imgsrc.clientWidth}
      @captionSize = {height:@$els.caption.offsetHeight,width:@$els.caption.offsetWidth}
      @processScale()
      if @imgScale < Number.MAX_VALUE && @imgScale > 0
        unless @thumb
          @thumbLoaded = true
          @$emit "thumb-loaded"
        @loaded = true
        @disableTransition = false
        @$emit "image-loaded"
        if @opened
          @$nextTick =>
            @calc()
    calc: ->
      @$set "pos", @$el.getBoundingClientRect()
      @$set "windowSize", @getViewportSize()
    show: ->
      return if @opened
      @calc() unless @closing or not @loaded
      @setOpened()
      if @loaded
        @opening = true
        endOpening = =>
          @opening = false
          @$off "after-enter", endOpening
          @$off "enter-cancelled", endOpening
        @$on "after-enter", endOpening
        @$on "enter-cancelled", endOpening

    hide: ->
      return unless @opened
      @closing = true
      endClosing = =>
        @closing = false
        @$off "after-leave", endClosing
        @$off "leave-cancelled", endClosing
      @$on "after-leave", endClosing
      @$on "leave-cancelled", endClosing
      @setClosed()

    open: ->
      return if @opened
      {zIndex,close} = @overlay.open allowScroll:!@disableScroll, opacity:@opacity, onBeforeClose: => @close()
      @zIndex = zIndex
      @closeOverlay = close
      @removeScrollListener = @onWindowScroll @close unless @allowScroll
      @$nextTick @show

    close: ->
      return unless @opened
      @hide()
      @closeOverlay?()
      @removeScrollListener?()
      @zIndex = null
      @closeOverlay = null

    toggle: (e) ->
      if e?
        return if e.defaultPrevented
        e.preventDefault()
      if @opened
        @close()
      else
        @open()
  beforeCompile: ->
    @available = false

  ready: ->
    @overlay = require("vue-overlay")(@Vue)
    @available = true if @opened
    @onWindowResize =>
      @processScale()
      @calc()

    if @delay and @thumb
      setTimeout @load, @delay

  beforeDestroy: ->
    @closeOverlay?()
    @removeScrollListener?()
</script>
