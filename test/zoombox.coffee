env = null
clickNWait = (el,cb) ->
  e = new MouseEvent("click",{
    "view": window,
    "bubbles": true,
    "cancelable": true
  })
  el.dispatchEvent(e)
  env.$nextTick -> env.$nextTick -> cb()
describe "zoombox", ->

  describe "basic env", ->

    before ->
      env = loadComp(require("../dev/basic.vue"))

    after ->
      unloadComp(env)

    it "should work with thumbnail", (done) ->
      t = env.$refs.thumb
      t.thumbLoaded.should.be.false
      t.$once "thumb-loaded", ->
        t.thumbLoaded.should.be.true
        should.exist t.$els.thumb
        clickNWait t.$el, ->
          t.opened.should.be.true
          should.exist t.$el.querySelector(".zoombox-loading")
          t.load()
          t.$once "image-loaded", -> t.$nextTick ->
            should.not.exist t.$el.querySelector(".zoombox-loading")
            should.exist t.$el.querySelector(".zoombox-image")
            should.exist t.$el.querySelector(".zoombox-caption")
            clickNWait t.$el, ->
              t.opened.should.be.false
              t.$once "after-leave", -> t.$nextTick ->
                should.not.exist t.$el.querySelector(".zoombox-loading")
                should.exist t.$els.thumb
                should.not.exist t.$el.querySelector(".zoombox-caption")
                done()

    it "should work without thumbnail", (done) ->
      t = env.$refs.img
      tmp = t.src
      t.src = null
      t.$nextTick ->
        t.thumbLoaded.should.be.false
        t.loaded.should.be.false
        t.src = tmp
        t.$once "image-loaded", ->
          t.thumbLoaded.should.be.true
          t.loaded.should.be.true
          clickNWait t.$el, ->
            t.opened.should.be.true
            should.not.exist t.$el.querySelector(".zoombox-loading")
            should.exist t.$el.querySelector(".zoombox-image")
            should.exist t.$el.querySelector(".zoombox-caption")
            clickNWait t.$el, ->
              t.opened.should.be.false
              t.$once "after-leave", -> t.$nextTick ->
                should.not.exist t.$el.querySelector(".zoombox-loading")
                should.exist t.$els.thumb
                should.not.exist t.$el.querySelector(".zoombox-caption")
                done()
