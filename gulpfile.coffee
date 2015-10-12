gulp = require 'gulp'
coffee = require 'gulp-coffee'
sourcemaps = require 'gulp-sourcemaps'

compileCoffee = (sources, destDir) ->
    gulp.src sources
    .pipe sourcemaps.init()
    .pipe coffee
        bare: true
    .on 'error', console.error
    .pipe sourcemaps.write '.'
    .pipe gulp.dest destDir

gulp.task 'coffee', ->
    sources = './src/*.coffee'
    destDir = './lib'
    compileCoffee sources, destDir