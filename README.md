# Inventing On Principle

## Inspiration
* [Bret Victor's Learnable Programming](http://worrydream.com/LearnableProgramming/)
* [Bret Victor's Inventing On Principle](http://worrydream.com/InventingOnPrinciple/)
* [Chris Granger's Lighttable](http://www.chris-granger.com/2012/04/12/light-table---a-new-ide-concept/)

## Foundation
* [Esprima][]: JavaScript parser
* [Escodegen](https://github.com/Constellation/escodegen): AST -> JavaScript generator
* [CodeMirror](http://codemirror.net/): In Browser Code Editor
* [Tangle.js](): JavaScript Reactive Documents Library
* [Underscore][_]: JavaScript utility functions
* [Backbone](http://backbonejs.org/): JavaScript Framework
* [jQuery](jquery.com): JavaScript DOM Library

## References
* [node-falafel](https://github.com/substack/node-falafel)
* [jsbin](https://github.com/remy/jsbin)
* [Codebook](http://danielhooper.tumblr.com/post/19313911658/codebook)
* [learnjs.info](https://github.com/zdwalter/learnjs)
* [AlgoView](https://github.com/nicroto/AlgoView)

## Instructions

* Clone this repo
* Within the repo, run `npm install && bower install`
* run `grunt server` to run the app

## Overview

At a high level, the app uses [Esprima][] to parse the source code within the code editor, analyzes the source code to extract out variable and function declarations and inserts trace statements, execute the source code, and then visualize the information collected with an interactive interface

## Parsing

Whenever there's a change in the source code, whether this is from the initial load of the template source file or actual editing, and there's no errors detected by [JSHint][], [Esprima][] is used to parse the valid source code and the [Abstract Syntax Tree (AST)][AST] is saved, along with [other helpers][] attached to help transform the source code.

## Analysis

Then, variable and function declarations are extracted by traversing the AST. These declarations are subsequently [wrapped in models][] and [rendered] as high level views of the declarations.

At the same time, scope information for the source code is [computed][] and is then used to [produce a list of variables][] that need to can be traced. The actual tracing generation is laid out in [`tracer`][] module. The logic under `genTraces` specifies all the various expression types and how their values should be collected. The inserted trace statements call [methods][] on the `tracer` to collect information during run time.

## Execution

The code is run using [`eval`][]. Here, a reference to the global object `_` is also passed in so the [underscore][_] library can be used in the source code

## Visualization

The actual execution steps of the code are collected by tracing statements that make side effects and a slider is generated to allow for stepping through of the code path. At each step of the slider, the [corresponding state][] at that step is rendered. There are 2 main ways of displaying this information:

1. the scoped variable information are directly displayed as [raw JSON][]
2. for specific arrays, a [D3 visualization][] is generated

## Conclusion

This project is still in progress, with lots of room for improvement

* Generalizing visualization modules to visualize different kinds of data, such as arrays, objects, etc.
* Optimizing the control flow to be more resilient from errors
* More code transformation tools, such as refactoring
* Better displays of variable information and control flows

<!-- Links -->

[Esprima]: http://esprima.org/
[JSHint]: http://jshint.com
[AST]: https://developer.mozilla.org/en-US/docs/SpiderMonkey/Parser_API
[other helpers]: https://github.com/yangsu/inventing-on-principle/blob/master/app/scripts/helpers/utils.coffee#L83-L137
[wrapped in models]: https://github.com/yangsu/inventing-on-principle/blob/master/app/scripts/models/application-model.coffee#L144-L162
[rendered]: https://github.com/yangsu/inventing-on-principle/blob/master/app/scripts/views/application-view.coffee#L121-L153
[computed]: https://github.com/yangsu/inventing-on-principle/blob/master/app/scripts/models/application-model.coffee#L164-L190
[produce a list of variables]: https://github.com/yangsu/inventing-on-principle/blob/master/app/scripts/models/application-model.coffee#L68-L113
[`tracer`]: https://github.com/yangsu/inventing-on-principle/blob/master/app/scripts/helpers/tracer.coffee#L20-L129
[methods]: https://github.com/yangsu/inventing-on-principle/blob/master/app/scripts/helpers/tracer.coffee#L135-L179
[`eval`]: https://github.com/yangsu/inventing-on-principle/blob/master/app/scripts/models/application-model.coffee#L126-L128
[_]: http://documentcloud.github.com/underscore/
[corresponding state]: https://github.com/yangsu/inventing-on-principle/blob/master/app/scripts/views/application-view.coffee#L209-L216
[raw JSON]: https://github.com/yangsu/inventing-on-principle/blob/master/app/scripts/views/application-view.coffee#L252-L259
[D3 visualization]: https://github.com/yangsu/inventing-on-principle/blob/master/app/scripts/script.coffee