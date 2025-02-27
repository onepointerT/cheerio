###*
# @module cheerio
# @borrows static.load as load
# @borrows static.html as html
# @borrows static.text as text
# @borrows static.xml as xml
###

staticMethods = require('./lib/static')
exports = module.exports = require('./lib/cheerio')

###*
# An identifier describing the version of Cheerio which has been executed.
#
# @type {string}
###

exports.version = require('./package.json').version
exports.load = staticMethods.load
exports.html = staticMethods.html
exports.text = staticMethods.text
exports.xml = staticMethods.xml

###*
# In order to promote consistency with the jQuery library, users are
# encouraged to instead use the static method of the same name. For example:
#
#     var $ = cheerio.load('<div><p></p></div>');
#     $.contains($('div').get(0), $('p').get(0)); // true
#     $.contains($('p').get(0), $('div').get(0)); // false
#
# @method
# @deprecated
###

exports.contains = staticMethods.contains

###*
# In order to promote consistency with the jQuery library, users are
# encouraged to instead use the static method of the same name. For example:
#
#     var $ = cheerio.load('');
#     $.merge([1, 2], [3, 4]) // [1, 2, 3, 4]
#
# @method
# @deprecated
###

exports.merge = staticMethods.merge

###*
# In order to promote consistency with the jQuery library, users are
# encouraged to instead use the static method of the same name as it is
# defined on the "loaded" Cheerio factory function. For example:
#
#     var $ = cheerio.load('');
#     $.parseHTML('<b>markup</b>');
#
# @method
# @deprecated see {@link static/parseHTML}
###

exports.parseHTML = staticMethods.parseHTML

###*
# Users seeking to access the top-level element of a parsed document should
# instead use the `root` static method of a "loaded" Cheerio function. For
# example:
#
#     var $ = cheerio.load('');
#     $.root();
#
# @method
# @deprecated
###

exports.root = staticMethods.root
