# vue-zoombox

a advanced zoombox.
- Zooms into everything (images, text)
- Reposition on window resize
- Full resolution for images
- support for caption
- support for scrolling

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
<zoombox style="width:200px">Content
  <span slot="caption">A caption</span>
</zoombox>
```
see [`dev/`](dev/) for examples.

#### Props
| Name | type | default | description |
| ---:| --- | ---| --- |
| src | String | - | path to image. Image will be fitted into the box. |
| opacity | Number | 0.5 | opacity of the overlay |
| max-scale | Number | Number.MAX_VALUE | maximal zoom factor |
| allow-scroll | Boolean | false | will not close on scroll |
| disable-scroll	| Boolean	| false | will disable scrolling |
| is-opened	| Boolean	| false | (two-way) set to open / close|
| transition-in | function | no animation | set animation. Argument: {el,oldScale,style,cb} |
| transition-out | function | no animation | set animation. Argument: {el,style,cb} |
| caption-transition | function | no animation | set animation. Argument: {el,style,cb} |

#### Events
| Name |  description |
| ---:| --- |
| close |  when received, will close |
| before-open | will be called before open animation |
| opened |  will be called when opened |
| before-close |  will be called before close animation |
| closed |  will be called when closed |


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
