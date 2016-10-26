<template lang="pug">
.container(style="height:2000px")
  a(href="https://github.com/vue-comps/vue-zoombox/blob/master/dev/basic.vue") source
  p with thumbnail: (big image loaded: {{loaded}})
  zoombox(
    :thumb="thumb",
    :src="src",
    @image-loaded="imageLoaded",
    v-ref:thumb
    )
    span a caption
    div(style="left:10%;top:45%;color:white;font-size:20px;position:absolute" slot="opened") <-
  p without thumbnail
  zoombox(
    :src="src",

    v-ref:img
    )
    span a caption
</template>

<script lang="coffee">
Velocity = require("velocity-animate")
cancel = (el) -> Velocity el, "stop"
Overlay = require("vue-overlay")
Overlay.obj.methods.fade = ({el,opacity,cb}) ->
  Velocity(el, {opacity: opacity}, {
    duration: 1000,
    queue: false,
    easing: 'easeOutQuad',
    complete: cb
  })
module.exports =
  components:
    "zoombox" : require "../src/zoombox.vue"
  data: ->
    loaded: false
    thumb: require("./thumb.png")
    src: require("./img.png")
  methods:
    imageLoaded: ->
      @loaded = true
  transitions:
    zoombox:
      css: false
      leaveCancelled: cancel
      enterCancelled: cancel
      enter: (el,done) ->
        Velocity.hook(el, "scale", @imgScale)
        @$nextTick =>
          Velocity el, {scale:@imgScale*@scale,top:@relPos.top,left:@relPos.left}, {
            duration: 1000,
            queue: false,
            ease: "easeOutQuad",
            complete: done
          }
      leave: (el,done) ->
        Velocity.hook(el, "scale", @imgScale*@scale)
        Velocity el, {scale:@imgScale,top:0,left:0}, {
          duration: 1000,
          queue: false,
          ease: "easeOutQuad",
          complete: done
        }
    zoomboxCaption:
      css: false
      leaveCancelled: cancel
      enterCancelled: cancel
      enter: (el,done) ->
        Velocity el, {opacity:1}, {
          duration: 1000,
          queue: false,
          ease: "easeOutQuad",
          complete: done
        }
      leave: (el,done) ->
        Velocity el, {opacity:0}, {
          duration: 1000,
          queue: false,
          ease: "easeOutQuad",
          complete: done
        }
</script>
