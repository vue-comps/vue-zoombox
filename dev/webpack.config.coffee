webpack = require "webpack"
module.exports =
  module:
    loaders: [
      { test: /\.vue$/, loader: "vue-loader"}
      { test: /\.coffee$/, loader: "coffee-loader"}
      { test: /\.png$/, loader: "url-loader"}
    ]
  resolve:
    extensions: ["",".js",".coffee",".vue"]
