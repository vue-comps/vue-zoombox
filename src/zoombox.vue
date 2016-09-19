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
    style="display:inline-block; transform-origin: top left; position: absolute;line-height: 0;top:0;left:0",
    @load="processThumb",
    :src="thumbSrc",
    @mouseenter="load"
    )
  template(v-if="loaded")
    img.zoombox-image(
      :style="iStyle",
      style="display:inline-block; transform-origin: top left; line-height: 0",
      v-if="opened",
      :src="src",
      :transition="cTransition"
      )
    div.zoombox-caption(
      v-el:caption,
      :style="captionStyle",
      style="position: fixed",
      v-if="opened",
      :transition="ccTransition"
      )
      slot
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
    hasCaption: -> @_slotContents.default?
    mergeStyle: ->
      style =
        position: "relative"
        cursor: if @opened then "zoom-out" else "zoom-in"
        height: @thumbSize.height+"px"
        width: @thumbSize.width+"px"
      return style
    thumbStyle: ->
      unless @thumb
        transform: "scale(#{@imgScale})"
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
      if @opened
        style =
          zIndex: @zIndex
        if @available
          style.top = (@windowSize.height + @pos.height*@scale) / 2 + 6+'px'
          style.left = (@windowSize.width - @$els.caption.offsetWidth) / 2+'px'
        if @opening
          style.opacity = 0
        return style
    realOpened: -> @opened and not @opening and not @closing
    zoom: ->
      if @loaded and @available
        if @hasCaption and @$els.caption?
          captionHeight = @$els.caption.offsetHeight
          return 1-2*Math.max(0.05*@windowSize.height,captionHeight*2)/@windowSize.height
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
    disableTransition: false
    loaded: false
    opening: false
    available: false
    closing: false
    pos: null
    windowSize: null
    zIndex: null
    imgScale: 0
    imgSize: {}
    thumbSize: {}

  watch:
    "src": ->
      @loaded = false
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
    processSrc: ->
      @imgSize = {height:@$els.imgsrc.clientHeight,width:@$els.imgsrc.clientWidth}
      if @$el.clientHeight > 0
        scaleH = @$el.clientHeight / @imgSize.height
      else
        scaleH = Number.MAX_VALUE
      if @$el.clientWidth > 0
        scaleW = @$el.clientWidth / @imgSize.width
      else
        scaleW = Number.MAX_VALUE
      @imgScale = Math.min(scaleH,scaleW)
      if @imgScale < Number.MAX_VALUE
        unless @thumb
          @thumbSize =
            height: @imgSize.height*@imgScale
            width: @imgSize.width*@imgScale
          @thumbLoaded = true
          @$emit "thumb-loaded"
        @loaded = true
        @$emit "image-loaded"
        if @opened
          @$nextTick =>
            @available = true
            @calc()
    calc: ->
      @$set "pos", @$el.getBoundingClientRect()
      @$set "windowSize", @getViewportSize()
    show: ->
      return if @opened
      unless @loaded
        @disableTransition = true
        @setOpened()
        @$once "image-loaded", =>
          @$nextTick =>
            @disableTransition = false
      else
        @calc()
        @setOpened()
        @opening = true
        endOpening = =>
          @opening = false
          @$off "after-enter", endOpening
          @$off "enter-cancelled", endOpening
        @$on "after-enter", endOpening
        @$on "enter-cancelled", endOpening
        @$nextTick =>
          @available = true

    hide: ->
      return unless @opened
      @closing = true
      endClosing = =>
        @closing = false
        @available = false
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
    @onWindowResize @calc
    if @delay and @thumb
      setTimeout @load, @delay

  beforeDestroy: ->
    @closeOverlay?()
    @removeScrollListener?()
</script>
