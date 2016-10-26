# vue-zoombox

a advanced zoombox.
- Reposition on window resize
- Full resolution for images
- support for caption
- support for scrolling
- support for thumbs

### [Demo](https://vue-comps.github.io/vue-zoombox)

# Install

```sh
npm install --save-dev vue-zoombox
```
or include `build/bundle.js`.

## Usage
```coffee
# in your component
components:
  "zoombox": require("vue-zoombox")
# or, when using bundle.js
components:
  "zoombox": window.vueComps.zoombox
```
```html
<zoombox src="./path/to/img" thumb="./path/to/thumb">
  <span>A caption</span>
  <span slot="loading">loading...</span>
  <span slot="opened">Will be shown besides the image when opened</span>
</zoombox>
```
see [`dev/`](dev/) for examples.

#### Props
Name | type | default | description
---:| --- | ---| ---
src | String | - | (required) path to image.
thumb | String | - | path to thumb
delay | Number | 3000 | Only if thumb is given, delays loading of the image, in ms. 0 to disable auto load of image.
opacity | Number | 0.5 | opacity of the overlay
max-scale | Number | Number.MAX_VALUE | maximal zoom factor
allow-scroll | Boolean | false | will not close on scroll
disable-scroll	| Boolean	| false | will disable scrolling
is-opened	| Boolean	| false | (two-way) set to open / close
transition | String | "zoombox" | name of a vue transition. [Detailed description](#transition)
caption-transition | String | "zoomboxCaption" | name of a vue transition. [Detailed description](#transition)

if thumb is given the image is loaded after `delay` or on `mouseenter`.  
If the image isn't loaded on click, the slot `loading` is displayed.

#### Events
Name | description
---:| ---
before-enter | will be called before open animation
after-enter |  will be called when opened
before-leave |  will be called before close animation
after-leave |  will be called when closed
thumb-loaded | will be called when thumb is ready
image-loaded | will be called when image is ready
toggled(isOpened:Boolean) | emitted when gets opened or closed. Alternative to use two-way `is-opened` prop


#### Transition

You can provide a vue transition like this:
```js
Vue.transition("fade",{
  // your transition
})
// or in the instance:
transitions: {
  fade: {
    // your transition
  }
}
// usage:
template: "<zoombox transition='fade'></zoombox>"
```

You can access several properties in your hooks:
```js
enter: function(el,cb) {
  self = this
  this.nextTick(function(){
    self.imgScale // scale to get the small image size
    self.scale // multiply with imgScale to get the big image size
    // target top and left positions for big image size
    self.relPos.top
    self.relPos.left
    // starting position for top and left are 0
  })
}
```

Example from [dev/basic.vue](dev/basic.vue)
```coffee
Velocity = require("velocity-animate")

transitions:
  zoombox:
    css: false
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
```

## Changelog
- 1.0.2  
added opened slot  
little bugfix with lineheight  

- 1.0.1  
close overlay on destroy  
changed container behavior to allow responsive images (#1)  

- 1.0.0  
removed support for other content (only images now)  
now using vue transitions  
events are renamed after vue transitions  
added support for thumbs  
added unit tests  

# Development
Clone repository.
```sh
npm install
npm run dev
```
Browse to `http://localhost:8080/`.

## License
Copyright (c) 2016 Paul Pflugradt
Licensed under the MIT license.
